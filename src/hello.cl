#!/usr/bin/sbcl --script

(load "~/quicklisp/setup.lisp")
(ql:quickload "cl-cffi-gtk")

;define our own package
(defpackage :lisp-editor
  (:use :gtk :gdk :gdk-pixbuf :gobject
   :glib :gio :pango :cairo :common-lisp))

;say we are using lisp editor
(in-package :lisp-editor)

(defun example-simple-window ()
  (within-main-loop
    (let (;; Create a toplevel window.
          (window (gtk-window-new :toplevel)))
      ;; Signal handler for the window to handle the signal "destroy".
      (g-signal-connect window "destroy"
                        (lambda (widget)
                          (declare (ignore widget))
                          (leave-gtk-main)))
      ;; Show the window.
      (gtk-widget-show-all window))))

(example-simple-window)
(join-gtk-main)
