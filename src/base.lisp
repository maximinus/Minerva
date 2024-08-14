(in-package :minerva)


(defconstant screen-width 640)
(defconstant screen-height 480)


(defclass Font ()
  ((sdl-font :initarg :font
	     :reader font)
   (color :initarg :color
	  :accessor color))
  (:default-initargs :color '(0 0 0 0)))

(defun load-font (font-name size)
  ;; given a path to a font, load it and return the font object
  ;; check the path exists
  (if (probe-file font-name)
      (progn
	(let ((loaded-font (sdl2-ttf:open-font font-name size)))
	  (make-instance 'Font :font loaded-font)))
      nil))

(defmethod get-texture ((font Font) text)
  (sdl2-ttf:render-text-blended (font font) text 0 0 0 0))

;; a widget can be set to expand or not, given the symbols
;; expand-none, expand-both, expand-vertical and expand-horizontal
;; don't forget that they are namespaced to the mv package
(defun horizontal-expandp (expand)
  (member expand '(:expand-horizontal :expand-both)))

(defun vertical-expandp (expand)
  (member expand '(:expand-vertical :expand-both)))


(defclass Size ()
  ((width :initarg width :accessor width)
   (height :initarg height :accessor height))
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
