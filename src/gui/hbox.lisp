(in-package :minerva.gui)

(defclass hbox (widget)
  ((children :initarg :children :accessor hbox-children :initform nil)
   (spacing :initarg :spacing :accessor hbox-spacing :initform 0)
  (align-y :initarg :align-y :accessor hbox-align-y :initform :start)))

(defmethod measure ((box hbox))
  (let* ((children (hbox-children box))
         (total-min-width 0)
         (max-min-height 0))
    (dolist (child children)
      (let ((req (measure child)))
        (incf total-min-width (size-request-min-width req))
        (setf max-min-height (max max-min-height (size-request-min-height req)))))
    (%apply-widget-margins-to-size-request
     box
      (%widget-size-request box
                    (+ (%spacing-total (length children) (hbox-spacing box))
                      total-min-width)
                    max-min-height))))

(defmethod layout ((box hbox) rect)
  (setf (widget-layout-rect box) (%apply-widget-margins-to-rect box rect))
  (let* ((children (hbox-children box))
         (inner (widget-layout-rect box))
         (child-requests (mapcar #'measure children))
         (child-count (length children))
         (spacing-total (%spacing-total child-count (hbox-spacing box)))
         (total-min-width (reduce #'+ child-requests :key #'size-request-min-width :initial-value 0))
         (total-min-plus-spacing (+ total-min-width spacing-total))
         (leftover (max 0 (- (rect-width inner) total-min-plus-spacing)))
         (expand-indexes (loop for req in child-requests
                               for index from 0
                               when (size-request-expand-x req)
                               collect index))
         (extra-widths (%split-extra-space leftover (length expand-indexes)))
         (extra-map (make-array child-count :element-type 'integer :initial-element 0))
         (cursor-x (rect-x inner)))
    (loop for child-index in expand-indexes
          for extra-index from 0 do
          (setf (aref extra-map child-index) (aref extra-widths extra-index)))
    (loop for child in children
          for req in child-requests
          for idx from 0 do
          (let* ((child-width (+ (size-request-min-width req) (aref extra-map idx)))
                 (child-height (if (size-request-expand-y req)
                                   (rect-height inner)
                                   (size-request-min-height req)))
                 (child-y (if (size-request-expand-y req)
                              (rect-y inner)
                              (%align-position (rect-y inner)
                                               (rect-height inner)
                                               child-height
                                               (hbox-align-y box))))
                 (child-rect (make-rect :x cursor-x
                                        :y child-y
                                        :width child-width
                                        :height child-height)))
            (layout child child-rect)
            (incf cursor-x child-width)
            (when (< idx (1- child-count))
              (incf cursor-x (hbox-spacing box))))))
  box)

(defmethod render ((box hbox) backend-window)
  (dolist (child (hbox-children box))
    (render child backend-window))
  box)

(defmethod event-children ((box hbox))
  (hbox-children box))
