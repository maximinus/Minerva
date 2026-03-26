(defpackage :minerva.common
  (:nicknames :minerva-common)
  (:use :cl)
  (:shadow :position)
  (:export
   :position
   :make-position
   :position-x
   :position-y
   :size
   :make-size
   :size-width
   :size-height
   :rect
   :make-rect
   :rect-x
   :rect-y
   :rect-width
   :rect-height
   :color
   :make-color
   :color-r
   :color-g
   :color-b
   :color-a))

(in-package :minerva.common)

(defstruct position
  (x 0 :type integer)
  (y 0 :type integer))

(defstruct size
  (width 0 :type integer)
  (height 0 :type integer))

(defstruct rect
  (x 0 :type integer)
  (y 0 :type integer)
  (width 0 :type integer)
  (height 0 :type integer))

(defstruct color
  (r 0 :type integer)
  (g 0 :type integer)
  (b 0 :type integer)
  (a 255 :type integer))
