(defpackage :minerva/containers
  (:use :cl)
  (:shadow :Position)
  (:export :horizontal-expandp
	   :vertical-expandp))

(in-package :minerva/containers)


(defun horizontal-expandp (expand)
  (member expand '(:expand-horizontal :expand-both)))

(defun vertical-expandp (expand)
  (member expand '(:expand-vertical :expand-both)))


(defclass Size ()
  ((width :initarg width
	  :accessor width)
   (height :initarg height
	   :accessor height))
  (:default-initargs :width 0 :height 0))

(defmethod equal-size ((size1 Size) (size2 Size))
  (and (equal (width size1) (width size2))
       (equal (height size1) (height size2))))


(defclass Position ()
  ((x :initarg x
      :accessor x)
   (y :initarg y
      :accessor y))
  (:default-initargs :x 0 :y 0))


(defclass Widget ()
  ((expand :initarg :expand :accessor expand)
   (align :initarg :align :accessor align)
   (parent :initarg :parent :accessor parent)
   (texture :initarg :texture :accessor texture)
   (background :initarg :background :accessor background)
   (size :initarg :size :accessor size)
   (offset :initarg :offset :accessor offset)
   (container :initarg :container :accessor container))
  (:default-initargs :background nil
		     :expand 'expand-none
		     :align 'align-top-left
		     :parent nil
		     :texture nil
		     :size nil
		     :offset nil
		     :container nil))

(defmethod render ((widget Widget) size offset)
  (if (not (equal-size size (size widget)))
      (progn
	(setf (offset widget) offset)
	(draw widget size))))

(defmethod draw ((widget Widget) size)
  (get-texture Widget size)
  (if (not (eq (background Widget) nil))
      (sdl2:fill-rect (texture widget) nil (background Widget)))
  (setf (size widget) size))

(defmethod get-texture ((widget Widget) size)
  ;depth is 24 but we should match the display surface really
  (setf (texture Widget) (sdl2:create-rgb-surface (width size) (height size) 24)))

(defmethod get-parent ((widget Widget))
  (if (not (eq (parent widget) nil))
      (get-parent (parent widget))))

(defmethod get-align-offset ((widget Widget) widget-size given-size)
  (let ((offset (make-instance 'Position :x 0 :y 0))
	(horizontal-space (- (width given-size) (width widget-size)))
	(vertical-space (- (height given-size) (height widget-size))))
    (if (> horizontal-space 0)
	(cond
	  ((eq (align widget) 'align-center)
	   (setf (x offset) (+ (x offset) (/ horizontal-space 2))))
	  ((eq (align widget) 'align-right)
	   (setf (x offset) (+ (x offset) horizontal-space)))))
    (if (> vertical-space 0)
	(cond
	  ((eq (align widget) 'align-center)
	   (setf (y offset) (+ (y offset) (/ vertical-space 2))))
	  ((eq (align widget) 'align-bottom)
	   (setf (y offset) (+ (y offset) vertical-space)))))))


(defclass Box (Widget)
  ((widgets :initarg :widgets :accessor widgets))
  (:default-initargs :widgets nil :container t))

(defmethod add-widget ((box Box) new-widget)
  ;nconc modifies the given list
  (setf (widgets box) (append (widgets box) (list new-widget))))

(defmethod expand-policy ((box Box))
  ;; expanding depends on wether the children do or not
  (let ((x-expand nil)
	(y-expand nil))
    (loop for widget in (widgets box)
	  do (if (not (eq (expand box) 'expand-none))
		 (progn
		   (if (eq (expand box) 'expand-both)
		       (return-from expand-policy 'expand-both))
		   (if (eq (expand box) 'expand-horizontal)
		       (setf x-expand t))
		   (if (eq (expand box) 'expand-vertical)
		       (setf y-expand t))))
	     (if (and x-expand y-expand)
		 (return-from expand-policy 'expand-both)))
    (if x-expand
	(return-from expand-policy 'expand-horizontal))
    (if y-expand
	(return-from expand-policy 'expand-vertical))
    'expand-none))
