(defpackage :minerva.gfx
  (:nicknames :minerva-gfx)
  (:use :cl :sb-alien)
  (:import-from :minerva.gfx.ffi
                :event-none
                :event-quit
                :event-window-resized
                :event-key-down
                :event-key-up
                :event-mouse-button-down
                :event-mouse-button-up
                :event-mouse-move
                :c-event
                :c-window
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
                :%sleep-ms)
  (:export
   :backend-window
   :init-backend
   :shutdown-backend
   :backend-last-error
   :create-window
   :destroy-window
   :window-should-close-p
   :request-window-close
   :window-size
   :poll-events
   :begin-frame
   :clear-screen
   :fill-rect
   :end-frame
   :ticks-ms
   :sleep-ms))

(in-package :minerva.gfx)

(defclass backend-window ()
  ((pointer :initarg :pointer :accessor pointer)))

(defun %null-pointer-p (ptr)
  (sb-alien:null-alien ptr))

(defun backend-last-error ()
  (or (%last-error) ""))

(defun init-backend ()
  (ensure-native-library-loaded)
  (unless (= 1 (%init))
    (error "Backend init failed: ~A" (backend-last-error)))
  t)

(defun shutdown-backend ()
  (%shutdown)
  t)

(defun create-window (&key (title "Minerva") (width 800) (height 600))
  (let ((ptr (%window-create title width height)))
    (when (%null-pointer-p ptr)
      (error "window_create failed: ~A" (backend-last-error)))
    (make-instance 'backend-window :pointer ptr)))

(defun destroy-window (window)
  (when (and window (slot-boundp window 'pointer) (pointer window) (not (%null-pointer-p (pointer window))))
    (%window-destroy (pointer window))
    (setf (pointer window) nil))
  t)

(defun window-should-close-p (window)
  (= 1 (%window-should-close (pointer window))))

(defun request-window-close (window)
  (%window-request-close (pointer window))
  t)

(defun window-size (window)
  (with-alien ((w int) (h int))
    (%window-get-size (pointer window) (addr w) (addr h))
    (values w h)))

(defun %normalize-event (type a b c)
  (case type
    (#.event-none nil)
    (#.event-quit '(:quit))
    (#.event-window-resized (list :window-resized a b))
    (#.event-key-down (list :key-down a))
    (#.event-key-up (list :key-up a))
    (#.event-mouse-button-down (list :mouse-button-down a b c))
    (#.event-mouse-button-up (list :mouse-button-up a b c))
    (#.event-mouse-move (list :mouse-move a b))
    (otherwise (list :unknown-event type a b c))))

(defun poll-events ()
  (let ((events '()))
    (with-alien ((ev c-event))
      (loop while (= 1 (%poll-event (addr ev))) do
        (let* ((type (slot ev 'type))
               (a (slot ev 'minerva.gfx.ffi::a))
               (b (slot ev 'minerva.gfx.ffi::b))
               (c (slot ev 'minerva.gfx.ffi::c))
               (normalized (%normalize-event type a b c)))
          (when normalized
            (push normalized events)))))
    (nreverse events)))

(defun begin-frame (window)
  (%begin-frame (pointer window))
  t)

(defun clear-screen (window r g b a)
  (%clear (pointer window) r g b a)
  t)

(defun fill-rect (window x y width height r g b a)
  (%fill-rect (pointer window) x y width height r g b a)
  t)

(defun end-frame (window)
  (%end-frame (pointer window))
  t)

(defun ticks-ms ()
  (%ticks-ms))

(defun sleep-ms (ms)
  (%sleep-ms ms)
  t)
