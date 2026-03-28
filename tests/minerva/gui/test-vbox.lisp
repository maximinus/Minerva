(in-package :minerva.gui)

(%deftest test-vbox-min-size
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 30))
         (b (make-instance 'color-rect :min-width 80 :min-height 20))
         (c (make-instance 'color-rect :min-width 40 :min-height 60))
         (box (make-instance 'vbox
                             :children (list a b c)
                             :margin-left 3 :margin-right 4
                             :margin-top 10 :margin-bottom 20
                             :spacing 5)))
    (%assert-min-size box 87 150 "vbox measure")))

(%deftest test-vbox-top-to-bottom-non-expanding
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 20))
         (b (make-instance 'color-rect :min-width 60 :min-height 30))
         (c (make-instance 'color-rect :min-width 40 :min-height 10))
         (box (make-instance 'vbox :children (list a b c) :spacing 8 :align-x :start))
         (root (make-instance 'window :width 200 :height 300 :child box)))
    (%assert-min-size box 60 76 "vbox no-margin min-size")
    (layout root (make-rect :x 0 :y 0 :width 200 :height 300))
    (%assert-rect a 0 0 50 20 "vbox child A")
    (%assert-rect b 0 28 60 30 "vbox child B")
    (%assert-rect c 0 66 40 10 "vbox child C")))

(%deftest test-vbox-leftover-height-distribution
  (let* ((a (make-instance 'color-rect :min-width 20 :min-height 50 :expand-y nil))
         (b (make-instance 'color-rect :min-width 20 :min-height 30 :expand-y t))
         (c (make-instance 'color-rect :min-width 20 :min-height 20 :expand-y t))
         (box (make-instance 'vbox :children (list a b c) :spacing 10))
         (root (make-instance 'window :width 100 :height 300 :child box)))
    (%assert-min-size box 20 120 "vbox distribution min-size")
    (layout root (make-rect :x 0 :y 0 :width 100 :height 300))
    (%assert-rect a 0 0 20 50 "vbox distribution A")
    (%assert-rect b 0 60 20 120 "vbox distribution B")
    (%assert-rect c 0 190 20 110 "vbox distribution C")))

(%deftest test-vbox-align-start
  (let* ((a (make-instance 'color-rect :min-width 100 :min-height 50))
         (b (make-instance 'color-rect :min-width 200 :min-height 50))
         (c (make-instance 'color-rect :min-width 50 :min-height 50))
         (box (make-instance 'vbox :children (list a b c) :align-x :start))
         (root (make-instance 'window :width 200 :height 300 :child box)))
    (%assert-min-size box 200 150 "vbox align-start min-size")
    (layout root (make-rect :x 0 :y 0 :width 200 :height 300))
    (%assert-rect a 0 0 100 50 "vbox align-start A")
    (%assert-rect b 0 50 200 50 "vbox align-start B")
    (%assert-rect c 0 100 50 50 "vbox align-start C")))

(%deftest test-vbox-align-center
  (let* ((a (make-instance 'color-rect :min-width 100 :min-height 50))
         (b (make-instance 'color-rect :min-width 200 :min-height 50))
         (c (make-instance 'color-rect :min-width 50 :min-height 50))
         (box (make-instance 'vbox :children (list a b c) :align-x :center))
         (root (make-instance 'window :width 200 :height 300 :child box)))
    (layout root (make-rect :x 0 :y 0 :width 200 :height 300))
    (%assert-rect a 50 0 100 50 "vbox align-center A")
    (%assert-rect b 0 50 200 50 "vbox align-center B")
    (%assert-rect c 75 100 50 50 "vbox align-center C")))

(%deftest test-vbox-align-end
  (let* ((a (make-instance 'color-rect :min-width 100 :min-height 50))
         (b (make-instance 'color-rect :min-width 200 :min-height 50))
         (c (make-instance 'color-rect :min-width 50 :min-height 50))
         (box (make-instance 'vbox :children (list a b c) :align-x :end))
         (root (make-instance 'window :width 200 :height 300 :child box)))
    (layout root (make-rect :x 0 :y 0 :width 200 :height 300))
    (%assert-rect a 100 0 100 50 "vbox align-end A")
    (%assert-rect b 0 50 200 50 "vbox align-end B")
    (%assert-rect c 150 100 50 50 "vbox align-end C")))

(%deftest test-empty-vbox-min-size-is-margin
  (let ((box (make-instance 'vbox
                            :children nil
                            :margin-left 10 :margin-right 20
                            :margin-top 5 :margin-bottom 15
                            :spacing 0)))
    (%assert-min-size box 30 20 "empty vbox")))

(%deftest test-single-child-vbox
  (let* ((a (make-instance 'color-rect :min-width 70 :min-height 20))
         (box (make-instance 'vbox :children (list a) :align-x :center))
         (root (make-instance 'window :width 200 :height 300 :child box)))
    (%assert-min-size box 70 20 "single child vbox min-size")
    (layout root (make-rect :x 0 :y 0 :width 200 :height 300))
    (%assert-rect a 65 0 70 20 "single child vbox rect")))

(%deftest test-main-axis-expansion-not-in-cross-measure
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 20 :expand-y t))
         (b (make-instance 'color-rect :min-width 80 :min-height 30 :expand-y nil))
         (c (make-instance 'color-rect :min-width 40 :min-height 10 :expand-y t))
         (box (make-instance 'vbox
                             :children (list a b c)
                             :margin-left 3 :margin-right 4
                             :margin-top 10 :margin-bottom 20
                             :spacing 5)))
    (%assert-min-size box 87 100 "main-axis expansion in vbox measure")
    (%assert-expand-flags box nil nil "main-axis expansion does not propagate upward")))

(%deftest test-container-margins-affect-min-size-and-child-placement
  (let* ((child (make-instance 'color-rect :min-width 20 :min-height 10))
         (box (make-instance 'vbox
                             :children (list child)
                             :margin-left 7 :margin-right 9
                             :margin-top 11 :margin-bottom 13
                             :spacing 0
                             :align-x :start))
         (root (make-instance 'window :width 100 :height 100 :child box)))
    (%assert-min-size box 36 34 "container margin min-size")
    (layout root (make-rect :x 0 :y 0 :width 100 :height 100))
    (%assert-rect box 7 11 84 76 "container margin applied to own layout")
    (%assert-rect child 7 11 20 10 "container margin offset child")))

(%deftest test-vbox-expanding-wrappers-equal-space-with-different-margin
  (let* ((leaf-a (make-instance 'color-rect :min-width 0 :min-height 0 :expand-x t :expand-y t))
         (leaf-b (make-instance 'color-rect :min-width 0 :min-height 0 :expand-x t :expand-y t))
         (leaf-c (make-instance 'color-rect :min-width 0 :min-height 0 :expand-x t :expand-y t))
         (wrap-a (make-instance 'hbox
                                :children (list leaf-a)
                                :margin-left 0 :margin-right 0
                                :margin-top 0 :margin-bottom 0
                                :spacing 0
                                :align-y :start
                                :expand-x t
                                :expand-y t))
         (wrap-b (make-instance 'hbox
                                :children (list leaf-b)
                                :margin-left 25 :margin-right 25
                                :margin-top 25 :margin-bottom 25
                                :spacing 0
                                :align-y :start
                                :expand-x t
                                :expand-y t))
         (wrap-c (make-instance 'hbox
                                :children (list leaf-c)
                                :margin-left 50 :margin-right 50
                                :margin-top 50 :margin-bottom 50
                                :spacing 0
                                :align-y :start
                                :expand-x t
                                :expand-y t))
         (column (make-instance 'vbox :children (list wrap-a wrap-b wrap-c) :spacing 0 :align-x :start))
         (root (make-instance 'window :width 300 :height 900 :child column)))
    (layout root (make-rect :x 0 :y 0 :width 300 :height 900))
    (%assert-rect wrap-a 0 0 300 250 "vbox margin wrappers A min-size + equal extra")
    (%assert-rect wrap-b 25 275 250 250 "vbox margin wrappers B min-size + equal extra")
    (%assert-rect wrap-c 50 600 200 250 "vbox margin wrappers C min-size + equal extra")
    (%assert-rect leaf-a 0 0 300 250 "vbox margin leaf A visible rect")
    (%assert-rect leaf-b 25 275 250 250 "vbox margin leaf B visible rect")
    (%assert-rect leaf-c 50 600 200 250 "vbox margin leaf C visible rect")))
