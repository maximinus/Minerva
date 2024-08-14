(in-package :minerva/containers)


(defclass Box (minerva:Widget)
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
