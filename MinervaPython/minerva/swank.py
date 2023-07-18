import socket

#from minerva.preferences import config
#from minerva.logs import logger

# Python client for swank server
# We open a LISP instance and communicate with it for a LISP IDE
# how to start a swank session on Lisp: sbcl --load start-swank.lisp


HOST = '127.0.0.1'
PORT = 4005

PACKAGE = 'COMMON-LISP-USER'
THREAD = 'T'
SWANK_INIT = """
(SWANK:SWANK-REQUIRE 
    '(SWANK-IO-PACKAGE::SWANK-TRACE-DIALOG SWANK-IO-PACKAGE::SWANK-PACKAGE-FU
      SWANK-IO-PACKAGE::SWANK-PRESENTATIONS SWANK-IO-PACKAGE::SWANK-FUZZY
      SWANK-IO-PACKAGE::SWANK-FANCY-INSPECTOR SWANK-IO-PACKAGE::SWANK-C-P-C
      SWANK-IO-PACKAGE::SWANK-ARGLISTS SWANK-IO-PACKAGE::SWANK-REPL))
"""
SWANK_PRESENTATION = '(SWANK:INIT-PRESENTATIONS)'
SWANK_CODE = '(SWANK-REPL:CREATE-REPL NIL :CODING-SYSTEM "utf-8-unix")'


def requote(s):
    t = s.replace('\\', '\\\\')
    t = t.replace('"', '\\"')
    return '"' + t + '"'


class SwankClient:
    def __init__(self):
        #self.lisp_path = config.lisp_binary
        self.counter = 1
        self.sock = self.create_connection()
        # send init command
        self.swank_rex(SWANK_INIT)
        self.swank_rex(SWANK_PRESENTATION)
        self.swank_rex(SWANK_CODE)

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
            return self.sock.recv(4096)
        except socket.error as ex:
            print('* Could not receive: {ex}')

    def swank_rex(self, cmd, package=PACKAGE, thread=THREAD):
        # Send an :emacs-rex command to SWANK
        form = f'(:EMACS-REX {cmd} "{package}" {thread} {self.counter})'
        self.counter += 1
        self.swank_send(form)
        data = self.swank_recv()
        print(f'* Got: {data}')
        return data

    def eval(self, exp):
        print(f'Evaluating {exp}')
        cmd = f'(SWANK-REPL:LISTENER-EVAL {requote(exp)})'
        return self.swank_rex(cmd, thread=':REPL-THREAD')


