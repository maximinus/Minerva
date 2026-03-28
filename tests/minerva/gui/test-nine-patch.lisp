(in-package :minerva.gui)

(%deftest test-33-nine-patch-min-size-includes-child-and-borders
  (let* ((child (make-instance 'color-rect :min-width 50 :min-height 20))
         (panel (make-instance 'nine-patch
                               :surface '(:width 100 :height 100)
                               :border-left 4
                               :border-right 6
                               :border-top 8
                               :border-bottom 10
                               :child child)))
    (%assert-min-size panel 60 38 "nine-patch min-size")))

(%deftest test-nine-patch-child-layout-uses-center-rect
  (let* ((child (make-instance 'color-rect :min-width 20 :min-height 10 :expand-x t :expand-y t))
         (panel (make-instance 'nine-patch
                               :surface '(:width 90 :height 90)
                               :border-left 5
                               :border-right 7
                               :border-top 11
                               :border-bottom 13
                               :expand-x t
                               :expand-y t
                               :child child))
         (root (make-instance 'window :width 100 :height 80 :child panel)))
    (layout root (make-rect :x 0 :y 0 :width 100 :height 80))
    (%assert-equal (let ((r (nine-patch-content-rect panel)))
                     (list (rect-x r) (rect-y r) (rect-width r) (rect-height r)))
                   '(5 11 88 56)
                   "nine-patch content rect")
    (%assert-rect child 5 11 88 56 "nine-patch child laid out in center")))

(%deftest test-nine-patch-min-size-no-child-borders-only
  (let ((panel (make-instance 'nine-patch
                              :surface '(:width 20 :height 20)
                              :border-left 3 :border-right 4 :border-top 5 :border-bottom 6)))
    (%assert-min-size panel 7 11 "nine-patch no child min-size")))

(%deftest test-nine-patch-min-size-includes-child
  (let* ((child (make-instance 'color-rect :min-width 100 :min-height 50))
         (panel (make-instance 'nine-patch
                               :surface '(:width 20 :height 20)
                               :border-left 3 :border-right 4 :border-top 5 :border-bottom 6
                               :child child)))
    (%assert-min-size panel 107 61 "nine-patch with child min-size")))

(%deftest test-nine-patch-min-size-updates-with-child-change
  (let* ((small (make-instance 'color-rect :min-width 10 :min-height 10))
         (large (make-instance 'color-rect :min-width 30 :min-height 40))
         (panel (make-instance 'nine-patch
                               :surface '(:width 20 :height 20)
                               :border-left 2 :border-right 3 :border-top 4 :border-bottom 5
                               :child small)))
    (%assert-min-size panel 15 19 "nine-patch with small child")
    (setf (nine-patch-child panel) large)
    (%assert-min-size panel 35 49 "nine-patch with large child")))

(%deftest test-nine-patch-child-layout-center-area
  (let* ((child (make-instance 'color-rect :min-width 1 :min-height 1 :expand-x t :expand-y t))
         (panel (make-instance 'nine-patch
                               :surface '(:width 20 :height 20)
                               :border-left 10 :border-right 20 :border-top 5 :border-bottom 15
                               :child child)))
    (layout panel (make-rect :x 100 :y 50 :width 200 :height 100))
    (%assert-rect child 110 55 170 80 "nine-patch child center layout")))

(%deftest test-nine-patch-no-child-layout-safe
  (let ((panel (make-instance 'nine-patch
                              :surface '(:width 20 :height 20)
                              :border-left 2 :border-right 2 :border-top 2 :border-bottom 2)))
    (layout panel (make-rect :x 0 :y 0 :width 40 :height 30))
    (%assert-equal (%rect-value-list (nine-patch-content-rect panel)) '(2 2 36 26) "nine-patch no child content rect")))

(%deftest test-nine-patch-nested-child-layout
  (let* ((a (make-instance 'color-rect :min-width 10 :min-height 10))
         (b (make-instance 'color-rect :min-width 10 :min-height 10))
         (inner (make-instance 'vbox :children (list a b) :spacing 5))
         (panel (make-instance 'nine-patch
                               :surface '(:width 50 :height 50)
                               :border-left 3 :border-right 4 :border-top 5 :border-bottom 6
                               :child inner)))
    (layout panel (make-rect :x 10 :y 20 :width 100 :height 60))
    (%assert-rect inner 13 25 93 49 "nested vbox receives center area")
    (%assert-equal (rect-x (widget-layout-rect a)) 13 "nested child A x")
    (%assert-equal (rect-y (widget-layout-rect a)) 25 "nested child A y")))

(%deftest test-nine-patch-corners-fixed-size
  (let ((calls '())
        (panel (make-instance 'nine-patch
                              :surface '(:width 20 :height 20)
                              :border-left 2 :border-right 3 :border-top 4 :border-bottom 5)))
    (let ((old (symbol-function 'minerva.gui::%call-draw-surface-rect-scaled)))
      (unwind-protect
           (progn
             (setf (symbol-function 'minerva.gui::%call-draw-surface-rect-scaled)
                   (lambda (backend-window surface source-rect dest-rect)
                     (declare (ignore backend-window surface))
                     (push (list (%rect-value-list source-rect) (%rect-value-list dest-rect)) calls)))
             (layout panel (make-rect :x 0 :y 0 :width 80 :height 70))
             (render panel nil))
        (setf (symbol-function 'minerva.gui::%call-draw-surface-rect-scaled) old)))
    (%assert-equal (length calls) 9 "nine patches draw count")
    (let* ((dest-rects (mapcar #'second calls))
           (top-left (find-if (lambda (r) (and (= (first r) 0) (= (second r) 0))) dest-rects))
           (top-right (find-if (lambda (r) (and (= (first r) 77) (= (second r) 0))) dest-rects))
           (bottom-left (find-if (lambda (r) (and (= (first r) 0) (= (second r) 65))) dest-rects))
           (bottom-right (find-if (lambda (r) (and (= (first r) 77) (= (second r) 65))) dest-rects)))
      (%assert-equal (third top-left) 2 "top-left width fixed")
      (%assert-equal (fourth top-left) 4 "top-left height fixed")
      (%assert-equal (third top-right) 3 "top-right width fixed")
      (%assert-equal (fourth bottom-left) 5 "bottom-left height fixed")
      (%assert-equal (third bottom-right) 3 "bottom-right width fixed"))))

(%deftest test-nine-patch-top-bottom-edges-stretch-horizontally
  (let ((calls '())
        (panel (make-instance 'nine-patch :surface '(:width 20 :height 20)
                              :border-left 2 :border-right 3 :border-top 4 :border-bottom 5)))
    (let ((old (symbol-function 'minerva.gui::%call-draw-surface-rect-scaled)))
      (unwind-protect
           (progn
             (setf (symbol-function 'minerva.gui::%call-draw-surface-rect-scaled)
                   (lambda (backend-window surface source-rect dest-rect)
                     (declare (ignore backend-window surface source-rect))
                     (push (%rect-value-list dest-rect) calls)))
             (layout panel (make-rect :x 0 :y 0 :width 80 :height 70))
             (render panel nil))
        (setf (symbol-function 'minerva.gui::%call-draw-surface-rect-scaled) old)))
    (let* ((top-edge (find-if (lambda (r) (and (= (second r) 0) (> (third r) 2))) calls))
           (bottom-edge (find-if (lambda (r) (and (= (second r) 65) (> (third r) 2))) calls)))
      (%assert-equal (> (third top-edge) 2) t "top edge stretched horizontally")
      (%assert-equal (> (third bottom-edge) 2) t "bottom edge stretched horizontally")
      (%assert-equal (fourth top-edge) 4 "top edge fixed thickness")
      (%assert-equal (fourth bottom-edge) 5 "bottom edge fixed thickness"))))

(%deftest test-nine-patch-left-right-edges-stretch-vertically
  (let ((calls '())
        (panel (make-instance 'nine-patch :surface '(:width 20 :height 20)
                              :border-left 2 :border-right 3 :border-top 4 :border-bottom 5)))
    (let ((old (symbol-function 'minerva.gui::%call-draw-surface-rect-scaled)))
      (unwind-protect
           (progn
             (setf (symbol-function 'minerva.gui::%call-draw-surface-rect-scaled)
                   (lambda (backend-window surface source-rect dest-rect)
                     (declare (ignore backend-window surface source-rect))
                     (push (%rect-value-list dest-rect) calls)))
             (layout panel (make-rect :x 0 :y 0 :width 80 :height 70))
             (render panel nil))
        (setf (symbol-function 'minerva.gui::%call-draw-surface-rect-scaled) old)))
    (let* ((left-edge (find-if (lambda (r) (and (= (first r) 0) (> (fourth r) 4))) calls))
           (right-edge (find-if (lambda (r) (and (= (first r) 77) (> (fourth r) 4))) calls)))
      (%assert-equal (third left-edge) 2 "left edge fixed width")
      (%assert-equal (third right-edge) 3 "right edge fixed width")
      (%assert-equal (> (fourth left-edge) 4) t "left edge stretched vertically")
      (%assert-equal (> (fourth right-edge) 4) t "right edge stretched vertically"))))

(%deftest test-nine-patch-center-stretches
  (let ((calls '())
        (panel (make-instance 'nine-patch :surface '(:width 20 :height 20)
                              :border-left 2 :border-right 3 :border-top 4 :border-bottom 5)))
    (let ((old (symbol-function 'minerva.gui::%call-draw-surface-rect-scaled)))
      (unwind-protect
           (progn
             (setf (symbol-function 'minerva.gui::%call-draw-surface-rect-scaled)
                   (lambda (backend-window surface source-rect dest-rect)
                     (declare (ignore backend-window surface source-rect))
                     (push (%rect-value-list dest-rect) calls)))
             (layout panel (make-rect :x 0 :y 0 :width 80 :height 70))
             (render panel nil))
        (setf (symbol-function 'minerva.gui::%call-draw-surface-rect-scaled) old)))
    (let ((center (find-if (lambda (r) (and (> (third r) 10) (> (fourth r) 10)
                                            (/= (first r) 0) (/= (second r) 0)))
                           calls)))
      (%assert-equal (> (third center) 10) t "center stretched width")
      (%assert-equal (> (fourth center) 10) t "center stretched height"))))

(%deftest test-nine-patch-small-output-clips-safely
  (let ((panel (make-instance 'nine-patch :surface '(:width 20 :height 20)
                              :border-left 10 :border-right 10 :border-top 10 :border-bottom 10)))
    (layout panel (make-rect :x 0 :y 0 :width 5 :height 5))
    (%assert-equal (%rect-value-list (nine-patch-content-rect panel)) '(10 10 0 0) "small output clipped content area")))

(%deftest test-nine-patch-renders-before-child
  (let* ((events '())
         (child (make-instance 'color-rect :min-width 10 :min-height 10 :color '(1 2 3 255)))
         (panel (make-instance 'nine-patch :surface '(:width 20 :height 20)
                               :border-left 2 :border-right 2 :border-top 2 :border-bottom 2
                               :child child))
         (old-draw (symbol-function 'minerva.gui::%call-draw-surface-rect-scaled))
         (old-fill (symbol-function 'minerva.gui::%call-fill-rect)))
    (unwind-protect
         (progn
           (setf (symbol-function 'minerva.gui::%call-draw-surface-rect-scaled)
                 (lambda (&rest args)
                   (declare (ignore args))
                   (push :nine-patch events)))
           (setf (symbol-function 'minerva.gui::%call-fill-rect)
                 (lambda (&rest args)
                   (declare (ignore args))
                   (push :child events)))
           (layout panel (make-rect :x 0 :y 0 :width 30 :height 30))
           (render panel nil))
      (setf (symbol-function 'minerva.gui::%call-draw-surface-rect-scaled) old-draw)
      (setf (symbol-function 'minerva.gui::%call-fill-rect) old-fill))
    (%assert-equal (car (last events)) :nine-patch "first render action is nine-patch")
    (%assert-equal (car events) :child "last render action is child")))

(%deftest test-child-confined-to-content-area
  (let* ((child (make-instance 'color-rect :min-width 100 :min-height 100 :expand-x t :expand-y t))
         (panel (make-instance 'nine-patch :surface '(:width 20 :height 20)
                               :border-left 4 :border-right 4 :border-top 3 :border-bottom 3
                               :child child)))
    (layout panel (make-rect :x 10 :y 10 :width 30 :height 20))
    (%assert-equal (%rect-value-list (widget-layout-rect child)) '(14 13 22 14) "child confined to center rect")))

(%deftest test-image-inside-nine-patch-min-size
  (let* ((img (make-instance 'image :surface '(:width 20 :height 10)))
         (panel (make-instance 'nine-patch :surface '(:width 20 :height 20)
                               :border-left 3 :border-right 4 :border-top 5 :border-bottom 6
                               :child img)))
    (%assert-min-size panel 27 21 "image + borders minimum size")))

(%deftest test-nine-patch-256-image-min-size-is-288
  (let* ((img (make-instance 'image :surface '(:width 256 :height 256)))
         (panel (make-instance 'nine-patch :surface '(:width 48 :height 48)
                               :border-left 16 :border-right 16
                               :border-top 16 :border-bottom 16
                               :child img)))
    (%assert-min-size panel 288 288 "nine-patch + 256 image min-size")))

(%deftest test-nine-patch-containing-text-image-layout
  (let ((img (make-instance 'image :surface '(:width 40 :height 12)))
        (panel nil))
    (setf panel (make-instance 'nine-patch :surface '(:width 20 :height 20)
                               :border-left 3 :border-right 3 :border-top 3 :border-bottom 3
                               :child img))
    (layout panel (make-rect :x 0 :y 0 :width 80 :height 40))
    (%assert-equal (%rect-value-list (widget-layout-rect img)) '(3 3 74 34) "text-image child center placement")))

(%deftest test-nine-patch-layout-deterministic
  (let* ((child (make-instance 'color-rect :min-width 10 :min-height 10 :expand-x t :expand-y t))
         (panel (make-instance 'nine-patch :surface '(:width 20 :height 20)
                               :border-left 2 :border-right 3 :border-top 4 :border-bottom 5
                               :child child))
         first
         second)
    (layout panel (make-rect :x 10 :y 20 :width 70 :height 60))
    (setf first (list (%rect-value-list (widget-layout-rect panel))
                      (%rect-value-list (nine-patch-content-rect panel))
                      (%rect-value-list (widget-layout-rect child))))
    (layout panel (make-rect :x 10 :y 20 :width 70 :height 60))
    (setf second (list (%rect-value-list (widget-layout-rect panel))
                       (%rect-value-list (nine-patch-content-rect panel))
                       (%rect-value-list (widget-layout-rect child))))
    (%assert-equal first second "nine-patch layout deterministic")))
