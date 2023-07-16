import socket

from minerva.preferences import config
from minerva.logs import logger

# Python client for swank server
# We open a LISP instance and communicate with it for a LISP IDE
# how to start a swank session on Lisp: sbcl --load start-swank.lisp


PACKAGE = 'COMMON-LISP-USER'
HOST = '127.0.0.1'
PORT = 4005


def requote(s):
    t = s.replace('\\', '\\\\')
    t = t.replace('"', '\\"')
    return '"' + t + '"'


class SwankClient:
    def __init__(self):
        lisp_path = config.lisp_binary

    def create_connection(self):
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.connect((HOST, PORT))
        except socket.error as ex:
            logger.error(f'* Socket error: {ex}')
            return
        return sock

    def swank_send(self, text):
        sock = self.create_connection()
        l = "%06x" % len(str(text))
        t = l + text
        try:
            sock.send(t.encode('utf-8'))
        except socket.error as ex:
            logger.error('* Socket error when sending: {ex}')
        return sock

    def swank_recv(self, sock):
        sock.setblocking(True)
        try:
            return sock.recv(4096)
        except socket.error as ex:
            logger.error('* Could not receive: {ex}')

    def swank_rex(self, action, cmd, package, thread, data=''):
        # Send an :emacs-rex command to SWANK
        key = "1"
        form = '(:emacs-rex ' + cmd + ' ' + package + ' ' + thread + ' ' + key + ')\n'
        sock = self.swank_send(form)
        data = self.swank_recv(sock)
        logger.info(f'* Got: {data}')
        return data

    def eval(self, exp):
        logger.info(f'Evaluating {exp}')
        cmd = '(swank-repl:listener-eval ' + requote(exp) + ')'
        self.swank_rex(':listener-eval', cmd, requote(PACKAGE), ':repl-thread')


if __name__ == '__main__':
    client = SwankClient()
    client.eval('(+ 2 3)')
