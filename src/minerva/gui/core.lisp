(defpackage :minerva.gui
  (:nicknames :minerva-gui)
  (:use :cl)
  (:import-from :minerva.common
                :color
                :make-position
                :position-x
                :position-y
                :make-size
                :size-width
                :size-height
                :rect
                :make-rect
                :rect-x
                :rect-y
                :rect-width
                :rect-height
                :make-color
                :color-r
                :color-g
                :color-b
                :color-a)
  (:export
   :rect
   :make-rect
   :rect-x
   :rect-y
   :rect-width
   :rect-height
   :size-request
   :make-size-request
   :size-request-min-width
   :size-request-min-height
   :size-request-expand-x
   :size-request-expand-y
   :widget
   :widget-layout-rect
  :widget-background-color
  :widget-content-alignment
  :widget-margin-left
  :widget-margin-right
  :widget-margin-top
  :widget-margin-bottom
   :measure
   :layout
   :render
   :window
   :window-width
   :window-height
   :window-child
   :hbox
   :hbox-children
   :hbox-spacing
   :hbox-align-y
   :vbox
   :vbox-children
   :vbox-spacing
   :vbox-align-x
   :color-rect
   :color-rect-min-width
   :color-rect-min-height
   :color-rect-expand-x
   :color-rect-expand-y
   :color-rect-color
   :filler
   :filler-min-width
   :filler-min-height
   :filler-expand-x
   :filler-expand-y
  :image
  :image-surface
  :image-draw-rect
  :nine-patch
  :nine-patch-surface
  :nine-patch-border-left
  :nine-patch-border-right
  :nine-patch-border-top
  :nine-patch-border-bottom
  :nine-patch-child
  :nine-patch-content-rect
   :measure-min-width
   :measure-min-height
   :measure-expand-x
   :measure-expand-y))

(in-package :minerva.gui)

(defstruct size-request
  (min-width 0 :type integer)
  (min-height 0 :type integer)
  (expand-x nil :type boolean)
  (expand-y nil :type boolean))

(defclass widget ()
  ((layout-rect :initform (make-rect)
                :accessor widget-layout-rect)
   (background-color :initarg :background-color
                     :initform nil
                     :accessor widget-background-color)
   (content-alignment :initarg :alignment
                      :initform :top-left
                      :accessor widget-content-alignment)
   (margin-left :initarg :margin-left
                :initform 0
                :accessor widget-margin-left)
   (margin-right :initarg :margin-right
                 :initform 0
                 :accessor widget-margin-right)
   (margin-top :initarg :margin-top
               :initform 0
               :accessor widget-margin-top)
   (margin-bottom :initarg :margin-bottom
                  :initform 0
                  :accessor widget-margin-bottom)))

(defgeneric measure (widget))
(defgeneric layout (widget rect))
(defgeneric render (widget backend-window))

(defun measure-min-width (widget)
  (size-request-min-width (measure widget)))

(defun measure-min-height (widget)
  (size-request-min-height (measure widget)))

(defun measure-expand-x (widget)
  (size-request-expand-x (measure widget)))

(defun measure-expand-y (widget)
  (size-request-expand-y (measure widget)))

(defun %non-negative-int (value)
  (max 0 (truncate value)))

(defun %widget-margin-values (widget)
  (values (%non-negative-int (widget-margin-left widget))
          (%non-negative-int (widget-margin-right widget))
          (%non-negative-int (widget-margin-top widget))
          (%non-negative-int (widget-margin-bottom widget))))

(defun %apply-widget-margins-to-size-request (widget request)
  (multiple-value-bind (left right top bottom)
      (%widget-margin-values widget)
    (make-size-request
     :min-width (+ left right (size-request-min-width request))
     :min-height (+ top bottom (size-request-min-height request))
     :expand-x (size-request-expand-x request)
     :expand-y (size-request-expand-y request))))

(defun %apply-widget-margins-to-rect (widget rect)
  (multiple-value-bind (left right top bottom)
      (%widget-margin-values widget)
    (%compute-inner-rect rect left right top bottom)))

(defun %widget-consumed-rect (widget)
  (multiple-value-bind (left right top bottom)
      (%widget-margin-values widget)
    (let ((inner (widget-layout-rect widget)))
      (make-rect :x (- (rect-x inner) left)
                 :y (- (rect-y inner) top)
                 :width (+ (rect-width inner) left right)
                 :height (+ (rect-height inner) top bottom)))))

(defun %render-widget-background (widget backend-window)
  (let ((background (widget-background-color widget)))
    (when background
      (%call-fill-rect backend-window
                       (%widget-consumed-rect widget)
                       background))))

