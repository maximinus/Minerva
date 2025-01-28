(in-package :minerva)


;; in addition to the base widgets, containers have the following additional properties
;; widgets:     the widgets held by the container

;; and the following methods
;; add-widget:  adds the widget to the container and sets its parent


(defclass Box (Widget)
  ;; box will display the first widget in it's widgets only
  ((widgets :initarg :widgets :accessor widgets))
  (:default-initargs :widgets nil :container t))

(defmethod min-size ((self Box))
  (if (equal (widgets self) nil)
      (make-instance 'Size :width 0 :height 0)
      (min-size (first (widgets self)))))

(defmethod add-widget ((self Box) new-widget)
  (setf (parent new-widget) self)
  (setf (widgets self) (append (widgets self) (list new-widget))))

(defmethod render ((self Box) size offset screen)
  ;; children are drawn on top of each other
  (if (not (equal (background self) nil))
      (format t "Drawing background"))
  (loop for widget in (widgets self) do
    (render widget size (make-position 0 0) screen)))

(defmethod expand-policy ((self Box))
  ;; expanding depends on wether the children do or not
  (let ((x-expand nil)
	(y-expand nil))
    (loop for widget in (widgets self)
	  do (if (not (eq (expand self) 'expand-none))
		 (progn
		   (if (eq (expand self) 'expand-both)
		       (return-from expand-policy 'expand-both))
		   (if (eq (expand self) 'expand-horizontal)
		       (setf x-expand t))
		   (if (eq (expand self) 'expand-vertical)
		       (setf y-expand t))))
	     (if (and x-expand y-expand)
		 (return-from expand-policy 'expand-both)))
    (if x-expand
	(return-from expand-policy 'expand-horizontal))
    (if y-expand
	(return-from expand-policy 'expand-vertical))
    'expand-none))


(defclass Margin (Box)
  ((margins :initarg :margins :accessor margins))
    (:default-initargs margins (make-margin 0 0 0 0)))

(defun make-margin (margins &rest initargs)
  (let ((new-margin (apply 'make-instance 'Margin initargs)))
    (setf (margin new-margin) margins)))

(defmethod min-size ((self Margin))
  (let ((render-size (make-size 0 0)))
    (loop for widget in (widgets self) do
      (let ((widget-size (min-size widget)))
	(setf (width render-size) (max (width render-size) (width widget-size)))
	(setf (height render-size) (max (height render-size) (height widget-size)))))
    (incf (width render-size) (+ (left self) (right self)))
    (incf (height render-size) (+ (top self) (bottom self)))
    render-size))

(defmethod render ((self Margin) size offset screen)
  (get-texture self size)
  (if (not (equal (background self) nil))
      (format t "Filling color"))
  (decf (width size) (+ (left self) (right self)))
  (decf (height size) (+ (top self) (bottom self)))
  (let ((offset-position (make-position (left self) (top self))))
    (loop for widget in (widgets self) do
      (render widget size offset-position)
      (format t "Rendering"))))

(defclass HBox (Box) ())

(defmethod min-size ((self HBox))
  (let ((base-size (make-size 0 0)))
    (loop for widget in (widgets self) do
      (let ((widget-size (min-size widget)))
	(incf (width base-size) (width widget-size))
	(setf (height base-size) (max (height base-size) (height widget-size)))))
    base-size))

(defmethod calculate-size ((self HBox) available-size)
  (let ((fixed-width 0)
	(expandable-count 0)
	(remaining-width 0)
	(expand-width 0)
	(extra-width 0)
	(final-widths nil)
	(height 0))
    (loop for widget in (widgets self) do
      (if (horizontal-expandp (expand widget))
	  (incf expandable-count 1))
      (incf fixed-width (width (min-size widget))))
    (setf remaining-width (- (width available-size) fixed-width))
    (setf remaining-width (max 0 remaining-width))
    (if (> expandable-count 0)
	(progn
	  (setf expand-width (floor remaining-width expandable-count))
	  (setf extra-width (mod remaining-width expandable-count))))
    ;; note that the height for each widget should be the same as the highest widget, else the widget cannot center
    (if (not (equal (widgets self) nil))
	(setf height (apply #'max (mapcar (lambda (x) (height (min-size x))) (widgets self)))))
    (loop for widget in (widgets self) do
      (if (vertical-expandp (expand widget))
	    (setf height (height available-size)))
      (if (vertical-expandp (expand widget))
   	  (progn
	    ;; distribute the remaining width to ensure total width matches
	    (if (> extra-width 0)
		(progn
		  (nconc final-widths (list (make-instance 'Size :width (+ (width (min-size widget)) expand-width 1) :height height)))
		  (decf extra-width))
		(nconc final-widths (list (make-instance 'Size :width (+ (width (min-size widget)) expand-width :height height))))))
	  (nconc final-widths (list (make-instance 'Size :width (width (min-size)) :height height)))))
    final-widths))

(defmethod render ((self HBox) size offset screen)
  (if (not (equal (background self) nil))
      (format t "Render background"))
  (if (not equal (widgets self) nil)
      (let* ((all-sizes (calculate-size self))
	     (max-height (apply #'max (mapcar (lambda (x) (height (min-size x)) all-sizes))))
	     (total-area (make-instance 'Size :width (loop for i in (widgets self) sum (width i)) :height height))
	     (xpos 0)
	     (ypos 0)
	     (widget-offset (frame-offset self))
	     (offset (get-align-offset self total-area new-size)))
	(incf xpos (x widget-offset))
	(incf ypos (y widget-offset))
	(loop for widget in (widgets self)
	      for widget-size in all-sizes do
		(setf (height widget-size) max-height)
		(render widget (make-instance 'Position :x (x offset) :y (y offset)))
		;; blit the texture onto our texture
		(format t "Blitting texture")
		(incf xpos (width widget-size))
		(incf (x offset) (width widget-size))))))


(defclass Frame (Widget)
  ((frame-position :initarg :frame-position :accessor frame-position)
   (modal :initarg :modal :accessor modal)
   (widgets :initarg :widgets :accessor widgets))
  (:default-initargs :widgets nil :modal nil :container t))

;; frames are like a single box, however they never expand and have a fixed size
;; so current-size is always fixed
;; they may have >1 widget, extra widgets are drawn on top of the others

(defun make-frame (size pos widgets &rest initargs)
  ;; widgets must be a list
  (let ((new-frame (apply 'make-instance 'Frame initargs)))
    (setf (current-size new-frame) size)
    (setf (frame-position new-frame) pos)
    (setf (widgets new-frame) widgets)
    (get-texture new-frame size)
    new-frame))

(defmethod render-frame ((self Frame))
  ;; render relies on a size being given, so we use a different function here
  (loop for widget in (widgets self) do
    (render widget (current-size self) (make-pos 0 0))
    ;; render the texture onto our texture
    (format t "Blitting frame")))

