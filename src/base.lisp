(in-package :minerva)


(defconstant screen-width 640)
(defconstant screen-height 480)


;; a widget can be set to expand or not, given the symbols
;; expand-none, expand-both, expand-vertical and expand-horizontal
;; don't forget that they are namespaced to the mv package
(defun horizontal-expandp (expand)
  (member expand '(expand-horizontal expand-both)))

(defun vertical-expandp (expand)
  (member expand '(expand-vertical expand-both)))


(defclass Size ()
  ((width :initarg :width :accessor width)
   (height :initarg :height :accessor height))
  (:default-initargs :width 0 :height 0))

(defun make-size (w h)
  (make-instance 'Size :width w :height h))

(defmethod equal-size ((size1 Size) (size2 Size))
  (and (equal (width size1) (width size2))
       (equal (height size1) (height size2))))


(defclass Position ()
  ((x :initarg :x
      :accessor x)
   (y :initarg :y
      :accessor y))
  (:default-initargs :x 0 :y 0))

(defun make-position (x y)
  (make-instance 'Position :x x :y y))

(defmethod add ((a Position) &rest b)
  (let ((xpos (x a))
	(ypos (y a)))
    (dolist (pos b)
      (incf xpos (x pos))
      (incf ypos (y pos)))
    (make-instance 'Position :x xpos :y ypos)))

(defmethod sub ((a Position) &rest b)
  (let ((xpos (x a))
	(ypos (y a)))
    (dolist (pos b)
      (decf xpos (x pos))
      (decf ypos (y pos)))
    (make-instance 'Position :x xpos :y ypos)))


(defclass Align ()
  ((x :initarg :x :accessor x)
   (y :initarg :y :accessor y))
  (:default-initargs :x 'align-left :y 'align-top))



;; we just need to draw a widget
(defclass Widget ()
  ((expand :initarg :expand :accessor expand)
   (align :initarg :align :accessor align)
   (parent :initarg :parent :accessor parent)
   (container :initarg :container :accessor container))
  (:default-initargs :expand 'expand-none
		     :align 'align-top-left
		     :parent nil
		     :container nil))

(defmethod min-size ((self Widget))
  ;; on a raw widget, this is always (0, 0)
  (make-instance 'Size :width 0 :height 0))

(defmethod render ((self Widget) size offset screen)
  ;; size is the size of the area we need draw to
  ;; offset is the position to draw to
  ;; screen is where to draw to
  )

(defmethod get-parent ((self Widget))
  (if (not (eq (parent self) nil))
      (get-parent (parent self))))

(defmethod get-align-offset ((self Widget) widget-size given-size)
  (let ((offset (make-instance 'Position :x 0 :y 0))
	(horizontal-space (- (width given-size) (width widget-size)))
	(vertical-space (- (height given-size) (height widget-size))))
    (if (> horizontal-space 0)
	(cond
	  ((eq (align self) 'align-center)
	   (setf (x offset) (+ (x offset) (/ horizontal-space 2))))
	  ((eq (align self) 'align-right)
	   (setf (x offset) (+ (x offset) horizontal-space)))))
    (if (> vertical-space 0)
	(cond
	  ((eq (align self) 'align-center)
	   (setf (y offset) (+ (y offset) (/ vertical-space 2))))
	  ((eq (align self) 'align-bottom)
	   (setf (y offset) (+ (y offset) vertical-space)))))
    offset))
