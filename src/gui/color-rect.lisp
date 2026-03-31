(in-package :minerva.gui)

(defclass color-rect (widget)
  ((min-size :initarg :min-size :accessor color-rect-min-size :initform nil)
   (color :initarg :color :accessor color-rect-color :initform '(255 255 255 255))))

(defun color-rect-expand-x (rect-widget)
  (widget-expand-x rect-widget))

(defun color-rect-expand-y (rect-widget)
  (widget-expand-y rect-widget))

(defun (setf color-rect-expand-x) (value rect-widget)
  (setf (widget-expand-x rect-widget) value))

(defun (setf color-rect-expand-y) (value rect-widget)
  (setf (widget-expand-y rect-widget) value))

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
   (%widget-size-request rect-widget
                         (color-rect-min-width rect-widget)
                         (color-rect-min-height rect-widget))))

(defmethod layout ((rect-widget color-rect) rect)
  (setf (widget-layout-rect rect-widget) (%apply-widget-margins-to-rect rect-widget rect))
  rect-widget)

(defmethod render ((rect-widget color-rect) backend-window)
  (%call-fill-rect backend-window
                   (widget-layout-rect rect-widget)
                   (color-rect-color rect-widget))
  rect-widget)
