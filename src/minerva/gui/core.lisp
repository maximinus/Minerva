(defpackage :minerva.gui
  (:nicknames :minerva-gui)
  (:use :cl)
  (:import-from :minerva.common
                :rect
                :make-rect
                :rect-x
                :rect-y
                :rect-width
                :rect-height)
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
   :hbox-padding-left
   :hbox-padding-right
   :hbox-padding-top
   :hbox-padding-bottom
   :hbox-spacing
   :hbox-align-y
   :vbox
   :vbox-children
   :vbox-padding-left
   :vbox-padding-right
   :vbox-padding-top
   :vbox-padding-bottom
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
    (destructuring-bind (r g b a) color
      (funcall fill-rect-fn
               backend-window
               (rect-x rect)
               (rect-y rect)
               (rect-width rect)
               (rect-height rect)
               r g b a))))

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

(defclass window (widget)
  ((width :initarg :width :accessor window-width :initform 0)
   (height :initarg :height :accessor window-height :initform 0)
   (child :initarg :child :accessor window-child :initform nil)))

(defmethod initialize-instance :after ((w window) &key)
  (unless (window-child w)
    (error "Window must have exactly one child.")))

(defmethod measure ((w window))
  (let ((child (window-child w)))
    (unless child
      (error "Window must have exactly one child."))
    (let ((child-request (measure child)))
      (%apply-widget-margins-to-size-request
       w
       (make-size-request
        :min-width (size-request-min-width child-request)
        :min-height (size-request-min-height child-request)
        :expand-x nil
        :expand-y nil)))))

