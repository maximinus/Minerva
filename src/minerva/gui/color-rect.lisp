(in-package :minerva.gui)

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
