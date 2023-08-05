import socket
import threading

from enum import Enum
from pathlib import Path
from sexpdata import loads
from datetime import datetime

from minerva.logs import logger
from minerva.actions import message_queue, Message, Target

# Python client for swank server
# We open a LISP instance and communicate with it for a LISP IDE
# how to start a swank session on Lisp: sbcl --load start-swank.lisp


HOST = '127.0.0.1'
PORT = 4005
SWANK_SCRIPT = 'start-swank.lisp'

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


class LispRuntime:
    def __init__(self, root_path, binary_path):
        # controls the lisp binary that runs swank
        self.lisp_binary = binary_path
        self.swank_file = self.get_swank_file(root_path)
        self.process = None

    @property
    def running(self):
        return self.process is not None

    def start(self):
        if self.lisp_binary is None:
            logger.info('Assuming Lisp server already started')
            return
        logger.info(f'Starting Lisp server at {self.lisp_binary}')
        #self.process = subprocess.run()

    def stop(self):
        pass

    def get_swank_file(self, root_dir):
        if root_dir is None:
            return Path().resolve() / SWANK_SCRIPT
        return Path(root_dir) / SWANK_SCRIPT


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

    @property
    def last(self):
        return str(self.ast[-1])

    def __repr__(self):
        return str(self.message_type)


def requote(s, line_end=False):
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


def get_message(sock, timeout=0):
    # timeout = 0, don't wait for socket
    try:
        if timeout > 0:
            sock.settimeout(timeout)
        else:
            sock.settimeout(None)
        length_data = sock.recv(6)
        length = int(length_data, 16)
        all_data = []
        while length > 0:
            if length < 4096:
                all_data.append(sock.recv(length))
                length = 0
            else:
                all_data.append(sock.recv(4096))
                length -= 4096
        joined_data = ''.join([x.decode('utf-8') for x in all_data])
        return SwankMessage(joined_data)
    except socket.error as ex:
        # not always an error, since we poll most of the time anyway
        return


def get_all_messages(sock, event):
    # this is the thread routine that gets all messages forever
    while True:
        # loop forever and raise messages
        data = get_message(sock, 2)
        if data is not None:
            message_queue.message(Message(Target.SWANK, 'message', data))
        if event.is_set():
            # end this event and exit
            break


class SwankClient:
    def __init__(self, root_path, binary_path=None):
        # messages are sent one at a time, and we wait for the transaction
        # to finish before we send the next message
        self.message_queue = []
        self.received_queue = []
        self.connected = False
        self.swank_server = LispRuntime(root_path, binary_path)
        self.binary_path = binary_path
        self.swank_server.start()
        self.counter = 1
        self.sock = self.create_connection()
        if self.sock is None:
            logger.error('Could not connect to Lisp instance')
            return
        self.swank_init()
        self.listener_thread = None
        self.thread_event = None
        self.start_listener()

    def start_listener(self):
        # create a new thread and obtain messages from it
        if self.connected is False:
            return
        self.thread_event = threading.Event()
        self.listener_thread = threading.Thread(target=get_all_messages, args=(self.sock, self.thread_event))
        self.listener_thread.start()

    def stop_listener(self):
        logger.info('Stoppinng Swank client')
        if self.listener_thread is not None:
            self.thread_event.set()
        self.swank_server.stop()

    def swank_init(self):
        # send init command
        try:
            self.send_swank_message(SWANK1)
            self.send_swank_message(SWANK2)
            self.send_swank_message(SWANK3)
            self.send_swank_message(SWANK4, Message(Target.SWANK, 'init-complete', None))
        except ConnectionError:
            return

    def create_connection(self):
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.connect((HOST, PORT))
            sock.setblocking(True)
            return sock
        except socket.error as ex:
            print(f'* Socket error: {ex}')

    def swank_send(self, text):
        l = "%06x" % len(str(text))
        t = l + text
        try:
            self.sock.send(t.encode('utf-8'))
        except socket.error:
            print('* Socket error when sending: {ex}')
            raise EnvironmentError

    def swank_rex(self, cmd, package=PACKAGE, thread=THREAD):
        # Send an :emacs-rex command to SWANK
        form = f'(:emacs-rex {cmd} "{package}" {thread} {self.counter})'
        logger.debug(f'Swank send: {form}')
        self.counter += 1
        self.swank_send(form)

    def send_swank_message(self, cmd, return_event=None, thread=THREAD):
        # send the given swank command
        # It will be placed into a queue. When the return data is finished
        # all the messages will be put into a list on the return_event object data
        # and then the message sent
        if not self.connected:
            logger.info('Not sending message: Lisp instance not connected')
            return
        self.message_queue.append([self.counter, return_event])
        if len(self.message_queue) == 1:
            # send the message right away
            self.swank_rex(cmd, thread)

    def eval(self, exp):
        # helper function for simple evaluations
        cmd = f'(swank-repl:listener-eval {requote(exp, line_end=False)})'
        self.send_swank_message(cmd, Message(Target.CONSOLE, 'eval-return', []), thread=':repl-thread')

    def end_next_message(self, swank_message):
        # we finally have a "return" message, so we can close off a message
        # if nothing is awaiting, then ignore
        return_value = swank_message.last
        while len(self.message_queue) > 0:
            oldest_message = self.message_queue.pop(0)
            if str(oldest_message[0]) != return_value:
                continue
            # we are looking at the right message
            return_message = oldest_message[1]
            if return_message is None:
                # nothing to do except tidy up
                self.received_queue = []
                return
            oldest_message.data = self.received_queue
            self.received_queue = []
            message_queue.message(return_message)
            return
        logger.info('Got return message with nothing waiting')

    def handle_message(self, swank_message):
        # what we get is the full message data. Decide what to do with it
        message_type = swank_message.data.message_type
        print(f'Got swank reply: {message_type}')
        if message_type == SwankType.RETURN:
            self.end_next_message()
        elif swank_message.message_type == SwankType.PING:
            self.return_ping(swank_message)
        else:
            self.received_queue.append(swank_message)

    def return_ping(self, message):
        response = f'(:EMACS-PONG {message.ast[1]} {message.ast[2]}'
        self.swank_send(response)

    def message(self, message):
        # got something back from swank, act on it
        if message.action == 'message':
            self.handle_message(message)
        elif message.action == 'repl-cmd':
            self.eval(message.data)
        elif message.action == 'lost-connection':
            # error and restart lisp binary?
            logger.error('Lost Lisp binary connection')
        elif message.action == 'init-complete':
            self.connected = True
        else:
            logger.error(f'No such message action {message.action} for Swank')


if __name__ == '__main__':
    client = SwankClient(None)
    client.stop_listener()
