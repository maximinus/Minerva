import gi

gi.require_version("Gtk", "3.0")
from gi.repository import GLib

import time
import queue
import socket
import threading
import subprocess

from enum import Enum
from pathlib import Path
from sexpdata import loads

from minerva.logs import logger
from minerva.preferences import config
from minerva.actions import message_queue, Message, Target

# Python client for swank server
# We open a LISP instance and communicate with it for a LISP IDE
# how to start a swank session on Lisp: sbcl --load start-swank.lisp


# To clean this up:

# Make sure all threads use queues to pass information back
# Make sure all queues use an event to exit properly
# Ensure all threads are killed on exit
# Make sure Lisp info is logged to the normal log file
# Take some of these values and throw them into the config file; in particular
# HOST, PORT, SWANK_SCRIPT and RECV_CHUNK_SIZE, MAX_CONNECTION_ATTEMPTS, TIME_BETWEEN_CONNECTIONS


HOST = '127.0.0.1'
PORT = 4005
SWANK_SCRIPT = 'start-swank.lisp'
RECV_CHUNK_SIZE = 4096
MAX_CONNECTION_EVENTS = 20
TIME_BETWEEN_CONNECTIONS = 0.5

PACKAGE = 'COMMON-LISP-USER'
THREAD = 'T'

SWANK_REQUIRES = ['swank-indentation',
                  'swank-trace-dialog',
                  'swank-package-fu',
                  'swank-presentations',
                  'swank-macrostep',
                  'swank-fuzzy',
                  'swank-fancy-inspector',
                  'swank-c-p-c',
                  'swank-arglists',
                  'swank-repl']

SWANK1 = '(swank:connection-info)'
SWANK2 = f'''(swank:swank-require '({" ".join(SWANK_REQUIRES)}))'''
SWANK3 = '(swank:init-presentations)'
SWANK4 = '(swank-repl:create-repl nil :coding-system "utf-8-unix")'


# here are the threads and their helper functions.
# the whole process is as follows
# First, we wait until the main window is displayed and ready
#   We then start the Lisp server and a thread to read it's output
#   We then start a thread to connect to the lisp server and wait for it to send a message back
#       If it fails to connect, we
#           1: Stop the Lisp server and all threads
#           2: Show a message on the console
#           3: Prevent console from accepting REPL commands
#       If it connects, we
#           1: Start the listener process
#           2: Push the required swank messages out
#       If swank messages work, we:
#           Update this in the console
#       Otherwise we
#           1: Stop all threads, the Lisp server and update the console as above


def get_message(sock, timeout=0):
    # attempt to get a message from the lisp server
    # timeout = 0, don't wait for socket
    try:
        if timeout > 0:
            sock.settimeout(timeout)
        else:
            sock.settimeout(None)
        length_data = sock.recv(6)
        if len(length_data) == 0:
            # nothing was returned, swank server is likely dead
            return
        length = int(length_data, 16)
        all_data = []
        while length > 0:
            bytes_to_get = min(length, RECV_CHUNK_SIZE)
            # sometimes it doesn't send the full buffer
            chunk_data = sock.recv(bytes_to_get)
            all_data.append(chunk_data)
            length -= len(chunk_data)
        joined_data = ''.join([x.decode('utf-8') for x in all_data])
        return SwankMessage(joined_data)
    except socket.error:
        # not always an error, since we poll most of the time anyway
        return


def get_all_messages(sock, event, thread_queue):
    # this is the thread routine that gets all messages forever from the Lisp server
    while True:
        # loop forever and raise messages
        data = get_message(sock, timeout=2)
        if data is not None:
            thread_queue.put(Message(Target.SWANK, 'message', data))
        if event.is_set():
            # end this event and exit
            return


