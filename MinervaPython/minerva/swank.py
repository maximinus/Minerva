import socket
import time

#from minerva.preferences import config
#from minerva.logs import logger

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

# numbers 1+2 reply perfectly
SWANK1 = '(swank:connection-info)'
SWANK2 = f'''(swank:swank-require '({" ".join(SWANK_REQUIRES)}))'''
SWANK3 = '(swank:init-presentations)'
SWANK4 = '(swank-repl:create-repl nil :coding-system "utf-8-unix")'
SWANK5 = '''(swank:autodoc '("+" "" swank::%cursor-marker%) :print-right-margin 80)'''
SWANK6 = '''(swank:autodoc '("+" "1" swank::%cursor-marker%) :print-right-margin 80)'''
SWANK7 = '''(swank:autodoc '("+" "1" "" swank::%cursor-marker%) :print-right-margin 80)'''
SWANK8 = '''(swank:autodoc '("+" "1" "2" swank::%cursor-marker%) :print-right-margin 80)'''


def requote(s, line_end=False):
    t = s.replace('\\', '\\\\')
    t = t.replace('"', '\\"')
    if line_end:
        return f'"{t}' + r'\n"'
    else:
        return f'"{t}"'


class SwankClient:
    def __init__(self):
        #self.lisp_path = config.lisp_binary
        self.counter = 1
        self.sock = self.create_connection()
        if self.sock is None:
            return
        self.swank_init()

    def swank_init(self):
        # send init command
        self.swank_rex(SWANK1)
        self.swank_rex(SWANK2)
        self.swank_rex(SWANK3)
        self.swank_rex(SWANK4)
        #time.sleep(1)
        #self.swank_rex(SWANK5)
        #time.sleep(1)
        #self.swank_rex(SWANK6)
        #time.sleep(1)
        #self.swank_rex(SWANK7)
        #time.sleep(1)
        #self.swank_rex(SWANK8)

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
        except socket.error as ex:
            print('* Socket error when sending: {ex}')

    def swank_recv(self):
        try:
            # grab the length and chunk it in
            length_data = self.sock.recv(6)
            length = int(length_data, 16)
            all_data = []
            while length > 0:
                all_data.append(self.sock.recv(4096))
                length -= 4096
            return all_data
        except socket.error as ex:
            print('* Could not receive: {ex}')

    def swank_rex(self, cmd, package=PACKAGE, thread=THREAD):
        # Send an :emacs-rex command to SWANK
        form = f'(:emacs-rex {cmd} "{package}" {thread} {self.counter})'
        self.counter += 1
        self.swank_send(form)
        data = self.swank_recv()
        print(f'* Got: {data}')
        return data

    def eval(self, exp):
        cmd = f'(swank-repl:listener-eval {requote(exp, line_end=True)})'
        return self.swank_rex(cmd, thread=':repl-thread')


if __name__ == '__main__':
    client = SwankClient()
    time.sleep(1)
    client.eval('(+ 1 2)')
