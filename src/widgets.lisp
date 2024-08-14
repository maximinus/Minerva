;; Simple widgets for the GUI
;; ColorRect is mainly used as a test widget

(in-package :minerva)

(defclass ColorRect (Widget)
  ((size :initarg :size :accessor size)
   (color :initarg :color :accessor color)))

(defmethod min-size ()
  size)

(defmethod draw ((self ColorRect) new-size)
  (setf (current-size self) new-size)
  (get-texture self new-size)
  (if (not (equal (background self) nil))
      (sdl2:fill-rect (texture self) nil (sdl2:map-rgb (sdl2:surface-format (texture self) (background self)))))
  (let ((draw-pos (get-align-offset self new-size)))
    (sdl2:render-draw-rect (texture self) (sdl2:make-rect (x draw-pos) (y draw-pos) (width size) (height size)))))
