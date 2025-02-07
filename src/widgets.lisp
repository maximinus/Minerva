;; Simple widgets for the GUI
;; ColorRect is mainly used as a test widget

(in-package :minerva)

(defclass ColorRect (Widget)
    ((size :initarg :size :accessor size)
     (color :initarg :color :accessor color))
    (:default-initargs :size (make-size 0 0)))


(defmethod min-size ((self ColorRect))
  (size self))

(defmethod render ((self ColorRect) size offset screen)
  (if (not (equal (background self) nil))
    ;; fill in the background
    (format t "Drawing ColorRect")
    (format t "Drawing ColorRect no color")))

