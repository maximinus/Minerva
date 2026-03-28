(defpackage :minerva.gfx
  (:nicknames :minerva-gfx)
  (:use :cl :sb-alien)
  (:shadowing-import-from :minerva.common
                          :position
                          :make-position
                          :position-x
                          :position-y)
  (:import-from :minerva.common
                :rect
                :make-rect
                :rect-x
                :rect-y
                :rect-width
                :rect-height
                :color
                :make-color
                :color-r
                :color-g
                :color-b
                :color-a)
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
                :c-surface
                :c-font
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
                :%surface-create-blank
                :%surface-load-file
                :%surface-destroy
                :%surface-width
                :%surface-height
                :%surface-is-rgba32
                :%surface-fill-rect
                :%surface-fill
                :%surface-read-pixel
                :%surface-blit
                :%surface-blit-rect
                :%surface-blit-rect-scaled
                :%window-draw-surface
                :%window-draw-surface-rect
                :%window-draw-surface-rect-scaled
                :%font-get
                :%font-destroy
                :%font-measure-text
                :%font-render-text
                :%ticks-ms
                :%sleep-ms)
  (:export
   :position
   :make-position
   :position-x
   :position-y
   :rect
   :make-rect
   :rect-x
   :rect-y
   :rect-width
   :rect-height
   :color
   :make-color
   :color-r
   :color-g
   :color-b
   :color-a
   :backend-window
   :backend-surface
   :backend-font
   :pointer
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
  :create-surface
  :load-surface
  :destroy-surface
  :surface-width
  :surface-height
  :surface-rgba32-p
  :fill-surface-rect
  :fill-surface
  :read-surface-pixel
  :blit-surface
  :blit-surface-rect
  :blit-surface-rect-scaled
  :draw-surface
  :draw-surface-rect
  :draw-surface-rect-scaled
  :get-font
  :destroy-font
  :measure-text
  :render-text-to-surface
   :end-frame
   :ticks-ms
   :sleep-ms))

(in-package :minerva.gfx)

(defclass backend-window ()
  ((pointer :initarg :pointer :accessor pointer)))

(defclass backend-surface ()
  ((pointer :initarg :pointer :accessor pointer)))

(defclass backend-font ()
  ((pointer :initarg :pointer :accessor pointer)
   (name :initarg :name :accessor font-name :initform "default")
   (size :initarg :size :accessor font-size :initform 12)))

(defun %null-pointer-p (ptr)
  (sb-alien:null-alien ptr))

(defun backend-last-error ()
  (or (%last-error) ""))

(defun %signal-ffi-error (operation &optional details)
  (error 'minerva.conditions:minerva-ffi-error
         :phase :ffi
         :message (or details (backend-last-error))
         :operation operation
         :native-error (backend-last-error)
         :details details))

(defun %signal-resource-error (operation &optional details)
  (error 'minerva.conditions:minerva-resource-error
         :phase :resource
         :message (or details (backend-last-error))
         :operation operation
         :native-error (backend-last-error)
         :details details))

(defun init-backend ()
  (ensure-native-library-loaded)
  (unless (= 1 (%init))
    (%signal-ffi-error "init" "Backend init failed"))
  t)

(defun shutdown-backend ()
  (%shutdown)
  t)

