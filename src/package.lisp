;; define the packages here

(defpackage :minerva
  (:use :cl)
  (:shadow :Position)
  (:export
   :Font :load-font :get-texture
   :horizontal-expandp :vertical-expandp
   :expand-horizontal :expand-vertical :expand-none :expand-both
   :align-left :align-right :align-top :align-bottom :align-center
   :Size :equal-size
   :Position
   :Widget
   :ColorRect
   :Box
   :wait-for-keypress :init-window))
