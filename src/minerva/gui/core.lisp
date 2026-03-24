(defpackage :minerva.gui
  (:nicknames :minerva-gui)
  (:use :cl)
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
   :measure-min-width
   :measure-min-height
   :measure-expand-x
   :measure-expand-y))

(in-package :minerva.gui)

(defstruct rect
  (x 0 :type integer)
  (y 0 :type integer)
  (width 0 :type integer)
  (height 0 :type integer))

(defstruct size-request
  (min-width 0 :type integer)
  (min-height 0 :type integer)
  (expand-x nil :type boolean)
  (expand-y nil :type boolean))

(defclass widget ()
  ((layout-rect :initform (make-rect)
                :accessor widget-layout-rect)))

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

(defun %align-position (start available-size child-size align)
  (case align
    (:start start)
    (:center (+ start (floor (- available-size child-size) 2)))
    (:end (+ start (- available-size child-size)))
    (otherwise (error "Invalid alignment value ~S" align))))

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
      (make-size-request
       :min-width (size-request-min-width child-request)
       :min-height (size-request-min-height child-request)
       :expand-x nil
       :expand-y nil))))

(defmethod layout ((w window) rect)
  (declare (ignore rect))
  (let ((root-rect (make-rect :x 0
                              :y 0
                              :width (%non-negative-int (window-width w))
                              :height (%non-negative-int (window-height w)))))
    (setf (widget-layout-rect w) root-rect))
  (let ((child (window-child w)))
    (unless child
      (error "Window must have exactly one child."))
    (let* ((request (measure child))
           (root-width (%non-negative-int (window-width w)))
           (root-height (%non-negative-int (window-height w)))
           (container-child-p (or (typep child 'hbox)
                                  (typep child 'vbox)))
           (child-width (if (or container-child-p
                               (size-request-expand-x request))
                            root-width
                            (size-request-min-width request)))
           (child-height (if (or container-child-p
                                (size-request-expand-y request))
                             root-height
                             (size-request-min-height request))))
      (layout child (make-rect :x 0
                               :y 0
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
    (make-size-request
     :min-width (+ (hbox-padding-left box)
                   (hbox-padding-right box)
                   (%spacing-total (length children) (hbox-spacing box))
                   total-min-width)
     :min-height (+ (hbox-padding-top box)
                    (hbox-padding-bottom box)
                    max-min-height)
     :expand-x expand-x
     :expand-y expand-y)))

(defmethod layout ((box hbox) rect)
  (setf (widget-layout-rect box) rect)
  (let* ((children (hbox-children box))
         (inner (%compute-inner-rect rect
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
    (make-size-request
     :min-width (+ (vbox-padding-left box)
                   (vbox-padding-right box)
                   max-min-width)
     :min-height (+ (vbox-padding-top box)
                    (vbox-padding-bottom box)
                    (%spacing-total (length children) (vbox-spacing box))
                    total-min-height)
     :expand-x expand-x
     :expand-y expand-y)))

(defmethod layout ((box vbox) rect)
  (setf (widget-layout-rect box) rect)
  (let* ((children (vbox-children box))
         (inner (%compute-inner-rect rect
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
  (make-size-request
   :min-width (%non-negative-int (color-rect-min-width rect-widget))
   :min-height (%non-negative-int (color-rect-min-height rect-widget))
   :expand-x (not (null (color-rect-expand-x rect-widget)))
   :expand-y (not (null (color-rect-expand-y rect-widget)))))

(defmethod layout ((rect-widget color-rect) rect)
  (setf (widget-layout-rect rect-widget) rect)
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
  (make-size-request
   :min-width (%non-negative-int (filler-min-width space))
   :min-height (%non-negative-int (filler-min-height space))
   :expand-x (not (null (filler-expand-x space)))
   :expand-y (not (null (filler-expand-y space)))))

(defmethod layout ((space filler) rect)
  (setf (widget-layout-rect space) rect)
  space)

(defmethod render ((space filler) backend-window)
  (declare (ignore backend-window))
  space)
