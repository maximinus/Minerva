import time
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
        print(f'Error: {ex}')
        return


def get_all_messages(sock):
    while True:
        # loop forever and raise messages
        data = get_message(sock)
        if data is None:
            message_queue.message(Message(Target.SWANK, 'lost-connection', None))
        else:
            message_queue.message(Message(Target.SWANK, 'message', data))


def wait_for_reply(sock, reply_count, timeout):
    # pump messages until we have a :return with 4
    # this should be pretty fast: we will only wait 3 seconds
    start_time = datetime.now()
    while (datetime.now() - start_time).seconds < timeout:
        message = get_message(sock, timeout=timeout)
        if message is None:
            raise ConnectionError
        if message.message_type == SwankType.RETURN:
            if message.ast[-1] == reply_count:
                return
    raise ConnectionError


class SwankClient:
    def __init__(self, root_path, binary_path=None):
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
        self.listener_thread = self.start_listener()

    def start_listener(self):
        # create a new thread and obtain messages from it
        if self.connected is False:
            return
        listener_thread = threading.Thread(target=get_message, args=(self.sock,))
        listener_thread.start()
        return listener_thread

    def swank_init(self):
        # send init command
        try:
            self.swank_rex_and_wait(SWANK1, 5)
            self.swank_rex_and_wait(SWANK2, 5)
            self.swank_rex_and_wait(SWANK3, 5)
            self.swank_rex_and_wait(SWANK4, 5)
            self.connected = True
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
        print(f'Sending: {text}')
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

    def swank_rex_and_wait(self, cmd, timeout=2):
        # used in init: send data and wait for reply
        self.swank_rex(cmd)
        wait_for_reply(self.sock, self.counter - 1, timeout)

    def eval(self, exp):
        print(f'Got: {exp}')
        if not self.connected:
            logger.info('Not evaluating: Lisp instance not connected')
            return
        try:
            cmd = f'(swank-repl:listener-eval {requote(exp, line_end=False)})'
            self.swank_rex(cmd, thread=':repl-thread')
            return ''
        except EnvironmentError:
            # We are no longer connected
            return ''

    def handle_message(self, swank_message):
        # what we get is the full message data. Decide what to do with it
        print(swank_message)
        if swank_message.message_type == SwankType.RETURN:
            pass
        elif swank_message.message_type == SwankType.WRITE_STRING:
            pass
        elif swank_message.message_type == SwankType.PRES_START:
            pass
        elif swank_message.message_type == SwankType.PRES_END:
            pass
        elif swank_message.message_type == SwankType.PING:
            self.return_ping(swank_message)

    def return_ping(self, message):
        response = f'(:EMACS-PONG {message.ast[1]} {message.ast[2]}'
        self.swank_send(response)

    def message(self, message):
        print(f'Got message {message.data}')
        # got something back from swank, act on it
        if message.action == 'message':
            self.handle_message(message)
        elif message.action == 'lost-connection':
            # error and restart lisp binary?
            logger.error('Lost Lisp binary connection')


if __name__ == '__main__':
    client = SwankClient(None)
    time.sleep(1)
    print(client.eval('(+ 1 2)'))
