(in-package :minerva.gui)

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
