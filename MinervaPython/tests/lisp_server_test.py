import threading
import time
import socket
import queue
import subprocess

from pathlib import Path

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, GLib

HOST = '127.0.0.1'
PORT = 4005

# code to test stopping / starting the list server

# What we want:
# Start a new thread that will start the lisp server
# Start another thread that will connect with this server

# Both threads should be killable at any point
# A thread should be able to raise a message (that needs to be on the main thread)
# The thread that connects needs to return the sock connection


def print_to_console(process, event, message_queue):
    while not event.is_set():
        output = process.stdout.readline()
        if len(output) != 0:
            message_queue.put(output)
        time.sleep(0.2)


class LispRuntime:
    def __init__(self):
        # controls the lisp binary that runs swank
        self.lisp_binary = '/usr/bin/sbcl'
        self.swank_file = Path(__file__).parent.parent / 'start-swank.lisp'
        self.process = None
        self.message_queue = queue.LifoQueue()
        self.event = threading.Event()

    @property
    def running(self):
        return self.process is not None

    def start(self):
        print(f'Starting Lisp server at {self.lisp_binary}')
        self.process = subprocess.Popen([self.lisp_binary, '--load', str(self.swank_file)],
                                         stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        self.listen_thread = threading.Thread(target=print_to_console, args=(self.process, self.event, self.message_queue))
        self.listen_thread.start()

    def stop(self):
        if self.process is None:
            # already stopped
            return
        self.process.terminate()
        try:
            self.process.communicate(timeout=0.2)
        except subprocess.TimeoutExpired:
            print('Process timed out on close - killing')
            self.process.kill()
        self.event.set()
        self.listen_thread.join()
        print('Stopped listening thread')


def create_connection():
    print('Trying to connect')
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect((HOST, PORT))
        sock.setblocking(True)
        return sock, None
    except socket.error as ex:
        return None, ex


def connect_to_lisp(message_queue, event):
    # this is the thread that runs until a connection can be made
    attempts = 0
    while attempts < 20:
        if event.is_set():
            # end the thread
            break
        sock, error = create_connection()
        if sock is None:
            # wait half a second
            time.sleep(0.5)
        else:
            # add message to queue
            message_queue.put(['lisp-connected', sock])
            return
        attempts += 1
    message_queue.put(['lisp-connect-fail', None])


def check_queue(queues):
    message_queue = queues[0]
    lisp_queue = queues[1]
    # only return false if we never want to be called again
    if not message_queue.empty():
        message = message_queue.get()
        print(f'Got: {message[0]}')

    if not lisp_queue.empty():
        message = lisp_queue.get()
        print(f'Lisp: {message}')
    return True


def exit_app(_widget, event, starter_thread, runtime):
    print('Closing')
    runtime.stop()
    event.set()
    print('Waiting for thread to exit')
    starter_thread.join()
    Gtk.main_quit()


if __name__ == '__main__':
    win = Gtk.Window()
    win.show_all()
    server = LispRuntime()
    server.start()
    # start the connection thread
    new_queue = queue.LifoQueue()
    thread_event = threading.Event()
    start_thread = threading.Thread(target=connect_to_lisp, args=(new_queue, thread_event))
    start_thread.start()
    GLib.idle_add(check_queue, [new_queue, server.message_queue])
    win.connect('destroy', exit_app, thread_event, start_thread, server)
    Gtk.main()
