#!/usr/bin/sbcl --script

(load "~/quicklisp/setup.lisp")
(ql:quickload "cl-cffi-gtk")

;define a package with our namespaces in it
(defpackage :lisp-editor
  (:use :gtk :gdk :gdk-pixbuf :gobject
   :glib :gio :pango :cairo :common-lisp))

;say we are going to use this package
(in-package :lisp-editor)

(defconstant NAME "Minerva")

(defun lisp-editor ()
  (within-main-loop
    ;Create a toplevel window.
    (let ((window (make-instance 'gtk-window'
                                 :type :toplevel
                                 :title NAME)))
      ;; Signal handler for the window to handle the signal "destroy".
      (g-signal-connect window "destroy"
                        (lambda (widget)
                          (declare (ignore widget))
                          (leave-gtk-main)))
      ;; Show the window.
      (gtk-widget-show-all window))))

;create the GUI and then wait for GUI thread to finish
(lisp-editor)
(join-gtk-main)
