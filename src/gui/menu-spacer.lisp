(in-package :minerva.gui)

(defclass menu-spacer (widget)
  ((line-color :initarg :line-color :accessor menu-spacer-line-color :initform '(120 120 120 255))
   (top-spacing :initarg :top-spacing :accessor menu-spacer-top-spacing :initform 4)
   (bottom-spacing :initarg :bottom-spacing :accessor menu-spacer-bottom-spacing :initform 4)
   (line-thickness :initarg :line-thickness :accessor menu-spacer-line-thickness :initform 1)
   (inset-x :initarg :inset-x :accessor menu-spacer-inset-x :initform 6)))

(defmethod initialize-instance :after ((spacer menu-spacer) &key)
  (setf (menu-spacer-top-spacing spacer) (%non-negative-int (menu-spacer-top-spacing spacer))
        (menu-spacer-bottom-spacing spacer) (%non-negative-int (menu-spacer-bottom-spacing spacer))
        (menu-spacer-line-thickness spacer) (%non-negative-int (menu-spacer-line-thickness spacer))
        (menu-spacer-inset-x spacer) (%non-negative-int (menu-spacer-inset-x spacer))))

(defmethod measure ((spacer menu-spacer))
  (%apply-widget-margins-to-size-request
   spacer
  (%widget-size-request spacer
                 0
                 (+ (menu-spacer-top-spacing spacer)
                   (menu-spacer-line-thickness spacer)
                   (menu-spacer-bottom-spacing spacer))
                 :expand-x t
                 :expand-y nil)))

(defmethod layout ((spacer menu-spacer) rect)
  (setf (widget-layout-rect spacer) (%apply-widget-margins-to-rect spacer rect))
  spacer)

(defmethod render ((spacer menu-spacer) backend-window)
  (let* ((inner (widget-layout-rect spacer))
         (inset (menu-spacer-inset-x spacer))
         (line-y (+ (rect-y inner) (menu-spacer-top-spacing spacer)))
         (line-height (menu-spacer-line-thickness spacer))
         (line-x (+ (rect-x inner) inset))
         (line-width (max 0 (- (rect-width inner) (* 2 inset)))))
    (when (and (> line-width 0) (> line-height 0))
      (%call-fill-rect backend-window
                       (make-rect :x line-x
                                  :y line-y
                                  :width line-width
                                  :height line-height)
                       (menu-spacer-line-color spacer))))
  spacer)

(defmethod handle-event ((spacer menu-spacer) app-state event)
  (declare (ignore app-state event))
  nil)