(in-package :minerva.gui)

(defclass filler (widget)
  ((min-size :initarg :min-size :accessor filler-min-size :initform nil))
  (:default-initargs
   :expand-x t
   :expand-y nil))

(defun filler-expand-x (space)
  (widget-expand-x space))

(defun filler-expand-y (space)
  (widget-expand-y space))

(defun (setf filler-expand-x) (value space)
  (setf (widget-expand-x space) value))

(defun (setf filler-expand-y) (value space)
  (setf (widget-expand-y space) value))

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
   (%widget-size-request space
                         (filler-min-width space)
                         (filler-min-height space))))

(defmethod layout ((space filler) rect)
  (setf (widget-layout-rect space) (%apply-widget-margins-to-rect space rect))
  space)

(defmethod render ((space filler) backend-window)
  (declare (ignore backend-window))
  space)
