(in-package :minerva.gui)

(defclass color-rect (widget)
  ((min-size :initarg :min-size :accessor color-rect-min-size :initform nil)
   (expand-x :initarg :expand-x :accessor color-rect-expand-x :initform nil)
   (expand-y :initarg :expand-y :accessor color-rect-expand-y :initform nil)
   (color :initarg :color :accessor color-rect-color :initform '(255 255 255 255))))

(defmethod initialize-instance :around ((rect-widget color-rect)
                                        &rest initargs
                                        &key min-size min-width min-height
                                        &allow-other-keys)
  (apply #'call-next-method rect-widget initargs)
  (let* ((base-size (%coerce-size min-size))
         (final-width (if (null min-width) (size-width base-size) min-width))
         (final-height (if (null min-height) (size-height base-size) min-height)))
    (setf (color-rect-min-size rect-widget)
          (make-size :width final-width
                     :height final-height))))

(defun color-rect-min-width (rect-widget)
  (size-width (color-rect-min-size rect-widget)))

(defun color-rect-min-height (rect-widget)
  (size-height (color-rect-min-size rect-widget)))

(defun (setf color-rect-min-width) (value rect-widget)
  (let ((min-size (color-rect-min-size rect-widget)))
    (setf (color-rect-min-size rect-widget)
          (make-size :width value
                     :height (size-height min-size)))
    value))

(defun (setf color-rect-min-height) (value rect-widget)
  (let ((min-size (color-rect-min-size rect-widget)))
    (setf (color-rect-min-size rect-widget)
          (make-size :width (size-width min-size)
                     :height value))
    value))

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
