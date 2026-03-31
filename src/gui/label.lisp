(in-package :minerva.gui)

(defclass label (widget)
  ((text :initarg :text :accessor label-text :initform "")
  (font-name :initarg :font-name :accessor label-font-name :initform theme:default-font)
  (text-size :initarg :text-size :accessor label-text-size :initform theme:default-font-size)
  (color :initarg :color :accessor label-color :initform theme:default-font-color)
   (surface :accessor label-surface :initform nil)
   (draw-rect :accessor label-draw-rect :initform (make-rect))))

(defun %string-ends-with (value suffix)
  (let ((value-length (length value))
        (suffix-length (length suffix)))
    (and (>= value-length suffix-length)
         (string-equal suffix value :start2 (- value-length suffix-length)))))

(defun %label-font-path (font-name)
  (let* ((name (or font-name theme:default-font))
         (looks-like-path (or (position #\/ name)
                              (position #\: name)
                              (%string-ends-with name ".ttf")))
         (font-file-name (if (%string-ends-with name ".ttf")
                             name
                             (format nil "~A.ttf" name))))
    (if looks-like-path
        name
        (let ((project-root (or (ignore-errors (asdf:system-source-directory "minerva"))
                                (truename "./"))))
          (namestring (merge-pathnames (format nil "minerva/assets/fonts/~A" font-file-name)
                                       project-root))))))

(defun %label-color-components (color)
  (destructuring-bind (r g b &optional (a 255))
      (if (listp color)
          color
          (list (color-r color)
                (color-g color)
                (color-b color)
                (color-a color)))
    (values r g b a)))

(defun %render-label-text-surface (font-name text-size text color)
  (let ((get-font-fn (%gfx-function "GET-FONT"))
        (destroy-font-fn (%gfx-function "DESTROY-FONT"))
        (render-text-fn (%gfx-function "RENDER-TEXT-TO-SURFACE"))
        (make-color-fn (%gfx-function "MAKE-COLOR")))
    (unless (and get-font-fn destroy-font-fn render-text-fn make-color-fn)
      (error "minerva.gfx text rendering functions are unavailable. Load src/gfx/ffi.lisp and src/gfx/backend.lisp first."))
    (let ((font nil))
      (unwind-protect
           (progn
             (setf font (funcall get-font-fn (%label-font-path font-name) (max 1 (%non-negative-int text-size))))
             (multiple-value-bind (r g b a)
                 (%label-color-components color)
               (funcall render-text-fn
                        font
                        (or text "")
                        (funcall make-color-fn :r r :g g :b b :a a))))
        (when font
          (funcall destroy-font-fn font))))))

(defun %label-placement (widget)
  (let* ((layout-rect (widget-layout-rect widget))
         (label-width (%surface-width (label-surface widget)))
         (label-height (%surface-height (label-surface widget)))
         (allocated-x (rect-x layout-rect))
         (allocated-y (rect-y layout-rect))
         (allocated-width (rect-width layout-rect))
         (allocated-height (rect-height layout-rect))
         (dest-x (%align-position allocated-x allocated-width label-width (%alignment-x (widget-content-alignment widget))))
         (dest-y (%align-position allocated-y allocated-height label-height (%alignment-y (widget-content-alignment widget))))
         (clip-left (max allocated-x dest-x))
         (clip-top (max allocated-y dest-y))
         (clip-right (min (+ allocated-x allocated-width) (+ dest-x label-width)))
         (clip-bottom (min (+ allocated-y allocated-height) (+ dest-y label-height)))
         (draw-width (max 0 (- clip-right clip-left)))
         (draw-height (max 0 (- clip-bottom clip-top))))
    (values (make-rect :x clip-left :y clip-top :width draw-width :height draw-height)
            (make-rect :x (max 0 (- clip-left dest-x))
                       :y (max 0 (- clip-top dest-y))
                       :width draw-width
                       :height draw-height))))

(defmethod initialize-instance :after ((lbl label) &key)
  (setf (label-surface lbl)
        (%render-label-text-surface (label-font-name lbl)
                                    (label-text-size lbl)
                                    (label-text lbl)
                                    (label-color lbl))))

(defmethod measure ((lbl label))
  (%apply-widget-margins-to-size-request
   lbl
   (%widget-size-request lbl
                         (%surface-width (label-surface lbl))
                         (%surface-height (label-surface lbl))
                         :expand-x nil
                         :expand-y nil)))

(defmethod layout ((lbl label) rect)
  (setf (widget-layout-rect lbl) (%apply-widget-margins-to-rect lbl rect))
  (multiple-value-bind (dest-rect source-rect)
      (%label-placement lbl)
    (declare (ignore source-rect))
    (setf (label-draw-rect lbl) dest-rect))
  lbl)

(defmethod render ((lbl label) backend-window)
  (let ((surface (label-surface lbl)))
    (when surface
      (multiple-value-bind (dest-rect source-rect)
          (%label-placement lbl)
        (setf (label-draw-rect lbl) dest-rect)
        (when (and (> (rect-width dest-rect) 0)
                   (> (rect-height dest-rect) 0))
          (%call-draw-surface-rect backend-window
                                   surface
                                   source-rect
                                   (rect-x dest-rect)
                                   (rect-y dest-rect))))))
  lbl)