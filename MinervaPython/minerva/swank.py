import time
import socket
import threading
from sexpdata import loads

from minerva.logs import logger
from minerva.actions import message_queue, Message, Target

# Python client for swank server
# We open a LISP instance and communicate with it for a LISP IDE
# how to start a swank session on Lisp: sbcl --load start-swank.lisp


HOST = '127.0.0.1'
PORT = 4005

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
SWANK5 = '''(swank:autodoc '("+" "" swank::%cursor-marker%) :print-right-margin 80)'''


def requote(s, line_end=False):
    t = s.replace('\\', '\\\\')
    t = t.replace('"', '\\"')
    if line_end:
        return f'"{t}' + r'\n"'
    else:
        return f'"{t}"'


class SwankMessage:
    def __init__(self, text_message):
        # this is some form of tree
        # the important point is that it starts (:some_message
        self.ast = loads(text_message)
        self.message_type = self.ast[0]


def get_message(sock):
    while True:
        # loop forever and raise messages
        try:
            # grab the length and chunk it in
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
            message_queue.message(Message(Target.SWANK, 'message', SwankMessage(joined_data)))
        except socket.error as ex:
            print('* Could not receive: {ex}')
            message_queue.message(Message(Target.SWANK, 'lost-connection', None))


class SwankClient:
    def __init__(self, binary_path=None):
        self.connected = False
        self.binary_path = binary_path
        self.start_lisp()
        self.counter = 1
        self.sock = self.create_connection()
        if self.sock is None:
            logger.error('Could not connect to Lisp instance')
            return
        self.listener_thread = self.start_listener()
        self.swank_init()

    def start_lisp(self):
        if self.binary_path is None:
            logger.info('Assuming Lisp server already started')
        else:
            logger.info(f'Started Lisp server at {self.binary_path}')

    def start_listener(self):
        # create a new thread and obtain messages from it
        listener_thread = threading.Thread(target=get_message, args=(self.sock,))
        listener_thread.start()
        return listener_thread

    def swank_get_message(self):
        all_messages = []
        while True:
            message = get_message(self.sock)
            # convert all messages and slap together
            full_message = ''.join([x.decode('utf-8') for x in message])
            all_messages.append(full_message)
            if full_message.startswith('(:return (:ok '):
                # grab the end and check
                end_value = full_message.split()[-1][:-1]
                print(f'End: {end_value}, Count: {self.counter - 1}')
                if str(self.counter - 1) == end_value:
                    return all_messages

    def swank_init(self):
        # send init command
        try:
            self.swank_rex(SWANK1)
            self.swank_rex(SWANK2)
            self.swank_rex(SWANK3)
            self.swank_rex(SWANK4)
            self.connected = True
        except EnvironmentError:
            logger.error('Could not communicate with Lisp instance')

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
        except socket.error as ex:
            print('* Socket error when sending: {ex}')
            raise EnvironmentError

    def swank_rex(self, cmd, package=PACKAGE, thread=THREAD):
        # Send an :emacs-rex command to SWANK
        # we need to keep pumping until we see a return of the thread counter number
        form = f'(:emacs-rex {cmd} "{package}" {thread} {self.counter})'
        logger.debug(f'Swank send: {form}')
        self.counter += 1
        self.swank_send(form)
        try:
            data = self.swank_get_message()
            logger.debug('Swank return: {data}')
            return data
        except EnvironmentError:
            logger.error('Swank rex failed')

    def eval(self, exp):
        print(f'Got: {exp}')
        if not self.connected:
            logger.info('Not evaluating: Lisp instance not connected')
            return
        try:
            cmd = f'(swank-repl:listener-eval {requote(exp, line_end=False)})'
            messages = self.swank_rex(cmd, thread=':repl-thread')
            return self.get_text_reply(messages)
        except EnvironmentError:
            return

    def get_text_reply(self, messages):
        text_reply = []
        # go through messages looking for :write-string
        for i in messages:
            data = i.split()
            message_type = data[0][2:]
            if message_type == 'write-string':
                text_reply.append(data[1][1:-1])
        return ''.join(text_reply)

    def handle_message(self, swank_message):
        # what we get is the full message data. Decide what to do with it
        if swank_message.message_type == ':return':
            pass
        elif swank_message.message_type == ':write-string':
            pass
        elif swank_message.message_type == ':presentation-start':
            pass
        elif swank_message.message_type == ':presentation-end':
            pass
        elif swank_message.message_type == ':ping':
            self.return_ping(swank_message)

    def return_ping(self, message):
        response = f'(:EMACS-PONG {message.ast[1]} {message.ast[2]}'
        self.swank_send(response)

    def message(self, message):
        # got something back from swank, act on it
        if message.action == 'message':
            self.handle_message()
        elif message.action == 'lost-connection':
            # error and restart lisp binary?
            logger.error('Lost Lisp binary connection')


if __name__ == '__main__':
    client = SwankClient(None)
    time.sleep(1)
    print(client.eval('(+ 1 2)'))
