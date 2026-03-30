(in-package :minerva.gui)

(defclass test-render-probe-widget (widget) ())

(defmethod measure ((widget test-render-probe-widget))
  (declare (ignore widget))
  (make-size-request :min-width 0 :min-height 0 :expand-x nil :expand-y nil))

(defmethod layout ((widget test-render-probe-widget) rect)
  (setf (widget-layout-rect widget)
        (%apply-widget-margins-to-rect widget rect))
  widget)

(defmethod render ((widget test-render-probe-widget) backend-window)
  (declare (ignore backend-window))
  widget)

(%deftest test-make-margins-single-value
  (let ((margins (make-margins 5)))
    (%assert-equal (list (margins-left margins)
                         (margins-right margins)
                         (margins-top margins)
                         (margins-bottom margins))
                   '(5 5 5 5)
                   "single-value margins set all sides")))

(%deftest test-widget-last-render-position-updates-after-render
  (let ((probe (make-instance 'test-render-probe-widget :margins 5)))
    (%assert-equal (widget-last-render-position probe)
                   nil
                   "last-render-position is nil before first render")
    (layout probe (make-rect :x 10 :y 20 :width 100 :height 50))
    (render probe nil)
    (%assert-equal (%rect-value-list (widget-last-render-position probe))
                   '(15 25 90 40)
                   "last-render-position stores inner/content rect after render")))

(%deftest test-make-margins-keyword-values
  (let ((margins (make-margins :margin-top 5 :margin-bottom 7)))
    (%assert-equal (list (margins-left margins)
                         (margins-right margins)
                         (margins-top margins)
                         (margins-bottom margins))
                   '(0 0 5 7)
                   "keyword margins set only supplied sides")))

(%deftest test-widget-accepts-margins-struct
  (let* ((box (make-instance 'hbox
                             :children nil
                             :margins (make-margins 5)
                             :spacing 0)))
    (%assert-min-size box 10 10 "margins struct affects widget min-size")
    (%assert-equal (list (widget-margin-left box)
                         (widget-margin-right box)
                         (widget-margin-top box)
                         (widget-margin-bottom box))
                   '(5 5 5 5)
                   "widget side accessors reflect margins struct")))

(%deftest test-nested-containers
  (let* ((top (make-instance 'color-rect :min-width 100 :min-height 50))
         (left (make-instance 'color-rect :min-width 50 :min-height 100))
         (right (make-instance 'color-rect :min-width 50 :min-height 50))
         (bottom (make-instance 'hbox :children (list left right) :spacing 10 :align-y :center))
         (root-box (make-instance 'vbox
                                  :children (list top bottom)
                                  :margin-left 10 :margin-right 10
                                  :margin-top 10 :margin-bottom 10
                                  :spacing 20 :align-x :start))
         (root (make-instance 'window :width 500 :height 300 :child root-box)))
    (%assert-min-size bottom 110 100 "nested bottom hbox min-size")
    (%assert-min-size root-box 130 190 "nested root vbox min-size")
    (layout root (make-rect :x 0 :y 0 :width 500 :height 300))
    (%assert-rect top 10 10 100 50 "nested top")
    (%assert-rect bottom 10 80 110 100 "nested bottom")
    (%assert-rect left 10 80 50 100 "nested bottom left")
    (%assert-rect right 70 105 50 50 "nested bottom right")))

(%deftest test-valid-layout-has-non-negative-rectangles
  (let* ((a (make-instance 'color-rect :min-width 30 :min-height 20))
         (b (make-instance 'color-rect :min-width 40 :min-height 10))
         (box (make-instance 'hbox
                             :children (list a b)
                             :margin-left 10 :margin-right 5
                             :margin-top 3 :margin-bottom 2
                             :spacing 4))
         (req (measure box))
         (root (make-instance 'window
                              :width (size-request-min-width req)
                              :height (size-request-min-height req)
                              :child box)))
    (layout root (make-rect :x 0 :y 0
                            :width (size-request-min-width req)
                            :height (size-request-min-height req)))
    (%assert-equal (%all-non-negative-rect-p box a b)
                   t
                   "all rectangles non-negative")))

(%deftest test-layout-deterministic
  (let* ((top (make-instance 'color-rect :min-width 120 :min-height 40))
         (left (make-instance 'color-rect :min-width 40 :min-height 60))
         (fill (make-instance 'filler :min-width 0 :min-height 0 :expand-x t :expand-y nil))
         (right (make-instance 'color-rect :min-width 50 :min-height 30))
         (row (make-instance 'hbox
                             :children (list left fill right)
                             :margin-left 5 :margin-right 5
                             :margin-top 2 :margin-bottom 2
                             :spacing 10 :align-y :center))
         (column (make-instance 'vbox
                                :children (list top row)
                                :margin-left 7 :margin-right 7
                                :margin-top 9 :margin-bottom 9
                                :spacing 12 :align-x :start))
         (root (make-instance 'window :width 420 :height 260 :child column))
         (first-measure (measure column))
         (second-measure (measure column))
         first-layout
         second-layout)
    (%assert-equal
     (list (size-request-min-width first-measure)
           (size-request-min-height first-measure)
           (size-request-expand-x first-measure)
           (size-request-expand-y first-measure))
     (list (size-request-min-width second-measure)
           (size-request-min-height second-measure)
           (size-request-expand-x second-measure)
           (size-request-expand-y second-measure))
     "deterministic measure")
    (layout root (make-rect :x 0 :y 0 :width 420 :height 260))
    (setf first-layout (list (%rect-list column) (%rect-list top) (%rect-list row)
                             (%rect-list left) (%rect-list fill) (%rect-list right)))
    (layout root (make-rect :x 0 :y 0 :width 420 :height 260))
    (setf second-layout (list (%rect-list column) (%rect-list top) (%rect-list row)
                              (%rect-list left) (%rect-list fill) (%rect-list right)))
    (%assert-equal first-layout second-layout "deterministic layout")))

(%deftest test-expand-does-not-change-min-size
  (let* ((fixed (make-instance 'color-rect :min-width 40 :min-height 10 :expand-x nil :expand-y nil))
         (expanding (make-instance 'color-rect :min-width 40 :min-height 10 :expand-x t :expand-y nil))
         (fixed-box (make-instance 'hbox :children (list fixed)))
         (expanding-box (make-instance 'hbox :children (list expanding))))
    (%assert-min-size fixed-box 40 10 "fixed child min-size")
    (%assert-min-size expanding-box 40 10 "expanding child same min-size")
    (%assert-expand-flags fixed-box nil nil "fixed child does not propagate expand")
    (%assert-expand-flags expanding-box nil nil "expanding child does not propagate eligibility")))
