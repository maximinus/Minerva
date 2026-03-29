(in-package :minerva.gui)

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