(defun create-window (&key (title "Minerva") (width 800) (height 600))
  (let ((ptr (%window-create title width height)))
    (when (%null-pointer-p ptr)
      (%signal-ffi-error "window_create" (format nil "window_create failed for title=~S" title)))
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

(defun clear-screen (window color)
  (%clear (pointer window)
          (color-r color)
          (color-g color)
          (color-b color)
          (color-a color))
  t)

(defun fill-rect (window rect color)
  (%fill-rect (pointer window)
              (rect-x rect)
              (rect-y rect)
              (rect-width rect)
              (rect-height rect)
              (color-r color)
              (color-g color)
              (color-b color)
              (color-a color))
  t)

(defun end-frame (window)
  (%end-frame (pointer window))
  t)

(defun create-surface (&key width height)
  (ensure-native-library-loaded)
  (let ((ptr (%surface-create-blank width height)))
    (when (%null-pointer-p ptr)
      (%signal-resource-error "surface_create_blank"
                              (format nil "surface_create_blank failed width=~S height=~S" width height)))
    (make-instance 'backend-surface :pointer ptr)))

(defun load-surface (path)
  (ensure-native-library-loaded)
  (let ((ptr (%surface-load-file path)))
    (when (%null-pointer-p ptr)
      (%signal-resource-error "surface_load_file"
                              (format nil "surface_load_file failed path=~S" path)))
    (make-instance 'backend-surface :pointer ptr)))

(defun destroy-surface (surface)
  (when (and surface
             (slot-boundp surface 'pointer)
             (pointer surface)
             (not (%null-pointer-p (pointer surface))))
    (%surface-destroy (pointer surface))
    (setf (pointer surface) nil))
  t)

(defun surface-width (surface)
  (%surface-width (pointer surface)))

(defun surface-height (surface)
  (%surface-height (pointer surface)))

(defun surface-rgba32-p (surface)
  (= 1 (%surface-is-rgba32 (pointer surface))))

(defun fill-surface-rect (surface rect color)
  (unless (= 1 (%surface-fill-rect (pointer surface)
                                   (rect-x rect)
                                   (rect-y rect)
                                   (rect-width rect)
                                   (rect-height rect)
                                   (color-r color)
                                   (color-g color)
                                   (color-b color)
                                   (color-a color)))
    (%signal-ffi-error "surface_fill_rect" "surface_fill_rect failed"))
  t)

(defun fill-surface (surface color)
  (unless (= 1 (%surface-fill (pointer surface)
                              (color-r color)
                              (color-g color)
                              (color-b color)
                              (color-a color)))
    (%signal-ffi-error "surface_fill" "surface_fill failed"))
  t)

(defun read-surface-pixel (surface position)
  (with-alien ((r unsigned-char)
               (g unsigned-char)
               (b unsigned-char)
               (a unsigned-char))
    (unless (= 1 (%surface-read-pixel (pointer surface)
                                      (position-x position)
                                      (position-y position)
                                      (addr r)
                                      (addr g)
                                      (addr b)
                                      (addr a)))
      (%signal-ffi-error "surface_read_pixel" "surface_read_pixel failed"))
    (make-color :r r :g g :b b :a a)))

(defun %ensure-blit-success (result operation)
  (unless (= 1 result)
    (%signal-ffi-error operation (format nil "~A failed" operation)))
  t)

(defun blit-surface (source destination dest-position)
  (%ensure-blit-success
   (%surface-blit (pointer source)
                  (pointer destination)
                  (position-x dest-position)
                  (position-y dest-position))
   "surface_blit"))

(defun blit-surface-rect (source source-rect destination dest-position)
  (%ensure-blit-success
   (%surface-blit-rect (pointer source)
                       (rect-x source-rect)
                       (rect-y source-rect)
                       (rect-width source-rect)
                       (rect-height source-rect)
                       (pointer destination)
                       (position-x dest-position)
                       (position-y dest-position))
   "surface_blit_rect"))

(defun blit-surface-rect-scaled (source source-rect destination dest-rect)
  (%ensure-blit-success
   (%surface-blit-rect-scaled (pointer source)
                              (rect-x source-rect)
                              (rect-y source-rect)
                              (rect-width source-rect)
                              (rect-height source-rect)
                              (pointer destination)
                              (rect-x dest-rect)
                              (rect-y dest-rect)
                              (rect-width dest-rect)
                              (rect-height dest-rect))
   "surface_blit_rect_scaled"))

(defun draw-surface (window surface dest-position)
  (%ensure-blit-success
   (%window-draw-surface (pointer window)
                         (pointer surface)
                         (position-x dest-position)
                         (position-y dest-position))
   "window_draw_surface"))

(defun draw-surface-rect (window surface source-rect dest-position)
  (%ensure-blit-success
   (%window-draw-surface-rect (pointer window)
                              (pointer surface)
                              (rect-x source-rect)
                              (rect-y source-rect)
                              (rect-width source-rect)
                              (rect-height source-rect)
                              (position-x dest-position)
                              (position-y dest-position))
   "window_draw_surface_rect"))

(defun draw-surface-rect-scaled (window surface source-rect dest-rect)
  (%ensure-blit-success
   (%window-draw-surface-rect-scaled (pointer window)
                                     (pointer surface)
                                     (rect-x source-rect)
                                     (rect-y source-rect)
                                     (rect-width source-rect)
                                     (rect-height source-rect)
                                     (rect-x dest-rect)
                                     (rect-y dest-rect)
                                     (rect-width dest-rect)
                                     (rect-height dest-rect))
   "window_draw_surface_rect_scaled"))

(defun get-font (name-or-path size)
  (ensure-native-library-loaded)
  (let ((ptr (%font-get name-or-path size)))
    (when (%null-pointer-p ptr)
      (%signal-resource-error "font_get"
                              (format nil "font_get failed name-or-path=~S size=~S" name-or-path size)))
    (make-instance 'backend-font
                   :pointer ptr
                   :name (or name-or-path "default")
                   :size size)))

(defun destroy-font (font)
  (when (and font
             (slot-boundp font 'pointer)
             (pointer font)
             (not (%null-pointer-p (pointer font))))
    (%font-destroy (pointer font))
    (setf (pointer font) nil))
  t)

(defun measure-text (font text)
  (with-alien ((width int)
               (height int))
    (%ensure-blit-success
     (%font-measure-text (pointer font)
                         (or text "")
                         (addr width)
                         (addr height))
     "font_measure_text")
    (values width height)))

(defun render-text-to-surface (font text color)
  (let ((ptr (%font-render-text (pointer font)
                                (or text "")
                                (color-r color)
                                (color-g color)
                                (color-b color)
                                (color-a color))))
    (when (%null-pointer-p ptr)
      (%signal-resource-error "font_render_text"
                              (format nil "font_render_text failed text-length=~S" (length (or text "")))))
    (make-instance 'backend-surface :pointer ptr)))

(defun ticks-ms ()
  (%ticks-ms))

(defun sleep-ms (ms)
  (%sleep-ms ms)
  t)