(defmethod render :around ((widget widget) backend-window)
  (%render-widget-background widget backend-window)
  (call-next-method))

(defun %align-position (start available-size child-size align)
  (case align
    (:start start)
    (:center (+ start (floor (- available-size child-size) 2)))
    (:end (+ start (- available-size child-size)))
    (otherwise (error "Invalid alignment value ~S" align))))

(defun %alignment-x (alignment)
  (case alignment
    ((:top-left :left :bottom-left) :start)
    ((:center :top-center :bottom-center) :center)
    ((:top-right :right :bottom-right) :end)
    (otherwise (error "Invalid combined alignment value ~S" alignment))))

(defun %alignment-y (alignment)
  (case alignment
    ((:top-left :top :top-center :top-right) :start)
    ((:center :left :right) :center)
    ((:bottom-left :bottom :bottom-center :bottom-right) :end)
    (otherwise (error "Invalid combined alignment value ~S" alignment))))

(defun %spacing-total (count spacing)
  (if (<= count 1)
      0
      (* (1- count) spacing)))

(defun %split-extra-space (extra count)
  (let ((result (make-array count :element-type 'integer :initial-element 0)))
    (if (<= count 0)
        result
        (let* ((base (floor extra count))
               (remainder (mod extra count)))
          (dotimes (i count)
            (setf (aref result i)
                  (+ base (if (< i remainder) 1 0))))
          result))))

(defun %compute-inner-rect (outer left right top bottom)
  (let* ((x (+ (rect-x outer) left))
         (y (+ (rect-y outer) top))
         (width (%non-negative-int (- (rect-width outer) left right)))
         (height (%non-negative-int (- (rect-height outer) top bottom))))
    (make-rect :x x :y y :width width :height height)))

(defun %call-fill-rect (backend-window rect color)
  (let* ((gfx-package (find-package :minerva.gfx))
         (fill-rect-symbol (and gfx-package (find-symbol "FILL-RECT" gfx-package)))
         (fill-rect-fn (and fill-rect-symbol (fboundp fill-rect-symbol) (symbol-function fill-rect-symbol))))
    (unless fill-rect-fn
      (error "minerva.gfx:fill-rect is unavailable. Load src/minerva/gfx/ffi.lisp and src/minerva/gfx/backend.lisp first."))
    (destructuring-bind (r g b a)
        (if (listp color)
            color
            (list (color-r color)
                  (color-g color)
                  (color-b color)
                  (color-a color)))
      (funcall fill-rect-fn
               backend-window
               rect
               (make-color :r r :g g :b b :a a)))))

(defun %gfx-function (name)
  (let* ((gfx-package (find-package :minerva.gfx))
         (symbol (and gfx-package (find-symbol name gfx-package))))
    (and symbol (fboundp symbol) (symbol-function symbol))))

(defun %call-draw-surface-rect (backend-window surface source-rect dest-x dest-y)
  (let ((draw-fn (%gfx-function "DRAW-SURFACE-RECT"))
        (make-pos-fn (%gfx-function "MAKE-POSITION")))
    (unless (and draw-fn make-pos-fn)
      (error "minerva.gfx surface draw functions are unavailable. Load src/minerva/gfx/ffi.lisp and src/minerva/gfx/backend.lisp first."))
    (funcall draw-fn
             backend-window
             surface
             source-rect
             (funcall make-pos-fn :x dest-x :y dest-y))))

(defun %call-draw-surface-rect-scaled (backend-window surface source-rect dest-rect)
  (let ((draw-fn (%gfx-function "DRAW-SURFACE-RECT-SCALED")))
    (unless draw-fn
      (error "minerva.gfx:draw-surface-rect-scaled is unavailable. Load src/minerva/gfx/ffi.lisp and src/minerva/gfx/backend.lisp first."))
    (funcall draw-fn backend-window surface source-rect dest-rect)))

(defun %surface-width (surface)
  (let ((fn (%gfx-function "SURFACE-WIDTH")))
    (cond
      ((null surface) 0)
      ((and (listp surface) (getf surface :width)) (max 0 (truncate (getf surface :width))))
      (fn (or (ignore-errors (funcall fn surface)) 0))
      (t 0))))

(defun %surface-height (surface)
  (let ((fn (%gfx-function "SURFACE-HEIGHT")))
    (cond
      ((null surface) 0)
      ((and (listp surface) (getf surface :height)) (max 0 (truncate (getf surface :height))))
      (fn (or (ignore-errors (funcall fn surface)) 0))
      (t 0))))
