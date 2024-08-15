(in-package :minerva)


(defclass Box (Widget)
  ;; box will display the first widget in it's widgets only
  ((widgets :initarg :widgets :accessor widgets))
  (:default-initargs :widgets nil :container t))

(defmethod min-size ((self Box))
  (if (equal (widgets self) nil)
      (make-instance 'Size :x 0 :y 0)
      (min-size (first (widgets self)))))

(defmethod add-widget ((self Box) new-widget)
  ;nconc modifies the given list
  (setf (widgets self) (append (widgets self) (list new-widget))))

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


(defclass HBox (Box) ())

(defmethod min-size ((self HBox))
  (let ((base-size (make-instance Size :width 0 :height 0)))
    (loop for widget in (widgets self) do
      (incf (width base-size) (width widget))
      (setf (height base-size) (max (height base-size) (height widget))))
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

(defmethod draw ((self HBox) new-size)
  (get-texture new-size)
  (if (not (equal (background self) nil))
      (sdl2:fill-rect (texture self) nil (sdl2:map-rgb (sdl2:surface-format (texture self) (background self)))))
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
		(sdl2:blit-surface (texture widget) nil (texture self) (sdl2:make-rect xpos ypos (width widget-size) (height widget-size)))
		(incf xpos (width widget-size))
		(incf (x offset) (width widget-size))))))
