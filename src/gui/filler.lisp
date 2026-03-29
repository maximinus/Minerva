(in-package :minerva.gui)

(defclass filler (widget)
  ((min-size :initarg :min-size :accessor filler-min-size :initform nil)
   (expand-x :initarg :expand-x :accessor filler-expand-x :initform t)
   (expand-y :initarg :expand-y :accessor filler-expand-y :initform nil)))

(defmethod initialize-instance :around ((space filler)
                                        &rest initargs
                                        &key min-size min-width min-height
                                        &allow-other-keys)
  (apply #'call-next-method space initargs)
  (let* ((base-size (%coerce-size min-size))
         (final-width (if (null min-width) (size-width base-size) min-width))
         (final-height (if (null min-height) (size-height base-size) min-height)))
    (setf (filler-min-size space)
          (make-size :width final-width
                     :height final-height))))

(defun filler-min-width (space)
  (size-width (filler-min-size space)))

(defun filler-min-height (space)
  (size-height (filler-min-size space)))

(defun (setf filler-min-width) (value space)
  (let ((min-size (filler-min-size space)))
    (setf (filler-min-size space)
          (make-size :width value
                     :height (size-height min-size)))
    value))

(defun (setf filler-min-height) (value space)
  (let ((min-size (filler-min-size space)))
    (setf (filler-min-size space)
          (make-size :width (size-width min-size)
                     :height value))
    value))

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