class LispRuntime:
    def __init__(self, root_path, binary_path):
        # controls the lisp binary that runs swank
        self.lisp_binary = binary_path
        self.swank_file = self.get_swank_file(root_path)
        logger.info(f'Swank startup file found at {self.swank_file}')
        self.process = None
        self.event = threading.Event()
        self.queue = queue.LifoQueue()
        self.listen_thread = threading.Thread(target=self.get_lisp_output)

    @property
    def running(self):
        return self.process is not None

    def get_lisp_output(self):
        # this is the thread to get the output of the lisp process
        while not self.event.is_set():
            output = self.process.stdout.readline()
            if len(output) != 0:
                self.queue.put(Message(Target.LOGS, data=f"LISP: {str(output, encoding='utf-8')}"))
            time.sleep(0.2)

    def start(self):
        # start the server; returns False if not started
        if self.lisp_binary is None:
            logger.info('Assuming Lisp server already started')
            return False
        if self.process is not None:
            logger.error('Lisp server already started, but asked to start again')
            return False
        logger.info(f'Starting Lisp server at {self.lisp_binary}')
        self.process = subprocess.Popen([self.lisp_binary, '--load', str(self.swank_file)],
                                         stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        self.listen_thread.start()
        return True

    def stop(self):
        logger.info('Killing Lisp server')
        if self.process is None:
            # already stopped
            return
        self.process.terminate()
        try:
            self.process.communicate(timeout=0.2)
        except subprocess.TimeoutExpired:
            logger.error('Process timed out on close - killing')
            self.process.kill()
        # kill the listening thread
        self.event.set()
        self.listen_thread.join()
        logger.info('Server and listener thread killed')

    def get_swank_file(self, root_dir):
        if root_dir is None:
            return Path().resolve() / SWANK_SCRIPT
        return Path(root_dir) / SWANK_SCRIPT


class LispConnectThread:
    def __init__(self):
        self.event = threading.Event()
        self.queue = queue.LifoQueue()
        self.lisp_connect = threading.Thread(target=self.connect_to_lisp)

    def start(self):
        self.lisp_connect.start()

    def stop(self):
        self.event.set()
        self.lisp_connect.join()

    def create_connection(self):
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.connect((HOST, PORT))
            sock.setblocking(True)
            return sock, None
        except socket.error as ex:
            return None, ex

    def connect_to_lisp(self):
        # this is the thread that runs until a connection can be made
        attempts = 0
        while attempts < MAX_CONNECTION_EVENTS:
            if self.event.is_set():
                # end the thread
                break
            sock, error = self.create_connection()
            if sock is None:
                # wait half a second
                time.sleep(TIME_BETWEEN_CONNECTIONS)
            else:
                # add message to queue
                self.queue.put(Message(Target.SWANK, 'lisp-connected', sock))
                return
            attempts += 1
        self.queue.put(Message(Target.SWANK, 'lisp-connect-failure'))


class SwankType(str, Enum):
    RETURN = ':return'
    WRITE_STRING = ':write-string'
    PRES_START = ':presentation-start'
    PRES_END = ':presentation-end'
    PING = ':ping'


class SwankMessage:
    def __init__(self, text_message):
        # this is some form of tree
        # the important point is that it starts (:some_message ...
        self.ast = loads(text_message)
        self.message_type = str(self.ast[0])
        self.raw = text_message

    @property
    def last(self):
        return str(self.ast[-1])

    def __repr__(self):
        return str(self.message_type)


def requote(s, line_end=False):
    # helper function for passing correctly quoted strings to swank
    t = s.replace('\\', '\\\\')
    t = t.replace('"', '\\"')
    if line_end:
        return f'"{t}' + r'\n"'
    else:
        return f'"{t}"'


def get_text_reply(messages):
    text_reply = []
    # go through messages looking for :write-string
    for i in messages:
        data = i.split()
        message_type = data[0][2:]
        if message_type == 'write-string':
            text_reply.append(data[1][1:-1])
    return ''.join(text_reply)


class FutureMessage:
    # a message to be added to the queue to be handled in sequence
    # the return messages from other events need to complete before this message is sent
    # thus the name; it's a message that will sent to swank in the future, and maybe not now
    def __init__(self, cmd, return_event, thread, counter):
        self.cmd = cmd
        self.return_event = return_event
        self.thread = thread
        self.counter = counter


def check_queue(queues):
    # only return false if we never want to be called again
    for single_queue in queues:
        if not single_queue.empty():
            new_message = single_queue.get()
            message_queue.message(new_message)
    return True


class SwankClient:
    def __init__(self, root_path, binary_path=None):
        # messages are sent one at a time, and we wait for the transaction
        # to finish before we send the next message
        self.swank_send_queue = []
        self.received_queue = []
        self.connected = False
        self.binary_path = binary_path
        self.swank_server = LispRuntime(root_path, binary_path)
        self.counter = 1
        self.sock = None
        self.connected = False
        self.listener_thread = None
        self.listener_event = threading.Event()
        self.listener_queue = queue.LifoQueue()
        self.lisp_connect_thread = LispConnectThread()

    def start_swank(self):
        # this is done after main window is displayed
        if not config.get('start_repl'):
            logger.info('Config says to not start Lisp instance')
            return
        # start the lisp instance and the thread to connect
        self.swank_server.start()
        self.lisp_connect_thread.start()
        GLib.idle_add(check_queue, [self.lisp_connect_thread.queue,
                                    self.swank_server.queue,
                                    self.listener_queue])

    def got_lisp_connection(self, lisp_sock):
        # called when we have started Lisp and have a sock connection
        self.sock = lisp_sock
        self.sock = lisp_sock
        self.start_listener()
        self.connected = True
        # the lisp connect thread should have finished, but just check here
        self.lisp_connect_thread.stop()
        self.swank_init()

    def lisp_connection_failed(self, ex):
        logger.error('Could not connect to Lisp server: {ex}')
        # inform the console
        message_queue.message(Message(Target.CONSOLE, 'no-lisp-connection', str(ex)))

    def swank_init(self):
        # send init command
        self.send_swank_message(SWANK1)
        self.send_swank_message(SWANK2)
        self.send_swank_message(SWANK3)
        self.send_swank_message(SWANK4, Message(Target.SWANK, 'init-complete', None))

    def start_listener(self):
        # create a new thread and obtain messages from it
        self.listener_thread = threading.Thread(target=get_all_messages, args=(self.sock, self.listener_event, self.listener_queue))
        self.listener_thread.start()

    def stop_listener(self):
        logger.info('Stopping Swank client')
        # kill the listening thread
        if self.listener_thread is not None:
            self.listener_event.set()
        self.listener_thread.join()
        # kill the Lisp instance and it's thread checking stdout
        self.swank_server.stop()

    def swank_send(self, text):
        l = "%06x" % len(str(text))
        t = l + text
        try:
            message = t.encode('utf-8')
            logger.info(f'Sending: {message}')
            self.sock.send(message)
        except socket.error:
            logger.error('* Socket error when sending: {ex}')
            raise EnvironmentError

    def swank_rex(self, cmd, counter, package=PACKAGE, thread=THREAD):
        # Send an :emacs-rex command to SWANK
        form = f'(:emacs-rex {cmd} "{package}" {thread} {counter})'
        self.swank_send(form)

    def send_swank_message(self, cmd, return_event=None, thread=THREAD):
        # send the given swank command
        # It will be placed into a queue. When the return data is finished,
        # all the messages will be put into a list on the return_event object data
        # and then the message sent
        if not self.connected:
            logger.info('Not sending message: Lisp instance not connected')
            return
        self.swank_send_queue.append(FutureMessage(cmd, return_event, thread, self.counter))
        self.counter += 1
        if len(self.swank_send_queue) == 1:
            # it's the only message, so send it; all other messages need the current message to be complete
            self.swank_rex(cmd, self.counter - 1, thread=thread)

    def eval(self, exp):
        # helper function for simple evaluations
        cmd = f'(swank-repl:listener-eval {requote(exp, line_end=False)})'
        self.send_swank_message(cmd, Message(Target.CONSOLE, 'eval-return', []), thread=':repl-thread')

    def send_next_message(self, swank_message):
        # we finally have a "return" message, so we can close off a message
        # if nothing is awaiting, then ignore
        return_value = swank_message.data.last
        while len(self.swank_send_queue) > 0:
            # the last message sent is still on the queue
            oldest_message = self.swank_send_queue.pop(0)
            if str(oldest_message.counter) != return_value:
                # keep cycling until we match the return index with the message
                continue
            # we are looking at the right message
            return_message = oldest_message.return_event
            if return_message is None:
                # nothing to do except tidy up
                self.received_queue = []
                break
            # Along with the message we send as data all the swank messages that replied
            # it is up to the message receiver to sort these out
            return_message.data = self.received_queue
            self.received_queue = []
            # broadcast the message now we have the swank reply
            message_queue.message(return_message)
            break
        # finally, send next message to swank if it exists
        if len(self.swank_send_queue) > 0:
            send_message = self.swank_send_queue[0]
            self.swank_rex(send_message.cmd, send_message.counter, thread=send_message.thread)

    def check_write_string(self, message):
        # when we have the format "(:write-string x nil some_int)"
        # swank is asking use to print the given text and then return a message
        # (:write-done some_int)
        # when this happens the ast looks like [Symbol, String, [], some_int]
        # so we examine the last 2 (we already know it starts :write-string)
        if len(message.data.ast) == 4:
            if len(message.data.ast[2]) == 0 and isinstance(message.data.ast[3], int):
                int_value = str(message.data.ast[3])
                self.swank_send(f'(:write-done {message.data.ast[3]})')
        # in all cases, add it to the list of messages to complete when done
        self.received_queue.append(message)

    def handle_message(self, swank_message):
        # swank_message is a SwankMessage
        logger.info(f'Swank reply: {swank_message.data.raw}')
        print(f'Swank reply: {swank_message.data.raw}')
        message_type = swank_message.data.message_type
        if message_type == SwankType.RETURN:
            self.send_next_message(swank_message)
        elif message_type == SwankType.PING:
            self.return_ping(swank_message)
        elif message_type == SwankType.WRITE_STRING:
            self.check_write_string(swank_message)
        else:
            # save the message for later
            self.received_queue.append(swank_message)

    def return_ping(self, message):
        response = f'(:EMACS-PONG {message.ast[1]} {message.ast[2]}'
        self.swank_send(response)

    def kill_all_threads(self):
        self.swank_server.stop()
        self.lisp_connect_thread.stop()

    def message(self, message):
        match message.action:
            case 'message':
                self.handle_message(message)
            case 'repl-cmd':
                self.eval(message.data)
            case 'lost-connection':
                # error and restart lisp binary?
                logger.error('Lost Lisp binary connection')
            case 'init-complete':
                logger.info('Swank setup complete')
                message_queue.message(Message(Target.CONSOLE, 'lisp-connected'))
            case 'start-swank':
                self.start_swank()
            case 'lisp-connected':
                self.got_lisp_connection(message.data)
            case 'lisp-connect-failure':
                self.lisp_connection_failed(message.data)
            case 'kill-threads':
                self.kill_all_threads()
            case _:
                logger.error(f'No such message action {message.action} for Swank')


if __name__ == '__main__':
    client = SwankClient(None)
    message_queue.set_resolver(client.message)
    client.swank_init()
    # this will be sent after the init is complete
    client.eval('(+ 1 2)')
    while True:
        pass
