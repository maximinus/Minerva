(in-package :minerva.gui)

(%deftest test-hbox-min-size
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 30))
         (b (make-instance 'color-rect :min-width 80 :min-height 20))
         (c (make-instance 'color-rect :min-width 40 :min-height 60))
         (box (make-instance 'hbox
                             :children (list a b c)
                             :margin-left 10 :margin-right 20
                             :margin-top 5 :margin-bottom 5
                             :spacing 7)))
    (%assert-min-size box 214 70 "hbox measure")))

(%deftest test-hbox-left-to-right-non-expanding
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 20))
         (b (make-instance 'color-rect :min-width 60 :min-height 30))
         (c (make-instance 'color-rect :min-width 40 :min-height 10))
         (box (make-instance 'hbox :children (list a b c) :spacing 10 :align-y :start))
         (root (make-instance 'window :width 300 :height 100 :child box)))
    (%assert-min-size box 170 30 "hbox no-margin min-size")
    (layout root (make-rect :x 0 :y 0 :width 300 :height 100))
    (%assert-rect a 0 0 50 20 "hbox child A")
    (%assert-rect b 60 0 60 30 "hbox child B")
    (%assert-rect c 130 0 40 10 "hbox child C")))

(%deftest test-hbox-leftover-width-distribution
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 20 :expand-x nil))
         (b (make-instance 'color-rect :min-width 30 :min-height 20 :expand-x t))
         (c (make-instance 'color-rect :min-width 20 :min-height 20 :expand-x t))
         (box (make-instance 'hbox :children (list a b c) :spacing 10))
         (root (make-instance 'window :width 400 :height 100 :child box)))
    (%assert-min-size box 120 20 "hbox distribution min-size")
    (layout root (make-rect :x 0 :y 0 :width 400 :height 100))
    (%assert-rect a 0 0 50 20 "hbox distribution A")
    (%assert-rect b 60 0 170 20 "hbox distribution B")
    (%assert-rect c 240 0 160 20 "hbox distribution C")))

(%deftest test-hbox-align-start
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 100))
         (b (make-instance 'color-rect :min-width 50 :min-height 150))
         (c (make-instance 'color-rect :min-width 50 :min-height 50))
         (box (make-instance 'hbox :children (list a b c) :align-y :start))
         (root (make-instance 'window :width 300 :height 150 :child box)))
    (%assert-min-size box 150 150 "hbox align-start min-size")
    (layout root (make-rect :x 0 :y 0 :width 300 :height 150))
    (%assert-rect a 0 0 50 100 "hbox align-start A")
    (%assert-rect b 50 0 50 150 "hbox align-start B")
    (%assert-rect c 100 0 50 50 "hbox align-start C")))

(%deftest test-hbox-align-center
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 100))
         (b (make-instance 'color-rect :min-width 50 :min-height 150))
         (c (make-instance 'color-rect :min-width 50 :min-height 50))
         (box (make-instance 'hbox :children (list a b c) :align-y :center))
         (root (make-instance 'window :width 300 :height 150 :child box)))
    (layout root (make-rect :x 0 :y 0 :width 300 :height 150))
    (%assert-rect a 0 25 50 100 "hbox align-center A")
    (%assert-rect b 50 0 50 150 "hbox align-center B")
    (%assert-rect c 100 50 50 50 "hbox align-center C")))

(%deftest test-hbox-align-end
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 100))
         (b (make-instance 'color-rect :min-width 50 :min-height 150))
         (c (make-instance 'color-rect :min-width 50 :min-height 50))
         (box (make-instance 'hbox :children (list a b c) :align-y :end))
         (root (make-instance 'window :width 300 :height 150 :child box)))
    (layout root (make-rect :x 0 :y 0 :width 300 :height 150))
    (%assert-rect a 0 50 50 100 "hbox align-end A")
    (%assert-rect b 50 0 50 150 "hbox align-end B")
    (%assert-rect c 100 100 50 50 "hbox align-end C")))

(%deftest test-hbox-cross-axis-expansion
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 100 :expand-y nil))
         (b (make-instance 'color-rect :min-width 50 :min-height 20 :expand-y t))
         (box (make-instance 'hbox :children (list a b) :align-y :center))
         (root (make-instance 'window :width 300 :height 150 :child box)))
    (%assert-min-size box 100 100 "hbox cross-axis expansion min-size")
    (layout root (make-rect :x 0 :y 0 :width 300 :height 150))
    (%assert-rect a 0 25 50 100 "hbox cross-axis A")
    (%assert-rect b 50 0 50 150 "hbox cross-axis B")))

(%deftest test-hbox-main-and-cross-expansion
  (let* ((a (make-instance 'color-rect :min-width 100 :min-height 50 :expand-x nil :expand-y nil))
         (b (make-instance 'color-rect :min-width 50 :min-height 20 :expand-x t :expand-y t))
         (box (make-instance 'hbox :children (list a b)))
         (root (make-instance 'window :width 400 :height 200 :child box)))
    (%assert-min-size box 150 50 "hbox main/cross expansion min-size")
    (layout root (make-rect :x 0 :y 0 :width 400 :height 200))
    (%assert-rect a 0 0 100 50 "hbox main/cross A")
    (%assert-rect b 100 0 300 200 "hbox main/cross B")))

(%deftest test-margin-reduces-inner-area
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 30))
         (box (make-instance 'hbox
                             :children (list a)
                             :margin-left 10 :margin-right 20
                             :margin-top 5 :margin-bottom 15
                             :spacing 0 :align-y :start))
         (root (make-instance 'window :width 300 :height 200 :child box)))
    (%assert-min-size box 80 50 "hbox margin min-size")
    (layout root (make-rect :x 0 :y 0 :width 300 :height 200))
    (%assert-rect a 10 5 50 30 "hbox margin child")))

(%deftest test-empty-hbox-min-size-is-margin
  (let ((box (make-instance 'hbox
                            :children nil
                            :margin-left 10 :margin-right 20
                            :margin-top 5 :margin-bottom 15
                            :spacing 0)))
    (%assert-min-size box 30 20 "empty hbox")))

(%deftest test-single-child-hbox
  (let* ((a (make-instance 'color-rect :min-width 70 :min-height 20))
         (box (make-instance 'hbox :children (list a) :align-y :center))
         (root (make-instance 'window :width 300 :height 100 :child box)))
    (%assert-min-size box 70 20 "single child hbox min-size")
    (layout root (make-rect :x 0 :y 0 :width 300 :height 100))
    (%assert-rect a 0 40 70 20 "single child hbox rect")))

(%deftest test-no-expanders-leave-extra-unassigned
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 20 :expand-x nil))
         (b (make-instance 'color-rect :min-width 50 :min-height 20 :expand-x nil))
         (box (make-instance 'hbox :children (list a b) :spacing 0))
         (root (make-instance 'window :width 400 :height 100 :child box)))
    (%assert-min-size box 100 20 "no-expander hbox min-size")
    (layout root (make-rect :x 0 :y 0 :width 400 :height 100))
    (%assert-rect a 0 0 50 20 "no-expander A")
    (%assert-rect b 50 0 50 20 "no-expander B")
    (%assert-equal (+ (rect-width (widget-layout-rect a)) (rect-width (widget-layout-rect b)))
                   100
                   "no-expander total used width")))

(%deftest test-cross-axis-expansion-not-in-main-measure
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 20 :expand-y t))
         (b (make-instance 'color-rect :min-width 80 :min-height 30 :expand-y nil))
         (c (make-instance 'color-rect :min-width 40 :min-height 10 :expand-y t))
         (box (make-instance 'hbox
                             :children (list a b c)
                             :margin-left 10 :margin-right 20
                             :margin-top 5 :margin-bottom 5
                             :spacing 6)))
    (%assert-min-size box 212 40 "cross-axis expansion in hbox measure")
    (%assert-expand-flags box nil nil "cross-axis expansion does not propagate upward")))

(%deftest test-hbox-expanding-wrappers-equal-space-with-different-margin
  (let* ((leaf-a (make-instance 'color-rect :min-width 0 :min-height 0 :expand-x t :expand-y t))
         (leaf-b (make-instance 'color-rect :min-width 0 :min-height 0 :expand-x t :expand-y t))
         (leaf-c (make-instance 'color-rect :min-width 0 :min-height 0 :expand-x t :expand-y t))
         (wrap-a (make-instance 'vbox
                                :children (list leaf-a)
                                :margin-left 0 :margin-right 0
                                :margin-top 0 :margin-bottom 0
                                :spacing 0
                                :align-x :start
                                :expand-x t
                                :expand-y t))
         (wrap-b (make-instance 'vbox
                                :children (list leaf-b)
                                :margin-left 25 :margin-right 25
                                :margin-top 25 :margin-bottom 25
                                :spacing 0
                                :align-x :start
                                :expand-x t
                                :expand-y t))
         (wrap-c (make-instance 'vbox
                                :children (list leaf-c)
                                :margin-left 50 :margin-right 50
                                :margin-top 50 :margin-bottom 50
                                :spacing 0
                                :align-x :start
                                :expand-x t
                                :expand-y t))
         (row (make-instance 'hbox :children (list wrap-a wrap-b wrap-c) :spacing 0 :align-y :start))
         (root (make-instance 'window :width 900 :height 300 :child row)))
    (layout root (make-rect :x 0 :y 0 :width 900 :height 300))
    (%assert-rect wrap-a 0 0 250 300 "hbox margin wrappers A min-size + equal extra")
    (%assert-rect wrap-b 275 25 250 250 "hbox margin wrappers B min-size + equal extra")
    (%assert-rect wrap-c 600 50 250 200 "hbox margin wrappers C min-size + equal extra")
    (%assert-rect leaf-a 0 0 250 300 "hbox margin leaf A visible rect")
    (%assert-rect leaf-b 275 25 250 250 "hbox margin leaf B visible rect")
    (%assert-rect leaf-c 600 50 250 200 "hbox margin leaf C visible rect")))

(%deftest test-container-expand-is-parent-level-eligibility
  (let* ((left-leaf (make-instance 'color-rect :min-width 20 :min-height 10 :expand-x nil :expand-y nil))
         (right-leaf (make-instance 'color-rect :min-width 20 :min-height 10 :expand-x t :expand-y nil))
         (left-box (make-instance 'hbox :children (list left-leaf)))
         (right-box (make-instance 'hbox :children (list right-leaf)))
         (parent (make-instance 'hbox :children (list left-box right-box) :spacing 0))
         (root (make-instance 'window :width 100 :height 20 :child parent)))
    (%assert-min-size parent 40 10 "parent min-size from children mins only")
    (layout root (make-rect :x 0 :y 0 :width 100 :height 20))
    (%assert-rect left-box 0 0 20 10 "non-expanding container keeps min width")
    (%assert-rect right-box 20 0 20 10 "child expand does not make parent container expand")))

(%deftest test-container-expands-only-when-explicitly-set
  (let* ((left-leaf (make-instance 'color-rect :min-width 20 :min-height 10 :expand-x nil :expand-y nil))
         (right-leaf (make-instance 'color-rect :min-width 20 :min-height 10 :expand-x t :expand-y nil))
         (left-box (make-instance 'hbox :children (list left-leaf) :expand-x nil))
         (right-box (make-instance 'hbox :children (list right-leaf) :expand-x t))
         (parent (make-instance 'hbox :children (list left-box right-box) :spacing 0))
         (root (make-instance 'window :width 100 :height 20 :child parent)))
    (layout root (make-rect :x 0 :y 0 :width 100 :height 20))
    (%assert-rect left-box 0 0 20 10 "non-expanding container keeps min width")
    (%assert-rect right-box 20 0 80 10 "container expands only when explicitly set")))
