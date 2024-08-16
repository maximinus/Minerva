(in-package :minerva)


(defconstant screen-width 640)
(defconstant screen-height 480)


(defclass Font ()
  ((sdl-font :initarg :sdl-font
	     :reader sdl-font)
   (color :initarg :color
	  :accessor color))
  (:default-initargs :color '(0 0 0 0)))

(defun load-font (font-name size)
  ;; given a path to a font, load it and return the font object
  ;; check the path exists
  (if (probe-file font-name)
      (progn
	(let ((loaded-font (sdl2-ttf:open-font font-name size)))
	  (make-instance 'Font :sdl-font loaded-font)))
      nil))

(defmethod get-texture ((self Font) text)
  (sdl2-ttf:render-text-blended (sdl-font self) text 0 0 0 0))


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


(defclass Margin ()
  ((left :initarg :left :accessor left)
   (right :initarg :right :accessor right)
   (top :initarg :top :accessor top)
   (bottom :initarg :bottom :accessor bottom))
  (:default-initargs :left 0 :right 0 :top 0 :bottom 0))

(defun make-margin (left right top bottom)
  (make-instance 'Margin :left left :right right :top top :bottom bottom))


(defclass Position ()
  ((x :initarg :x
      :accessor x)
   (y :initarg :y
      :accessor y))
  (:default-initargs :x 0 :y 0))

(defun make-pos (x y)
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


(defclass Widget ()
  ((expand :initarg :expand :accessor expand)
   (align :initarg :align :accessor align)
   (parent :initarg :parent :accessor parent)
   (texture :initarg :texture :accessor texture)
   (background :initarg :background :accessor background)
   (current-size :initarg :current-size :accessor current-size)
   (offset :initarg :offset :accessor offset)
   (container :initarg :container :accessor container))
  (:default-initargs :background nil
		     :expand 'expand-none
		     :align 'align-top-left
		     :parent nil
		     :texture nil
		     :current-size (make-size 0 0)
		     :offset nil
		     :container nil))

;; Every widget has the following properties
;; align:        how to align when the space allocated is bigger than the widget
;; expand:       if the widget is allowed to expand or not, and in what direction
;;               some widgets may ignore this value
;; parent:       the parent widget, or nil if there is no parent
;; texture:      an SDL texture which the widget is rendered to
;; background:   a background color which is blitted onto the texture before widget rendering
;; current-size: the size of the last render of the widget
;; offset:       the offset of this widget compared to its parent
;; container:    t if the widget holds other widgets

;; Every widget has the following methods:
;; min-size:     returns a Size stating the smalledt possible space in which a widget can be rendered
;; render:       draws the widget on to it's own texture, which is set to the size given
;;               this is also passed an offset value which is the widgets offset to the parent
;; draw:         draws the widget onto it's texture
;; get-texture:  makes a new texure of the required size and format
;; get-parent:   returns the parent widget or nil
;; get-align-offset:
;;               returns the offset position when the texture is larger than the widget

(defmethod min-size ((self Widget))
  ;; on a raw widget, this is always (0, 0)
  (make-instance 'Size :width 0 :height 0))

(defmethod render ((self Widget) size offset)
  (if (not (equal-size size (current-size self)))
      (progn
	(setf (offset self) offset)
	(setf (current-size self) size)
	(draw self size))))

(defmethod draw ((self Widget) size)
  (get-texture self size)
  (if (not (eq (background self) nil))
      (sdl2:fill-rect (texture self) nil (background self)))
  (setf (current-size self) size))

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