(defmethod layout ((w window) rect)
  (declare (ignore rect))
  (let* ((outer-rect (make-rect :x 0
                                :y 0
                                :width (%non-negative-int (window-width w))
                                :height (%non-negative-int (window-height w))))
         (root-rect (%apply-widget-margins-to-rect w outer-rect)))
    (setf (widget-layout-rect w) root-rect))
  (let ((child (window-child w)))
    (unless child
      (error "Window must have exactly one child."))
    (let* ((request (measure child))
           (root-rect (widget-layout-rect w))
           (root-x (rect-x root-rect))
           (root-y (rect-y root-rect))
           (root-width (rect-width root-rect))
           (root-height (rect-height root-rect))
           (hbox-class (find-class 'hbox nil))
           (vbox-class (find-class 'vbox nil))
           (container-child-p (or (and hbox-class (typep child hbox-class))
                                  (and vbox-class (typep child vbox-class))))
           (container-fill-by-default-p (and container-child-p
                                             (eq (widget-content-alignment child) :top-left)))
           (child-width (if (or (size-request-expand-x request)
                               container-fill-by-default-p)
                            root-width
                            (size-request-min-width request)))
           (child-height (if (or (size-request-expand-y request)
                                container-fill-by-default-p)
                             root-height
                             (size-request-min-height request)))
           (child-x (%align-position root-x
                                     root-width
                                     child-width
                                     (%alignment-x (widget-content-alignment child))))
           (child-y (%align-position root-y
                                     root-height
                                     child-height
                                     (%alignment-y (widget-content-alignment child)))))
      (layout child (make-rect :x child-x
                               :y child-y
                               :width child-width
                               :height child-height))))
  w)

(defmethod render ((w window) backend-window)
  (render (window-child w) backend-window)
  w)

(defclass hbox (widget)
  ((children :initarg :children :accessor hbox-children :initform nil)
   (padding-left :initarg :padding-left :accessor hbox-padding-left :initform 0)
   (padding-right :initarg :padding-right :accessor hbox-padding-right :initform 0)
   (padding-top :initarg :padding-top :accessor hbox-padding-top :initform 0)
   (padding-bottom :initarg :padding-bottom :accessor hbox-padding-bottom :initform 0)
   (spacing :initarg :spacing :accessor hbox-spacing :initform 0)
   (align-y :initarg :align-y :accessor hbox-align-y :initform :start)))

(defmethod measure ((box hbox))
  (let* ((children (hbox-children box))
         (total-min-width 0)
         (max-min-height 0)
         (expand-x nil)
         (expand-y nil))
    (dolist (child children)
      (let ((req (measure child)))
        (incf total-min-width (size-request-min-width req))
        (setf max-min-height (max max-min-height (size-request-min-height req)))
        (setf expand-x (or expand-x (size-request-expand-x req)))
        (setf expand-y (or expand-y (size-request-expand-y req)))))
    (%apply-widget-margins-to-size-request
     box
     (make-size-request
      :min-width (+ (hbox-padding-left box)
                    (hbox-padding-right box)
                    (%spacing-total (length children) (hbox-spacing box))
                    total-min-width)
      :min-height (+ (hbox-padding-top box)
                     (hbox-padding-bottom box)
                     max-min-height)
      :expand-x expand-x
      :expand-y expand-y))))

(defmethod layout ((box hbox) rect)
  (setf (widget-layout-rect box) (%apply-widget-margins-to-rect box rect))
  (let* ((children (hbox-children box))
         (inner (%compute-inner-rect (widget-layout-rect box)
                                    (hbox-padding-left box)
                                    (hbox-padding-right box)
                                    (hbox-padding-top box)
                                    (hbox-padding-bottom box)))
         (child-requests (mapcar #'measure children))
         (child-count (length children))
         (spacing-total (%spacing-total child-count (hbox-spacing box)))
         (total-min-width (reduce #'+ child-requests :key #'size-request-min-width :initial-value 0))
         (total-min-plus-spacing (+ total-min-width spacing-total))
         (leftover (max 0 (- (rect-width inner) total-min-plus-spacing)))
         (expand-indexes (loop for req in child-requests
                               for index from 0
                               when (size-request-expand-x req)
                               collect index))
         (extra-widths (%split-extra-space leftover (length expand-indexes)))
         (extra-map (make-array child-count :element-type 'integer :initial-element 0))
         (cursor-x (rect-x inner)))
    (loop for child-index in expand-indexes
          for extra-index from 0 do
          (setf (aref extra-map child-index) (aref extra-widths extra-index)))
    (loop for child in children
          for req in child-requests
          for idx from 0 do
          (let* ((child-width (+ (size-request-min-width req) (aref extra-map idx)))
                 (child-height (if (size-request-expand-y req)
                                   (rect-height inner)
                                   (size-request-min-height req)))
                 (child-y (if (size-request-expand-y req)
                              (rect-y inner)
                              (%align-position (rect-y inner)
                                               (rect-height inner)
                                               child-height
                                               (hbox-align-y box))))
                 (child-rect (make-rect :x cursor-x
                                        :y child-y
                                        :width child-width
                                        :height child-height)))
            (layout child child-rect)
            (incf cursor-x child-width)
            (when (< idx (1- child-count))
              (incf cursor-x (hbox-spacing box))))))
  box)

(defmethod render ((box hbox) backend-window)
  (dolist (child (hbox-children box))
    (render child backend-window))
  box)

(defclass vbox (widget)
  ((children :initarg :children :accessor vbox-children :initform nil)
   (padding-left :initarg :padding-left :accessor vbox-padding-left :initform 0)
   (padding-right :initarg :padding-right :accessor vbox-padding-right :initform 0)
   (padding-top :initarg :padding-top :accessor vbox-padding-top :initform 0)
   (padding-bottom :initarg :padding-bottom :accessor vbox-padding-bottom :initform 0)
   (spacing :initarg :spacing :accessor vbox-spacing :initform 0)
   (align-x :initarg :align-x :accessor vbox-align-x :initform :start)))

(defmethod measure ((box vbox))
  (let* ((children (vbox-children box))
         (total-min-height 0)
         (max-min-width 0)
         (expand-x nil)
         (expand-y nil))
    (dolist (child children)
      (let ((req (measure child)))
        (incf total-min-height (size-request-min-height req))
        (setf max-min-width (max max-min-width (size-request-min-width req)))
        (setf expand-x (or expand-x (size-request-expand-x req)))
        (setf expand-y (or expand-y (size-request-expand-y req)))))
    (%apply-widget-margins-to-size-request
     box
     (make-size-request
      :min-width (+ (vbox-padding-left box)
                    (vbox-padding-right box)
                    max-min-width)
      :min-height (+ (vbox-padding-top box)
                     (vbox-padding-bottom box)
                     (%spacing-total (length children) (vbox-spacing box))
                     total-min-height)
      :expand-x expand-x
      :expand-y expand-y))))

(defmethod layout ((box vbox) rect)
  (setf (widget-layout-rect box) (%apply-widget-margins-to-rect box rect))
  (let* ((children (vbox-children box))
         (inner (%compute-inner-rect (widget-layout-rect box)
                                    (vbox-padding-left box)
                                    (vbox-padding-right box)
                                    (vbox-padding-top box)
                                    (vbox-padding-bottom box)))
         (child-requests (mapcar #'measure children))
         (child-count (length children))
         (spacing-total (%spacing-total child-count (vbox-spacing box)))
         (total-min-height (reduce #'+ child-requests :key #'size-request-min-height :initial-value 0))
         (total-min-plus-spacing (+ total-min-height spacing-total))
         (leftover (max 0 (- (rect-height inner) total-min-plus-spacing)))
         (expand-indexes (loop for req in child-requests
                               for index from 0
                               when (size-request-expand-y req)
                               collect index))
         (extra-heights (%split-extra-space leftover (length expand-indexes)))
         (extra-map (make-array child-count :element-type 'integer :initial-element 0))
         (cursor-y (rect-y inner)))
    (loop for child-index in expand-indexes
          for extra-index from 0 do
          (setf (aref extra-map child-index) (aref extra-heights extra-index)))
    (loop for child in children
          for req in child-requests
          for idx from 0 do
          (let* ((child-height (+ (size-request-min-height req) (aref extra-map idx)))
                 (child-width (if (size-request-expand-x req)
                                  (rect-width inner)
                                  (size-request-min-width req)))
                 (child-x (if (size-request-expand-x req)
                              (rect-x inner)
                              (%align-position (rect-x inner)
                                               (rect-width inner)
                                               child-width
                                               (vbox-align-x box))))
                 (child-rect (make-rect :x child-x
                                        :y cursor-y
                                        :width child-width
                                        :height child-height)))
            (layout child child-rect)
            (incf cursor-y child-height)
            (when (< idx (1- child-count))
              (incf cursor-y (vbox-spacing box))))))
  box)

(defmethod render ((box vbox) backend-window)
  (dolist (child (vbox-children box))
    (render child backend-window))
  box)

(defclass color-rect (widget)
  ((min-width :initarg :min-width :accessor color-rect-min-width :initform 0)
   (min-height :initarg :min-height :accessor color-rect-min-height :initform 0)
   (expand-x :initarg :expand-x :accessor color-rect-expand-x :initform nil)
   (expand-y :initarg :expand-y :accessor color-rect-expand-y :initform nil)
   (color :initarg :color :accessor color-rect-color :initform '(255 255 255 255))))

(defmethod measure ((rect-widget color-rect))
  (%apply-widget-margins-to-size-request
   rect-widget
   (make-size-request
    :min-width (%non-negative-int (color-rect-min-width rect-widget))
    :min-height (%non-negative-int (color-rect-min-height rect-widget))
    :expand-x (not (null (color-rect-expand-x rect-widget)))
    :expand-y (not (null (color-rect-expand-y rect-widget))))))

(defmethod layout ((rect-widget color-rect) rect)
  (setf (widget-layout-rect rect-widget) (%apply-widget-margins-to-rect rect-widget rect))
  rect-widget)

(defmethod render ((rect-widget color-rect) backend-window)
  (%call-fill-rect backend-window
                   (widget-layout-rect rect-widget)
                   (color-rect-color rect-widget))
  rect-widget)

(defclass filler (widget)
  ((min-width :initarg :min-width :accessor filler-min-width :initform 0)
   (min-height :initarg :min-height :accessor filler-min-height :initform 0)
   (expand-x :initarg :expand-x :accessor filler-expand-x :initform t)
   (expand-y :initarg :expand-y :accessor filler-expand-y :initform nil)))

(defmethod measure ((space filler))
  (%apply-widget-margins-to-size-request
   space
   (make-size-request
    :min-width (%non-negative-int (filler-min-width space))
    :min-height (%non-negative-int (filler-min-height space))
    :expand-x (not (null (filler-expand-x space)))
    :expand-y (not (null (filler-expand-y space))))))

(defmethod layout ((space filler) rect)
  (setf (widget-layout-rect space) (%apply-widget-margins-to-rect space rect))
  space)

(defmethod render ((space filler) backend-window)
  (declare (ignore backend-window))
  space)

(defclass image (widget)
  ((surface :initarg :surface :accessor image-surface :initform nil)
   (draw-rect :accessor image-draw-rect :initform (make-rect))))

(defun %image-placement (widget)
  (let* ((layout-rect (widget-layout-rect widget))
         (image-width (%surface-width (image-surface widget)))
         (image-height (%surface-height (image-surface widget)))
         (allocated-x (rect-x layout-rect))
         (allocated-y (rect-y layout-rect))
         (allocated-width (rect-width layout-rect))
         (allocated-height (rect-height layout-rect))
         (dest-x (%align-position allocated-x allocated-width image-width (%alignment-x (widget-content-alignment widget))))
         (dest-y (%align-position allocated-y allocated-height image-height (%alignment-y (widget-content-alignment widget))))
         (clip-left (max allocated-x dest-x))
         (clip-top (max allocated-y dest-y))
         (clip-right (min (+ allocated-x allocated-width) (+ dest-x image-width)))
         (clip-bottom (min (+ allocated-y allocated-height) (+ dest-y image-height)))
         (draw-width (max 0 (- clip-right clip-left)))
         (draw-height (max 0 (- clip-bottom clip-top))))
    (values (make-rect :x clip-left :y clip-top :width draw-width :height draw-height)
            (make-rect :x (max 0 (- clip-left dest-x))
                       :y (max 0 (- clip-top dest-y))
                       :width draw-width
                       :height draw-height))))

(defmethod measure ((img image))
  (%apply-widget-margins-to-size-request
   img
   (make-size-request
    :min-width (%surface-width (image-surface img))
    :min-height (%surface-height (image-surface img))
    :expand-x nil
    :expand-y nil)))

(defmethod layout ((img image) rect)
  (setf (widget-layout-rect img) (%apply-widget-margins-to-rect img rect))
  (multiple-value-bind (dest-rect source-rect)
      (%image-placement img)
    (declare (ignore source-rect))
    (setf (image-draw-rect img) dest-rect))
  img)

(defmethod render ((img image) backend-window)
  (let ((surface (image-surface img)))
    (when surface
      (multiple-value-bind (dest-rect source-rect)
          (%image-placement img)
        (setf (image-draw-rect img) dest-rect)
        (when (and (> (rect-width dest-rect) 0)
                   (> (rect-height dest-rect) 0))
          (%call-draw-surface-rect backend-window
                                   surface
                                   source-rect
                                   (rect-x dest-rect)
                                   (rect-y dest-rect))))))
  img)

(defclass nine-patch (widget)
  ((surface :initarg :surface :accessor nine-patch-surface :initform nil)
   (border-left :initarg :border-left :accessor nine-patch-border-left :initform 0)
   (border-right :initarg :border-right :accessor nine-patch-border-right :initform 0)
   (border-top :initarg :border-top :accessor nine-patch-border-top :initform 0)
   (border-bottom :initarg :border-bottom :accessor nine-patch-border-bottom :initform 0)
   (child :initarg :child :accessor nine-patch-child :initform nil)
   (content-rect :accessor nine-patch-content-rect :initform (make-rect))))

(defun %non-negative-border (value)
  (%non-negative-int value))

(defun %patch-segment (total start-size end-size)
  (let* ((start (min (%non-negative-int start-size) (%non-negative-int total)))
         (remaining (max 0 (- (%non-negative-int total) start)))
         (end (min (%non-negative-int end-size) remaining))
         (center (max 0 (- (%non-negative-int total) start end))))
    (values start center end)))

(defmethod measure ((panel nine-patch))
  (let* ((child (nine-patch-child panel))
         (child-request (if child (measure child) (make-size-request)))
         (left (%non-negative-border (nine-patch-border-left panel)))
         (right (%non-negative-border (nine-patch-border-right panel)))
         (top (%non-negative-border (nine-patch-border-top panel)))
         (bottom (%non-negative-border (nine-patch-border-bottom panel))))
    (%apply-widget-margins-to-size-request
     panel
     (make-size-request
      :min-width (+ left right (size-request-min-width child-request))
      :min-height (+ top bottom (size-request-min-height child-request))
      :expand-x (if child (size-request-expand-x child-request) nil)
      :expand-y (if child (size-request-expand-y child-request) nil)))))

(defmethod layout ((panel nine-patch) rect)
  (setf (widget-layout-rect panel) (%apply-widget-margins-to-rect panel rect))
  (let* ((left (%non-negative-border (nine-patch-border-left panel)))
         (right (%non-negative-border (nine-patch-border-right panel)))
         (top (%non-negative-border (nine-patch-border-top panel)))
         (bottom (%non-negative-border (nine-patch-border-bottom panel)))
         (content (%compute-inner-rect (widget-layout-rect panel) left right top bottom))
         (child (nine-patch-child panel)))
    (setf (nine-patch-content-rect panel) content)
    (when child
      (layout child content)))
  panel)

(defun %render-nine-patch-part (backend-window surface src-x src-y src-w src-h dst-x dst-y dst-w dst-h)
  (when (and (> src-w 0) (> src-h 0) (> dst-w 0) (> dst-h 0))
    (%call-draw-surface-rect-scaled
     backend-window
     surface
     (make-rect :x src-x :y src-y :width src-w :height src-h)
     (make-rect :x dst-x :y dst-y :width dst-w :height dst-h))))

(defmethod render ((panel nine-patch) backend-window)
  (let* ((surface (nine-patch-surface panel))
         (outer (widget-layout-rect panel))
         (child (nine-patch-child panel)))
    (when surface
      (let* ((src-width (%surface-width surface))
             (src-height (%surface-height surface))
             (dst-width (rect-width outer))
             (dst-height (rect-height outer))
             (src-x-segments (multiple-value-list
                              (%patch-segment src-width
                                              (%non-negative-border (nine-patch-border-left panel))
                                              (%non-negative-border (nine-patch-border-right panel)))))
             (src-y-segments (multiple-value-list
                              (%patch-segment src-height
                                              (%non-negative-border (nine-patch-border-top panel))
                                              (%non-negative-border (nine-patch-border-bottom panel)))))
             (dst-x-segments (multiple-value-list
                              (%patch-segment dst-width
                                              (%non-negative-border (nine-patch-border-left panel))
                                              (%non-negative-border (nine-patch-border-right panel)))))
             (dst-y-segments (multiple-value-list
                              (%patch-segment dst-height
                                              (%non-negative-border (nine-patch-border-top panel))
                                              (%non-negative-border (nine-patch-border-bottom panel))))))
        (destructuring-bind (src-left src-center src-right) src-x-segments
          (destructuring-bind (src-top src-middle src-bottom) src-y-segments
            (destructuring-bind (dst-left dst-center dst-right) dst-x-segments
              (destructuring-bind (dst-top dst-middle dst-bottom) dst-y-segments
                (let* ((sx0 0)
                       (sx1 src-left)
                       (sx2 (+ src-left src-center))
                       (sy0 0)
                       (sy1 src-top)
                       (sy2 (+ src-top src-middle))
                       (dx0 (rect-x outer))
                       (dx1 (+ (rect-x outer) dst-left))
                       (dx2 (+ (rect-x outer) dst-left dst-center))
                       (dy0 (rect-y outer))
                       (dy1 (+ (rect-y outer) dst-top))
                       (dy2 (+ (rect-y outer) dst-top dst-middle)))
                  (%render-nine-patch-part backend-window surface sx0 sy0 src-left src-top dx0 dy0 dst-left dst-top)
                  (%render-nine-patch-part backend-window surface sx1 sy0 src-center src-top dx1 dy0 dst-center dst-top)
                  (%render-nine-patch-part backend-window surface sx2 sy0 src-right src-top dx2 dy0 dst-right dst-top)
                  (%render-nine-patch-part backend-window surface sx0 sy1 src-left src-middle dx0 dy1 dst-left dst-middle)
                  (%render-nine-patch-part backend-window surface sx1 sy1 src-center src-middle dx1 dy1 dst-center dst-middle)
                  (%render-nine-patch-part backend-window surface sx2 sy1 src-right src-middle dx2 dy1 dst-right dst-middle)
                  (%render-nine-patch-part backend-window surface sx0 sy2 src-left src-bottom dx0 dy2 dst-left dst-bottom)
                  (%render-nine-patch-part backend-window surface sx1 sy2 src-center src-bottom dx1 dy2 dst-center dst-bottom)
                  (%render-nine-patch-part backend-window surface sx2 sy2 src-right src-bottom dx2 dy2 dst-right dst-bottom))))))))
    (when child
      (render child backend-window))
    panel))
