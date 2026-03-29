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
    :margins
    :make-margins
    :margins-left
    :margins-right
    :margins-top
    :margins-bottom
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
  :widget-margins
  :widget-background-color
  :widget-content-alignment
  :widget-margin-left
  :widget-margin-right
  :widget-margin-top
  :widget-margin-bottom
   :measure
   :layout
   :render
  :handle-event
  :event-children
   :window
  :window-size
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
  :color-rect-min-size
   :color-rect-min-width
   :color-rect-min-height
   :color-rect-expand-x
   :color-rect-expand-y
   :color-rect-color
   :filler
  :filler-min-size
   :filler-min-width
   :filler-min-height
   :filler-expand-x
   :filler-expand-y
  :image
  :image-surface
  :image-draw-rect
  :label
  :label-text
  :label-font-name
  :label-text-size
  :label-color
  :label-surface
  :label-draw-rect
  :button
  :button-text
  :button-font-name
  :button-text-size
  :button-color
  :button-padding-x
  :button-padding-y
  :button-command
  :button-state
  :button-normal-surface
  :button-highlighted-surface
  :button-pressed-surface
  :button-text-surface
  :button-text-draw-rect
  :nine-patch
  :nine-patch-surface
  :nine-patch-border-left
  :nine-patch-border-right
  :nine-patch-border-top
  :nine-patch-border-bottom
  :nine-patch-child
  :nine-patch-content-rect
  :menu-nine-patch
  :menu-nine-patch-border-size
  :menu-nine-patch-border-left
  :menu-nine-patch-border-right
  :menu-nine-patch-border-top
  :menu-nine-patch-border-bottom
  :default-image-paths
  :menu-item
  :menu-item-id
  :menu-item-text
  :menu-item-command
  :menu-item-icon
  :menu-item-key-text
  :menu-item-highlighted-color
  :menu-item-state
  :menu-item-icon-surface
  :menu-item-label-surface
  :menu-item-key-surface
  :menu-item-icon-column-width
  :menu-item-label-column-width
  :menu-item-key-column-width
  :menu-item-icon-draw-rect
  :menu-item-label-draw-rect
  :menu-item-key-draw-rect
  :menu-spacer
  :menu-spacer-line-color
  :menu-spacer-top-spacing
  :menu-spacer-bottom-spacing
  :menu-spacer-line-thickness
  :menu-spacer-inset-x
  :menu
  :menu-entries
  :menu-children
  :menu-panel-surface
  :menu-border-left
  :menu-border-right
  :menu-border-top
  :menu-border-bottom
  :menu-icon-column-width
  :menu-label-column-width
  :menu-key-column-width
  :make-menu
   :measure-min-width
   :measure-min-height
   :measure-expand-x
   :measure-expand-y))

(in-package :minerva.gui)

(defstruct (margins
            (:constructor %make-margins (&key (left 0) (right 0) (top 0) (bottom 0))))
  (left 0 :type integer)
  (right 0 :type integer)
  (top 0 :type integer)
  (bottom 0 :type integer))

(defun make-margins (&rest args)
  (cond
    ((null args)
     (%make-margins))
    ((and (= (length args) 1)
          (numberp (first args)))
     (let ((value (%non-negative-int (first args))))
       (%make-margins :left value :right value :top value :bottom value)))
    (t
     (%make-margins :left (%non-negative-int (getf args :margin-left 0))
                    :right (%non-negative-int (getf args :margin-right 0))
                    :top (%non-negative-int (getf args :margin-top 0))
                    :bottom (%non-negative-int (getf args :margin-bottom 0))))))

(defstruct size-request
  (min-width 0 :type integer)
  (min-height 0 :type integer)
  (expand-x nil :type boolean)
  (expand-y nil :type boolean))

(defclass widget ()
  ((layout-rect :initform (make-rect)
                :accessor widget-layout-rect)
   (margins :initarg :margins
            :initform nil
            :accessor widget-margins)
   (background-color :initarg :background-color
                     :initform nil
                     :accessor widget-background-color)
   (content-alignment :initarg :alignment
                      :initform :top-left
                      :accessor widget-content-alignment)))

(defun %coerce-margins (value)
  (cond
    ((null value) (make-margins))
    ((typep value 'margins) value)
    ((numberp value) (make-margins value))
    (t (error "Invalid margins value ~S. Expected NIL, integer, or MARGINS." value))))

(defun %coerce-size (value)
  (cond
    ((null value) (make-size :width 0 :height 0))
    ((typep value 'minerva.common:size) value)
    ((numberp value)
     (let ((dimension (%non-negative-int value)))
       (make-size :width dimension :height dimension)))
    (t (error "Invalid size value ~S. Expected NIL, integer, or SIZE." value))))

(defmethod initialize-instance :around ((widget widget)
               &rest initargs
               &key margins margin-left margin-right margin-top margin-bottom
               &allow-other-keys)
  (apply #'call-next-method widget initargs)
  (let* ((base (%coerce-margins margins))
    (left (if (null margin-left) (margins-left base) margin-left))
    (right (if (null margin-right) (margins-right base) margin-right))
    (top (if (null margin-top) (margins-top base) margin-top))
    (bottom (if (null margin-bottom) (margins-bottom base) margin-bottom)))
    (setf (widget-margins widget)
          (make-margins :margin-left left
                        :margin-right right
                        :margin-top top
                        :margin-bottom bottom))))

(defun widget-margin-left (widget)
  (margins-left (widget-margins widget)))

(defun widget-margin-right (widget)
  (margins-right (widget-margins widget)))

(defun widget-margin-top (widget)
  (margins-top (widget-margins widget)))

(defun widget-margin-bottom (widget)
  (margins-bottom (widget-margins widget)))

(defun (setf widget-margin-left) (value widget)
  (let ((margins (widget-margins widget)))
    (setf (widget-margins widget)
          (make-margins :margin-left value
                        :margin-right (margins-right margins)
                        :margin-top (margins-top margins)
                        :margin-bottom (margins-bottom margins)))
    value))

(defun (setf widget-margin-right) (value widget)
  (let ((margins (widget-margins widget)))
    (setf (widget-margins widget)
          (make-margins :margin-left (margins-left margins)
                        :margin-right value
                        :margin-top (margins-top margins)
                        :margin-bottom (margins-bottom margins)))
    value))

(defun (setf widget-margin-top) (value widget)
  (let ((margins (widget-margins widget)))
    (setf (widget-margins widget)
          (make-margins :margin-left (margins-left margins)
                        :margin-right (margins-right margins)
                        :margin-top value
                        :margin-bottom (margins-bottom margins)))
    value))

(defun (setf widget-margin-bottom) (value widget)
  (let ((margins (widget-margins widget)))
    (setf (widget-margins widget)
          (make-margins :margin-left (margins-left margins)
                        :margin-right (margins-right margins)
                        :margin-top (margins-top margins)
                        :margin-bottom value))
    value))

(defgeneric measure (widget))
(defgeneric layout (widget rect))
(defgeneric render (widget backend-window))
(defgeneric handle-event (widget app-state event))
(defgeneric event-children (widget))

(defmethod handle-event ((widget widget) app-state event)
  (declare (ignore app-state event))
  nil)

(defmethod event-children ((widget widget))
  nil)

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
