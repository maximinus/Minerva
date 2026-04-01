(in-package :minerva.gui)

(defclass scroll-area-test-widget (widget)
  ((min-width :initarg :min-width :accessor scroll-area-test-min-width :initform 0)
   (min-height :initarg :min-height :accessor scroll-area-test-min-height :initform 0)
   (last-event :accessor scroll-area-test-last-event :initform nil)
   (render-clip :accessor scroll-area-test-render-clip :initform nil)))

(defmethod measure ((widget scroll-area-test-widget))
  (%widget-size-request widget
                        (scroll-area-test-min-width widget)
                        (scroll-area-test-min-height widget)
                        :expand-x nil
                        :expand-y nil))

(defmethod layout ((widget scroll-area-test-widget) rect)
  (setf (widget-layout-rect widget) rect)
  widget)

(defmethod render ((widget scroll-area-test-widget) backend-window)
  (declare (ignore backend-window))
  (setf (scroll-area-test-render-clip widget)
        (and *render-clip-rect* (%copy-rect *render-clip-rect*)))
  widget)

(defmethod handle-event ((widget scroll-area-test-widget) app-state event)
  (declare (ignore app-state))
  (setf (scroll-area-test-last-event widget) event)
  nil)

(defmacro %with-scroll-area-surface-stub (&body body)
  `(let ((old-load (symbol-function 'minerva.gui::%scroll-area-load-surface)))
     (unwind-protect
          (progn
            (setf (symbol-function 'minerva.gui::%scroll-area-load-surface)
                  (lambda (relative-path)
                    (declare (ignore relative-path))
                    '(:width 20 :height 20)))
            ,@body)
       (setf (symbol-function 'minerva.gui::%scroll-area-load-surface) old-load))))

(defun %center-point (rect)
  (list (+ (rect-x rect) (floor (rect-width rect) 2))
        (+ (rect-y rect) (floor (rect-height rect) 2))))

(%deftest test-scroll-area-no-bars-when-child-fits
  (%with-scroll-area-surface-stub
   (let* ((child (make-instance 'scroll-area-test-widget :min-width 120 :min-height 80))
          (area (make-instance 'scroll-area :child child)))
     (layout area (make-rect :x 0 :y 0 :width 200 :height 150))
     (%assert-equal (scroll-area-horizontal-visible-p area) nil "scroll-area hides horizontal bar when child fits")
     (%assert-equal (scroll-area-vertical-visible-p area) nil "scroll-area hides vertical bar when child fits"))))

(%deftest test-scroll-area-horizontal-bar-appears-when-child-too-wide
  (%with-scroll-area-surface-stub
   (let* ((child (make-instance 'scroll-area-test-widget :min-width 240 :min-height 80))
          (area (make-instance 'scroll-area :child child)))
     (layout area (make-rect :x 0 :y 0 :width 200 :height 150))
     (%assert-equal (scroll-area-horizontal-visible-p area) t "scroll-area shows horizontal bar when child is too wide")
     (%assert-equal (scroll-area-vertical-visible-p area) nil "scroll-area keeps vertical bar hidden when child height fits"))))

(%deftest test-scroll-area-vertical-bar-appears-when-child-too-tall
  (%with-scroll-area-surface-stub
   (let* ((child (make-instance 'scroll-area-test-widget :min-width 120 :min-height 260))
          (area (make-instance 'scroll-area :child child)))
     (layout area (make-rect :x 0 :y 0 :width 200 :height 150))
     (%assert-equal (scroll-area-horizontal-visible-p area) nil "scroll-area keeps horizontal bar hidden when child width fits")
     (%assert-equal (scroll-area-vertical-visible-p area) t "scroll-area shows vertical bar when child is too tall"))))

(%deftest test-scroll-area-both-bars-appear-when-both-axes-overflow
  (%with-scroll-area-surface-stub
   (let* ((child (make-instance 'scroll-area-test-widget :min-width 400 :min-height 300))
          (area (make-instance 'scroll-area :child child)))
     (layout area (make-rect :x 0 :y 0 :width 200 :height 150))
     (%assert-equal (scroll-area-horizontal-visible-p area) t "scroll-area shows horizontal bar when width overflows")
     (%assert-equal (scroll-area-vertical-visible-p area) t "scroll-area shows vertical bar when height overflows"))))

(%deftest test-scroll-area-showing-one-bar-can-force-the-other
  (%with-scroll-area-surface-stub
   (let* ((child (make-instance 'scroll-area-test-widget :min-width 210 :min-height 181))
          (area (make-instance 'scroll-area :child child)))
     (layout area (make-rect :x 0 :y 0 :width 200 :height 200))
     (%assert-equal (scroll-area-horizontal-visible-p area) t "horizontal bar appears for slight width overflow")
     (%assert-equal (scroll-area-vertical-visible-p area) t "vertical bar appears after horizontal bar reduces viewport"))))

(%deftest test-scroll-area-right-button-increases-scroll-x
  (%with-scroll-area-surface-stub
   (let* ((child (make-instance 'scroll-area-test-widget :min-width 400 :min-height 100))
          (area (make-instance 'scroll-area :child child)))
     (layout area (make-rect :x 0 :y 0 :width 200 :height 120))
     (destructuring-bind (x y) (%center-point (scroll-area-horizontal-right-button-rect area))
       (handle-event area nil (list :mouse-down :button :left :x x :y y)))
     (%assert-equal (scroll-area-scroll-x area) 20 "right button increases scroll-x by fixed step"))))

(%deftest test-scroll-area-left-button-decreases-scroll-x-with-clamp
  (%with-scroll-area-surface-stub
   (let* ((child (make-instance 'scroll-area-test-widget :min-width 400 :min-height 100))
          (area (make-instance 'scroll-area :child child :scroll-x 50)))
     (layout area (make-rect :x 0 :y 0 :width 200 :height 120))
     (destructuring-bind (x y) (%center-point (scroll-area-horizontal-left-button-rect area))
       (handle-event area nil (list :mouse-down :button :left :x x :y y))
       (handle-event area nil (list :mouse-down :button :left :x x :y y))
       (handle-event area nil (list :mouse-down :button :left :x x :y y)))
     (%assert-equal (scroll-area-scroll-x area) 0 "left button clamps scroll-x at zero"))))

(%deftest test-scroll-area-bottom-button-increases-scroll-y
  (%with-scroll-area-surface-stub
   (let* ((child (make-instance 'scroll-area-test-widget :min-width 100 :min-height 400))
          (area (make-instance 'scroll-area :child child)))
     (layout area (make-rect :x 0 :y 0 :width 120 :height 200))
     (destructuring-bind (x y) (%center-point (scroll-area-vertical-bottom-button-rect area))
       (handle-event area nil (list :mouse-down :button :left :x x :y y)))
     (%assert-equal (scroll-area-scroll-y area) 20 "bottom button increases scroll-y by fixed step"))))

(%deftest test-scroll-area-top-button-decreases-scroll-y-with-clamp
  (%with-scroll-area-surface-stub
   (let* ((child (make-instance 'scroll-area-test-widget :min-width 100 :min-height 400))
          (area (make-instance 'scroll-area :child child :scroll-y 60)))
     (layout area (make-rect :x 0 :y 0 :width 120 :height 200))
     (destructuring-bind (x y) (%center-point (scroll-area-vertical-top-button-rect area))
       (handle-event area nil (list :mouse-down :button :left :x x :y y))
       (handle-event area nil (list :mouse-down :button :left :x x :y y))
       (handle-event area nil (list :mouse-down :button :left :x x :y y))
       (handle-event area nil (list :mouse-down :button :left :x x :y y)))
     (%assert-equal (scroll-area-scroll-y area) 0 "top button clamps scroll-y at zero"))))

(%deftest test-scroll-area-scroll-offsets-clamp-to-maximum
  (%with-scroll-area-surface-stub
   (let* ((child (make-instance 'scroll-area-test-widget :min-width 400 :min-height 400))
          (area (make-instance 'scroll-area :child child)))
     (layout area (make-rect :x 0 :y 0 :width 200 :height 200))
     (destructuring-bind (hx hy) (%center-point (scroll-area-horizontal-right-button-rect area))
       (destructuring-bind (vx vy) (%center-point (scroll-area-vertical-bottom-button-rect area))
         (dotimes (i 30)
           (declare (ignore i))
           (handle-event area nil (list :mouse-down :button :left :x hx :y hy))
           (handle-event area nil (list :mouse-down :button :left :x vx :y vy)))))
     (%assert-equal (scroll-area-scroll-x area) (%scroll-area-max-scroll-x area) "scroll-area clamps scroll-x at max")
     (%assert-equal (scroll-area-scroll-y area) (%scroll-area-max-scroll-y area) "scroll-area clamps scroll-y at max"))))

(%deftest test-scroll-area-thumb-size-reflects-visible-fraction
  (%with-scroll-area-surface-stub
   (let* ((child (make-instance 'scroll-area-test-widget :min-width 400 :min-height 100))
          (area (make-instance 'scroll-area :child child)))
     (layout area (make-rect :x 0 :y 0 :width 200 :height 120))
     (%assert-equal (rect-width (scroll-area-horizontal-track-rect area)) 160 "horizontal track width")
     (%assert-equal (rect-width (scroll-area-horizontal-thumb-rect area)) 80 "horizontal thumb width is proportional to visible fraction"))))

(%deftest test-scroll-area-thumb-position-reflects-scroll-offset
  (%with-scroll-area-surface-stub
   (let* ((child (make-instance 'scroll-area-test-widget :min-width 400 :min-height 100))
          (area (make-instance 'scroll-area :child child :scroll-x 100)))
     (layout area (make-rect :x 0 :y 0 :width 200 :height 120))
     (%assert-equal (rect-x (scroll-area-horizontal-track-rect area)) 20 "horizontal track x")
     (%assert-equal (rect-x (scroll-area-horizontal-thumb-rect area)) 60 "horizontal thumb x reflects scroll position"))))

(%deftest test-scroll-area-child-layout-offset-by-scroll
  (%with-scroll-area-surface-stub
   (let* ((child (make-instance 'scroll-area-test-widget :min-width 500 :min-height 300))
          (area (make-instance 'scroll-area :child child :scroll-x 40 :scroll-y 30)))
     (layout area (make-rect :x 10 :y 20 :width 300 :height 200))
     (let* ((viewport (scroll-area-viewport-rect area))
            (child-rect (widget-layout-rect child)))
       (%assert-equal (rect-x child-rect)
                      (- (rect-x viewport) 40)
                      "scroll-area positions child x by negative scroll-x")
       (%assert-equal (rect-y child-rect)
                      (- (rect-y viewport) 30)
                      "scroll-area positions child y by negative scroll-y")))))

(%deftest test-scroll-area-renders-child-with-viewport-clip
  (%with-scroll-area-surface-stub
   (let* ((child (make-instance 'scroll-area-test-widget :min-width 250 :min-height 150))
     (area (make-instance 'scroll-area :child child :scroll-x 0 :scroll-y 0)))
     (layout area (make-rect :x 10 :y 20 :width 300 :height 200))
     (render area nil)
     (%assert-equal (%rect-value-list (scroll-area-test-render-clip child))
                    (%rect-value-list (scroll-area-viewport-rect area))
                    "scroll-area renders child with viewport clip rect"))))

(%deftest test-scroll-area-forwards-viewport-mouse-events-to-child-in-content-space
  (%with-scroll-area-surface-stub
   (let* ((child (make-instance 'scroll-area-test-widget :min-width 500 :min-height 300))
          (area (make-instance 'scroll-area :child child :scroll-x 40 :scroll-y 30)))
     (layout area (make-rect :x 10 :y 20 :width 300 :height 200))
     (let* ((viewport (scroll-area-viewport-rect area))
            (x (+ (rect-x viewport) 15))
            (y (+ (rect-y viewport) 10)))
       (handle-event area nil (list :mouse-down :button :left :x x :y y))
       (%assert-equal (getf (rest (scroll-area-test-last-event child)) :x)
                      (+ x 40)
                      "scroll-area forwards child mouse x in content coordinates")
       (%assert-equal (getf (rest (scroll-area-test-last-event child)) :y)
                      (+ y 30)
                      "scroll-area forwards child mouse y in content coordinates")))))
