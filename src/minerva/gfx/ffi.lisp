(defpackage :minerva.gfx.ffi
  (:use :cl :sb-alien)
  (:export
   :event-none
   :event-quit
   :event-window-resized
   :event-key-down
   :event-key-up
   :event-mouse-button-down
   :event-mouse-button-up
   :event-mouse-move
   :c-window
   :c-event
   :ensure-native-library-loaded
   :%init
   :%shutdown
   :%last-error
   :%window-create
   :%window-destroy
   :%window-should-close
   :%window-request-close
   :%window-get-size
   :%poll-event
   :%begin-frame
   :%clear
   :%fill-rect
   :%end-frame
   :%ticks-ms
   :%sleep-ms))

(in-package :minerva.gfx.ffi)

(defconstant event-none 0)
(defconstant event-quit 1)
(defconstant event-window-resized 2)
(defconstant event-key-down 3)
(defconstant event-key-up 4)
(defconstant event-mouse-button-down 5)
(defconstant event-mouse-button-up 6)
(defconstant event-mouse-move 7)

(defvar *native-library-loaded* nil)
(defparameter *ffi-source-file*
  (or *load-truename* *load-pathname*))

(defun %this-file-dir ()
  (let ((source *ffi-source-file*))
    (unless source
      (error "Cannot determine file location while loading minerva/gfx/ffi.lisp"))
    (make-pathname :name nil :type nil :defaults source)))

(defun %repo-root ()
  (truename (merge-pathnames "../../../" (%this-file-dir))))

(defun ensure-native-library-loaded ()
  (unless *native-library-loaded*
    (let* ((root (%repo-root))
           (sdl-path (merge-pathnames "build/native/_deps/sdl3-build/libSDL3.so" root))
           (native-path (merge-pathnames "build/native/libminerva_native.so" root)))
      (when (probe-file sdl-path)
        (load-shared-object (namestring sdl-path)))
      (unless (probe-file native-path)
        (error "Native library not found at ~A. Build native target first." (namestring native-path)))
      (load-shared-object (namestring native-path))
      (setf *native-library-loaded* t))))

(define-alien-type c-window (* t))

(define-alien-type c-event
  (struct c-event
    (type int)
    (a int)
    (b int)
    (c int)
    (d int)))

(define-alien-routine ("init" %init) int)
(define-alien-routine ("minerva_shutdown" %shutdown) void)
(define-alien-routine ("last_error" %last-error) c-string)

(define-alien-routine ("window_create" %window-create) c-window
  (title c-string)
  (width int)
  (height int))

(define-alien-routine ("window_destroy" %window-destroy) void
  (window c-window))

(define-alien-routine ("window_should_close" %window-should-close) int
  (window c-window))

(define-alien-routine ("window_request_close" %window-request-close) void
  (window c-window))

(define-alien-routine ("window_get_size" %window-get-size) void
  (window c-window)
  (width (* int))
  (height (* int)))

(define-alien-routine ("poll_event" %poll-event) int
  (out-event (* c-event)))

(define-alien-routine ("begin_frame" %begin-frame) void
  (window c-window))

(define-alien-routine ("clear" %clear) void
  (window c-window)
  (r unsigned-char)
  (g unsigned-char)
  (b unsigned-char)
  (a unsigned-char))

(define-alien-routine ("fill_rect" %fill-rect) void
  (window c-window)
  (x int)
  (y int)
  (width int)
  (height int)
  (r unsigned-char)
  (g unsigned-char)
  (b unsigned-char)
  (a unsigned-char))

(define-alien-routine ("end_frame" %end-frame) void
  (window c-window))

(define-alien-routine ("ticks_ms" %ticks-ms) unsigned-long-long)

(define-alien-routine ("sleep_ms" %sleep-ms) void
  (ms int))