if __name__ == '__main__':
    client = SwankClient()
    client.eval('(+ 2 3)')
    # result
    # ("SB-C")) ("do-nested-cleanups" 1 ("SB-C")) ("with-ir1-namespace" 0 ("SB-C")) ("do-inheritable-constraints" 1 ("SB-C")) ("processing-decls" 1 ("SB-C")) ("do-uses" 1 ("SB-C")) ("when-vop-existsp" 1 ("SB-C")) ("defpattern" 3 ("SB-X86-64-ASM" "SB-VM" "SB-REGALLOC" "SB-FASL" "SB-ASSEM" "SB-C")) ("assemble" 1 ("SB-X86-64-ASM" "SB-VM" "SB-REGALLOC" "SB-FASL" "SB-ASSEM" "SB-C")) ("without-scheduling" 1 ("SB-X86-64-ASM" "SB-VM" "SB-REGALLOC" "SB-FASL" "SB-ASSEM" "SB-C")) ("define-instruction-macro" 2 ("SB-X86-64-ASM" "SB-VM" "SB-REGALLOC" "SB-FASL" "SB-ASSEM" "SB-C")) ("with-modified-segment-index-and-posn" 1 ("SB-ASSEM")) ("acase" 1 ("QL-HTTP")) ("match" 1 ("SWANK" "SWANK/MATCH")) ("with-minimax-value" 1 ("SB-LOOP")) ("with-sum-count" 1 ("SB-LOOP")) ("with-loop-list-collection-head" 1 ("SB-LOOP")) ("with-read-buffer" 1 ("SB-IMPL")) ("when-extended-sequence-type" 1 ("SB-IMPL")) ("with-symbol" 1 ("SB-IMPL")) ("with-active-processes-lock" 1 ("SB-IMPL")) ("output-wrapper" 1 ("SB-IMPL")) ("input-wrapper/variable-width" 1 ("SB-IMPL")) ("handling-end-of-the-world" 0 ("SB-IMPL")) ("with-package-names" 1 ("SB-IMPL")) ("with-native-pathname" 1 ("SB-IMPL")) ("matchify-list" 1 ("SB-IMPL")) ("with-args" 1 ("SB-IMPL")) ("with-descriptor-handlers" 0 ("SB-IMPL")) ("with-stepping-enabled" 0 ("SB-IMPL")) ("with-push-char" 1 ("SB-IMPL")) ("with-host" 1 ("SB-IMPL")) ("output-wrapper/variable-width" 1 ("SB-IMPL")) ("with-member-test" 1 ("SB-IMPL")) ("with-native-directory-iterator" 1 ("SB-IMPL")) ("with-environment" 1 ("SB-IMPL")) ("with-scheduler-lock" 1 ("SB-IMPL")) ("with-package-graph" 1 ("SB-IMPL")) ("with-one-string" 1 ("SB-IMPL")) ("with-weak-hash-table-entry" 0 ("SB-IMPL")) ("with-stepping-disabled" 0 ("SB-IMPL")) ("do-vector-data" 1 ("SB-IMPL")) ("find-package-restarts" 1 ("SB-IMPL")) ("do-packages" 1 ("SB-IMPL")) ("with-packed-info-iterator" 1 ("SB-IMPL")) ("with-finalizer-store" 1 ("SB-IMPL")) ("describe-block" 1 ("SB-IMPL")) ("with-pathname" 1 ("SB-IMPL")) ("map-into-lambda" 2 ("SB-IMPL")) ("with-case-info" 1 ("SB-IMPL")) ("input-wrapper" 1 ("SB-IMPL")) ("with-fd-setsize" 1 ("SB-UNIX")) ("with-program-output" 1 ("UIOP/RUN-PROGRAM")) ("with-program-input" 1 ("UIOP/RUN-PROGRAM")) ("with-program-error-output" 1 ("UIOP/RUN-PROGRAM")) ("define-alien-callable" 3 ("SB-VM" "SB-REGALLOC" "SB-FASL" "SB-BIGNUM" "SB-POSIX" "SB-BSD-SOCKETS-INTERNAL" "SB-KERNEL" "SB-THREAD" "SB-APROF" "SB-INT" "COMMON-LISP-USER" "SB-ALIEN" "SB-UNIX" "SB-IMPL" "SB-C" "SB-EXT")) ("with-alien" 1 ("SB-VM" "SB-REGALLOC" "SB-FASL" "SB-BIGNUM" "SB-POSIX" "SB-BSD-SOCKETS-INTERNAL" "SB-KERNEL" "SB-THREAD" "SB-APROF" "SB-INT" "COMMON-LISP-USER" "SB-ALIEN" "SB-UNIX" "SB-IMPL" "SB-C" "SB-EXT")) ("define-alien-callback" 3 ("SB-ALIEN")) ("alien-lambda" 2 ("SB-ALIEN")) ("with-auxiliary-alien-types" 1 ("SB-ALIEN")) ("walker-environment-bind" 1 ("SB-WALKER")) ("with-augmented-environment" 1 ("SB-WALKER")) ("with-new-definition-in-environment" 1 ("SB-WALKER")) ("program-destructuring-bind" 2 ("SB-EVAL")) ("with-temporary-file" 1 ("QUICKLISP-CLIENT" "QL-DIST" "QL-UTIL" "QL-CONFIG")) ("without-prompting" 0 ("QUICKLISP-CLIENT" "QL-DIST" "QL-UTIL" "QL-CONFIG")) ("in-interruption" 1 ("SB-X86-64-ASM" "SB-DISASSEM" "SB-VM" "SB-REGALLOC" "SB-FASL" "SB-BIGNUM" "SB-LOCKLESS" "SB-KERNEL" "SB-THREAD" "SB-DEBUG" "SB-DI" "SB-APROF" "SB-INT" "SB-SYS" "SB-ALIEN" "SB-UNIX" "SB-IMPL" "SB-C" "SB-EXT")) ("with-code-pages-pinned" 1 ("SB-X86-64-ASM" "SB-DISASSEM" "SB-VM" "SB-REGALLOC" "SB-FASL" "SB-BIGNUM" "SB-LOCKLESS" "SB-KERNEL" "SB-THREAD" "SB-DEBUG" "SB-DI" "SB-APROF" "SB-INT" "SB-SYS" "SB-ALIEN" "SB-UNIX" "SB-IMPL" "SB-C" "SB-EXT")) ("with-deadline" 1 ("SB-X86-64-ASM" "SB-DISASSEM" "SB-VM" "SB-REGALLOC" "SB-FASL" "SB-BIGNUM" "SB-LOCKLESS" "SB-KERNEL" "SB-THREAD" "SB-DEBUG" "SB-DI" "SB-APROF" "SB-INT" "SB-SYS" "SB-ALIEN" "SB-UNIX" "SB-IMPL" "SB-C" "SB-EXT")) ("with-local-interrupts" 0 ("SB-X86-64-ASM" "SB-DISASSEM" "SB-VM" "SB-REGALLOC" "SB-FASL" "SB-BIGNUM" "SB-LOCKLESS" "SB-KERNEL" "SB-THREAD" "SB-DEBUG" "SB-DI" "SB-APROF" "SB-INT" "SB-SYS" "SB-ALIEN" "SB-UNIX" "SB-IMPL" "SB-C" "SB-EXT")) ("with-in'

