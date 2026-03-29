(in-package :minerva.gui)

(defclass window (widget)
  ((size :initarg :size :accessor window-size :initform nil)
   (child :initarg :child :accessor window-child :initform nil)))

(defmethod initialize-instance :around ((w window)
                                        &rest initargs
                                        &key size width height
                                        &allow-other-keys)
  (apply #'call-next-method w initargs)
  (let* ((base-size (%coerce-size size))
         (final-width (if (null width) (size-width base-size) width))
         (final-height (if (null height) (size-height base-size) height)))
    (setf (window-size w)
          (make-size :width final-width
                     :height final-height))))

(defun window-width (w)
  (size-width (window-size w)))

(defun window-height (w)
  (size-height (window-size w)))

(defun (setf window-width) (value w)
  (let ((size (window-size w)))
    (setf (window-size w)
          (make-size :width value
                     :height (size-height size)))
    value))

(defun (setf window-height) (value w)
  (let ((size (window-size w)))
    (setf (window-size w)
          (make-size :width (size-width size)
                     :height value))
    value))

(defmethod initialize-instance :after ((w window) &key)
  (unless (window-child w)
    (error "Window must have exactly one child.")))

(defmethod measure ((w window))
  (let ((child (window-child w)))
    (unless child
      (error "Window must have exactly one child."))
    (let ((child-request (measure child)))
      (%apply-widget-margins-to-size-request
       w
       (make-size-request
        :min-width (size-request-min-width child-request)
        :min-height (size-request-min-height child-request)
        :expand-x nil
        :expand-y nil)))))

(defmethod layout ((w window) rect)
  (declare (ignore rect))
  (let* ((outer-rect (make-rect :x 0
                                :y 0
                                :width (%non-negative-int (window-width w))
                                :height (%non-negative-int (window-height w))))
         (root-rect (%apply-widget-margins-to-rect w outer-rect)))
    (setf (widget-layout-rect w) root-rect))
  (let ((child (window-child w)))
    (unless child
      (error "Window must have exactly one child."))
    (let* ((request (measure child))
           (root-rect (widget-layout-rect w))
           (root-x (rect-x root-rect))
           (root-y (rect-y root-rect))
           (root-width (rect-width root-rect))
           (root-height (rect-height root-rect))
           (hbox-class (find-class 'hbox nil))
           (vbox-class (find-class 'vbox nil))
           (container-child-p (or (and hbox-class (typep child hbox-class))
                                  (and vbox-class (typep child vbox-class))))
           (container-fill-by-default-p (and container-child-p
                                             (eq (widget-content-alignment child) :top-left)))
           (child-width (if (or (size-request-expand-x request)
                                container-fill-by-default-p)
                            root-width
                            (size-request-min-width request)))
           (child-height (if (or (size-request-expand-y request)
                                 container-fill-by-default-p)
                             root-height
                             (size-request-min-height request)))
           (child-x (%align-position root-x
                                     root-width
                                     child-width
                                     (%alignment-x (widget-content-alignment child))))
           (child-y (%align-position root-y
                                     root-height
                                     child-height
                                     (%alignment-y (widget-content-alignment child)))))
      (layout child (make-rect :x child-x
                               :y child-y
                               :width child-width
                               :height child-height))))
  w)

(defmethod render ((w window) backend-window)
  (render (window-child w) backend-window)
  w)

(defmethod event-children ((w window))
  (let ((child (window-child w)))
    (if child (list child) nil)))

(defmethod handle-event ((w window) app-state event)
  (declare (ignore app-state))
  (let ((type (first event)))
    (case type
      (:window-resized
       (let ((new-width (or (getf (rest event) :width) (window-width w)))
             (new-height (or (getf (rest event) :height) (window-height w))))
         (setf (window-width w) new-width
               (window-height w) new-height)
         nil))
      (:quit
        '((:command :quit-app)))
      (otherwise nil))))
