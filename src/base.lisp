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
  (member expand '(expand-horizontal expand-both)))

(defun vertical-expandp (expand)
  (member expand '(expand-vertical expand-both)))


(defclass Size ()
  ((width :initarg :width :accessor width)
   (height :initarg :height :accessor height))
  (:default-initargs :width 0 :height 0))

(defmethod equal-size ((size1 Size) (size2 Size))
  (and (equal (width size1) (width size2))
       (equal (height size1) (height size2))))


(defclass Position ()
  ((x :initarg :x
      :accessor x)
   (y :initarg :y
      :accessor y))
  (:default-initargs :x 0 :y 0))

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


(defclass Widget ()
  ((expand :initarg :expand :accessor expand)
   (align :initarg :align :accessor align)
   (parent :initarg :parent :accessor parent)
   (texture :initarg :texture :accessor texture)
   (background :initarg :background :accessor background)
   (current-size :initarg :size :accessor size)
   (offset :initarg :offset :accessor offset)
   (container :initarg :container :accessor container)
   (frame-offset :initarg frame-offset :accessor frame-offset))
  (:default-initargs :background nil
		     :expand 'expand-none
		     :align 'align-top-left
		     :parent nil
		     :texture nil
		     :current_size nil
		     :offset nil
		     :container nil))

(defmethod min-size ((self Widget))
  ;; on a raw widget, this is always (0, 0)
  (make-instance 'Size :width 0 :height 0))

(defmethod render ((self Widget) size offset)
  (if (not (equal-size size (current-size self)))
      (progn
	(setf (offset self) offset)
	(draw self size))))

(defmethod draw ((self Widget) size)
  (get-texture self size)
  (if (not (eq (background self) nil))
      (sdl2:fill-rect (texture self) nil (background Widget)))
  (setf (size widget) size))

(defmethod get-texture ((self Widget) size)
  ;depth is 24 but we should match the display surface really
  (setf (texture self) (sdl2:create-rgb-surface (width size) (height size) 24)))

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
