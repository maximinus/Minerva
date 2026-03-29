(in-package :minerva.gui)

(defclass vbox (widget)
  ((children :initarg :children :accessor vbox-children :initform nil)
   (spacing :initarg :spacing :accessor vbox-spacing :initform 0)
  (align-x :initarg :align-x :accessor vbox-align-x :initform :start)
  (expand-x :initarg :expand-x :initform nil)
  (expand-y :initarg :expand-y :initform nil)))

(defmethod measure ((box vbox))
  (let* ((children (vbox-children box))
         (total-min-height 0)
         (max-min-width 0))
    (dolist (child children)
      (let ((req (measure child)))
        (incf total-min-height (size-request-min-height req))
        (setf max-min-width (max max-min-width (size-request-min-width req)))))
    (%apply-widget-margins-to-size-request
     box
     (make-size-request
      :min-width max-min-width
      :min-height (+ (%spacing-total (length children) (vbox-spacing box))
                     total-min-height)
      :expand-x (not (null (slot-value box 'expand-x)))
        :expand-y (not (null (slot-value box 'expand-y)))))))

(defmethod layout ((box vbox) rect)
  (setf (widget-layout-rect box) (%apply-widget-margins-to-rect box rect))
  (let* ((children (vbox-children box))
         (inner (widget-layout-rect box))
         (child-requests (mapcar #'measure children))
         (child-count (length children))
         (spacing-total (%spacing-total child-count (vbox-spacing box)))
         (total-min-height (reduce #'+ child-requests :key #'size-request-min-height :initial-value 0))
         (total-min-plus-spacing (+ total-min-height spacing-total))
         (leftover (max 0 (- (rect-height inner) total-min-plus-spacing)))
         (expand-indexes (loop for req in child-requests
                               for index from 0
                               when (size-request-expand-y req)
                               collect index))
         (extra-heights (%split-extra-space leftover (length expand-indexes)))
         (extra-map (make-array child-count :element-type 'integer :initial-element 0))
         (cursor-y (rect-y inner)))
    (loop for child-index in expand-indexes
          for extra-index from 0 do
          (setf (aref extra-map child-index) (aref extra-heights extra-index)))
    (loop for child in children
          for req in child-requests
          for idx from 0 do
          (let* ((child-height (+ (size-request-min-height req) (aref extra-map idx)))
                 (child-width (if (size-request-expand-x req)
                                  (rect-width inner)
                                  (size-request-min-width req)))
                 (child-x (if (size-request-expand-x req)
                              (rect-x inner)
                              (%align-position (rect-x inner)
                                               (rect-width inner)
                                               child-width
                                               (vbox-align-x box))))
                 (child-rect (make-rect :x child-x
                                        :y cursor-y
                                        :width child-width
                                        :height child-height)))
            (layout child child-rect)
            (incf cursor-y child-height)
            (when (< idx (1- child-count))
              (incf cursor-y (vbox-spacing box))))))
  box)

(defmethod render ((box vbox) backend-window)
  (dolist (child (vbox-children box))
    (render child backend-window))
  box)

(defmethod event-children ((box vbox))
  (vbox-children box))
