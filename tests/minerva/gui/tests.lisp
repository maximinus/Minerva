(in-package :minerva.gui)

(defvar *test-count* 0)
(defvar *test-failures* 0)

(defmacro %deftest (name &body body)
  `(defun ,name ()
     ,@body))

(defun %assert-equal (actual expected label)
  (incf *test-count*)
  (unless (equal actual expected)
    (incf *test-failures*)
    (format t "[FAIL] ~A expected=~S actual=~S~%" label expected actual)))

(defun %assert-rect (widget x y width height label)
  (let ((rect (widget-layout-rect widget)))
    (%assert-equal
     (list (rect-x rect) (rect-y rect) (rect-width rect) (rect-height rect))
     (list x y width height)
     label)))

(defun %assert-min-size (widget min-width min-height label)
  (let ((request (measure widget)))
    (%assert-equal (size-request-min-width request) min-width (concatenate 'string label " min-width"))
    (%assert-equal (size-request-min-height request) min-height (concatenate 'string label " min-height"))))

(defun %assert-expand-flags (widget expand-x expand-y label)
  (let ((request (measure widget)))
    (%assert-equal (size-request-expand-x request) expand-x (concatenate 'string label " expand-x"))
    (%assert-equal (size-request-expand-y request) expand-y (concatenate 'string label " expand-y"))))

(defun %all-non-negative-rect-p (&rest widgets)
  (every (lambda (widget)
           (let ((rect (widget-layout-rect widget)))
             (and (>= (rect-x rect) 0)
                  (>= (rect-y rect) 0)
                  (>= (rect-width rect) 0)
                  (>= (rect-height rect) 0))))
         widgets))

(defun %rect-list (widget)
  (let ((r (widget-layout-rect widget)))
    (list (rect-x r) (rect-y r) (rect-width r) (rect-height r))))

(defun %run-test-case (test-symbol)
  (let ((failures-before *test-failures*))
    (handler-case
        (progn
          (funcall (symbol-function test-symbol))
          (if (= failures-before *test-failures*)
              (format t "* Pass ~(~A~)~%" test-symbol)
              (format t "- Fail ~(~A~)~%" test-symbol)))
      (error (condition)
        (incf *test-failures*)
        (format t "- Fail ~(~A~) (~A)~%" test-symbol condition)))))

(%deftest test-01-window-passes-child-without-expand
  (let* ((child (make-instance 'color-rect :min-width 100 :min-height 50 :expand-x nil :expand-y nil))
         (root (make-instance 'window :width 800 :height 600 :child child)))
    (%assert-min-size root 100 50 "window with fixed child")
    (layout root (make-rect :x 0 :y 0 :width 800 :height 600))
    (%assert-rect child 0 0 100 50 "window fixed child final rect")))

(%deftest test-02-window-expanding-child-fills
  (let* ((child (make-instance 'color-rect :min-width 100 :min-height 50 :expand-x t :expand-y t))
         (root (make-instance 'window :width 800 :height 600 :child child)))
    (%assert-min-size root 100 50 "window with expanding child")
    (%assert-expand-flags child t t "expanding child flags")
    (layout root (make-rect :x 0 :y 0 :width 800 :height 600))
    (%assert-rect child 0 0 800 600 "window expanding child final rect")))

(%deftest test-03-hbox-min-size
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 30))
         (b (make-instance 'color-rect :min-width 80 :min-height 20))
         (c (make-instance 'color-rect :min-width 40 :min-height 60))
         (box (make-instance 'hbox
                             :children (list a b c)
                             :padding-left 10 :padding-right 20
                             :padding-top 5 :padding-bottom 5
                             :spacing 7)))
    (%assert-min-size box 214 70 "hbox measure")))

(%deftest test-04-vbox-min-size
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 30))
         (b (make-instance 'color-rect :min-width 80 :min-height 20))
         (c (make-instance 'color-rect :min-width 40 :min-height 60))
         (box (make-instance 'vbox
                             :children (list a b c)
                             :padding-left 3 :padding-right 4
                             :padding-top 10 :padding-bottom 20
                             :spacing 5)))
    (%assert-min-size box 87 150 "vbox measure")))

(%deftest test-05-hbox-left-to-right-non-expanding
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 20))
         (b (make-instance 'color-rect :min-width 60 :min-height 30))
         (c (make-instance 'color-rect :min-width 40 :min-height 10))
         (box (make-instance 'hbox :children (list a b c) :spacing 10 :align-y :start))
         (root (make-instance 'window :width 300 :height 100 :child box)))
    (%assert-min-size box 170 30 "hbox no-padding min-size")
    (layout root (make-rect :x 0 :y 0 :width 300 :height 100))
    (%assert-rect a 0 0 50 20 "hbox child A")
    (%assert-rect b 60 0 60 30 "hbox child B")
    (%assert-rect c 130 0 40 10 "hbox child C")))

(%deftest test-06-vbox-top-to-bottom-non-expanding
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 20))
         (b (make-instance 'color-rect :min-width 60 :min-height 30))
         (c (make-instance 'color-rect :min-width 40 :min-height 10))
         (box (make-instance 'vbox :children (list a b c) :spacing 8 :align-x :start))
         (root (make-instance 'window :width 200 :height 300 :child box)))
    (%assert-min-size box 60 76 "vbox no-padding min-size")
    (layout root (make-rect :x 0 :y 0 :width 200 :height 300))
    (%assert-rect a 0 0 50 20 "vbox child A")
    (%assert-rect b 0 28 60 30 "vbox child B")
    (%assert-rect c 0 66 40 10 "vbox child C")))

(%deftest test-07-hbox-leftover-width-distribution
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

(%deftest test-08-vbox-leftover-height-distribution
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

(%deftest test-09-filler-pushes-siblings-no-spacing
  (let* ((left (make-instance 'color-rect :min-width 100 :min-height 40))
         (middle (make-instance 'filler :min-width 0 :min-height 0 :expand-x t :expand-y nil))
         (right (make-instance 'color-rect :min-width 100 :min-height 40))
         (box (make-instance 'hbox :children (list left middle right) :spacing 0))
         (root (make-instance 'window :width 500 :height 100 :child box)))
    (%assert-min-size box 200 40 "filler no-spacing min-size")
    (layout root (make-rect :x 0 :y 0 :width 500 :height 100))
    (%assert-rect left 0 0 100 40 "filler no-spacing left")
    (%assert-rect middle 100 0 300 0 "filler no-spacing middle")
    (%assert-rect right 400 0 100 40 "filler no-spacing right")))

(%deftest test-10-filler-pushes-siblings-with-spacing
  (let* ((left (make-instance 'color-rect :min-width 100 :min-height 40))
         (middle (make-instance 'filler :min-width 0 :min-height 0 :expand-x t :expand-y nil))
         (right (make-instance 'color-rect :min-width 100 :min-height 40))
         (box (make-instance 'hbox :children (list left middle right) :spacing 10))
         (root (make-instance 'window :width 500 :height 100 :child box)))
    (%assert-min-size box 220 40 "filler spacing min-size")
    (layout root (make-rect :x 0 :y 0 :width 500 :height 100))
    (%assert-rect left 0 0 100 40 "filler spacing left")
    (%assert-rect middle 110 0 280 0 "filler spacing middle")
    (%assert-rect right 400 0 100 40 "filler spacing right")))

(%deftest test-11-hbox-align-start
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

(%deftest test-12-hbox-align-center
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 100))
         (b (make-instance 'color-rect :min-width 50 :min-height 150))
         (c (make-instance 'color-rect :min-width 50 :min-height 50))
         (box (make-instance 'hbox :children (list a b c) :align-y :center))
         (root (make-instance 'window :width 300 :height 150 :child box)))
    (layout root (make-rect :x 0 :y 0 :width 300 :height 150))
    (%assert-rect a 0 25 50 100 "hbox align-center A")
    (%assert-rect b 50 0 50 150 "hbox align-center B")
    (%assert-rect c 100 50 50 50 "hbox align-center C")))

(%deftest test-13-hbox-align-end
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 100))
         (b (make-instance 'color-rect :min-width 50 :min-height 150))
         (c (make-instance 'color-rect :min-width 50 :min-height 50))
         (box (make-instance 'hbox :children (list a b c) :align-y :end))
         (root (make-instance 'window :width 300 :height 150 :child box)))
    (layout root (make-rect :x 0 :y 0 :width 300 :height 150))
    (%assert-rect a 0 50 50 100 "hbox align-end A")
    (%assert-rect b 50 0 50 150 "hbox align-end B")
    (%assert-rect c 100 100 50 50 "hbox align-end C")))

(%deftest test-14-vbox-align-start
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

(%deftest test-15-vbox-align-center
  (let* ((a (make-instance 'color-rect :min-width 100 :min-height 50))
         (b (make-instance 'color-rect :min-width 200 :min-height 50))
         (c (make-instance 'color-rect :min-width 50 :min-height 50))
         (box (make-instance 'vbox :children (list a b c) :align-x :center))
         (root (make-instance 'window :width 200 :height 300 :child box)))
    (layout root (make-rect :x 0 :y 0 :width 200 :height 300))
    (%assert-rect a 50 0 100 50 "vbox align-center A")
    (%assert-rect b 0 50 200 50 "vbox align-center B")
    (%assert-rect c 75 100 50 50 "vbox align-center C")))

(%deftest test-16-vbox-align-end
  (let* ((a (make-instance 'color-rect :min-width 100 :min-height 50))
         (b (make-instance 'color-rect :min-width 200 :min-height 50))
         (c (make-instance 'color-rect :min-width 50 :min-height 50))
         (box (make-instance 'vbox :children (list a b c) :align-x :end))
         (root (make-instance 'window :width 200 :height 300 :child box)))
    (layout root (make-rect :x 0 :y 0 :width 200 :height 300))
    (%assert-rect a 100 0 100 50 "vbox align-end A")
    (%assert-rect b 0 50 200 50 "vbox align-end B")
    (%assert-rect c 150 100 50 50 "vbox align-end C")))

(%deftest test-17-hbox-cross-axis-expansion
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 100 :expand-y nil))
         (b (make-instance 'color-rect :min-width 50 :min-height 20 :expand-y t))
         (box (make-instance 'hbox :children (list a b) :align-y :center))
         (root (make-instance 'window :width 300 :height 150 :child box)))
    (%assert-min-size box 100 100 "hbox cross-axis expansion min-size")
    (layout root (make-rect :x 0 :y 0 :width 300 :height 150))
    (%assert-rect a 0 25 50 100 "hbox cross-axis A")
    (%assert-rect b 50 0 50 150 "hbox cross-axis B")))

(%deftest test-18-hbox-main-and-cross-expansion
  (let* ((a (make-instance 'color-rect :min-width 100 :min-height 50 :expand-x nil :expand-y nil))
         (b (make-instance 'color-rect :min-width 50 :min-height 20 :expand-x t :expand-y t))
         (box (make-instance 'hbox :children (list a b)))
         (root (make-instance 'window :width 400 :height 200 :child box)))
    (%assert-min-size box 150 50 "hbox main/cross expansion min-size")
    (layout root (make-rect :x 0 :y 0 :width 400 :height 200))
    (%assert-rect a 0 0 100 50 "hbox main/cross A")
    (%assert-rect b 100 0 300 200 "hbox main/cross B")))

(%deftest test-19-padding-reduces-inner-area
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 30))
         (box (make-instance 'hbox
                             :children (list a)
                             :padding-left 10 :padding-right 20
                             :padding-top 5 :padding-bottom 15
                             :spacing 0 :align-y :start))
         (root (make-instance 'window :width 300 :height 200 :child box)))
    (%assert-min-size box 80 50 "hbox padding min-size")
    (layout root (make-rect :x 0 :y 0 :width 300 :height 200))
    (%assert-rect a 10 5 50 30 "hbox padding child")))

(%deftest test-20-nested-containers
  (let* ((top (make-instance 'color-rect :min-width 100 :min-height 50))
         (left (make-instance 'color-rect :min-width 50 :min-height 100))
         (right (make-instance 'color-rect :min-width 50 :min-height 50))
         (bottom (make-instance 'hbox :children (list left right) :spacing 10 :align-y :center))
         (root-box (make-instance 'vbox
                                  :children (list top bottom)
                                  :padding-left 10 :padding-right 10
                                  :padding-top 10 :padding-bottom 10
                                  :spacing 20 :align-x :start))
         (root (make-instance 'window :width 500 :height 300 :child root-box)))
    (%assert-min-size bottom 110 100 "nested bottom hbox min-size")
    (%assert-min-size root-box 130 190 "nested root vbox min-size")
    (layout root (make-rect :x 0 :y 0 :width 500 :height 300))
    (%assert-rect top 10 10 100 50 "nested top")
    (%assert-rect bottom 10 80 110 100 "nested bottom")
    (%assert-rect left 10 80 50 100 "nested bottom left")
    (%assert-rect right 70 105 50 50 "nested bottom right")))

(%deftest test-21-empty-hbox-min-size-is-padding
  (let ((box (make-instance 'hbox
                            :children nil
                            :padding-left 10 :padding-right 20
                            :padding-top 5 :padding-bottom 15
                            :spacing 0)))
    (%assert-min-size box 30 20 "empty hbox")))

(%deftest test-22-empty-vbox-min-size-is-padding
  (let ((box (make-instance 'vbox
                            :children nil
                            :padding-left 10 :padding-right 20
                            :padding-top 5 :padding-bottom 15
                            :spacing 0)))
    (%assert-min-size box 30 20 "empty vbox")))

(%deftest test-23-single-child-hbox
  (let* ((a (make-instance 'color-rect :min-width 70 :min-height 20))
         (box (make-instance 'hbox :children (list a) :align-y :center))
         (root (make-instance 'window :width 300 :height 100 :child box)))
    (%assert-min-size box 70 20 "single child hbox min-size")
    (layout root (make-rect :x 0 :y 0 :width 300 :height 100))
    (%assert-rect a 0 40 70 20 "single child hbox rect")))

(%deftest test-24-single-child-vbox
  (let* ((a (make-instance 'color-rect :min-width 70 :min-height 20))
         (box (make-instance 'vbox :children (list a) :align-x :center))
         (root (make-instance 'window :width 200 :height 300 :child box)))
    (%assert-min-size box 70 20 "single child vbox min-size")
    (layout root (make-rect :x 0 :y 0 :width 200 :height 300))
    (%assert-rect a 65 0 70 20 "single child vbox rect")))

(%deftest test-25-no-expanders-leave-extra-unassigned
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

(%deftest test-26-multiple-fillers-split-equally
  (let* ((left (make-instance 'color-rect :min-width 100 :min-height 20))
         (fill-a (make-instance 'filler :min-width 0 :min-height 0 :expand-x t :expand-y nil))
         (fill-b (make-instance 'filler :min-width 0 :min-height 0 :expand-x t :expand-y nil))
         (right (make-instance 'color-rect :min-width 100 :min-height 20))
         (box (make-instance 'hbox :children (list left fill-a fill-b right) :spacing 0))
         (root (make-instance 'window :width 500 :height 100 :child box)))
    (%assert-min-size box 200 20 "multiple fillers min-size")
    (layout root (make-rect :x 0 :y 0 :width 500 :height 100))
    (%assert-rect left 0 0 100 20 "multiple fillers left")
    (%assert-rect fill-a 100 0 150 0 "multiple fillers A")
    (%assert-rect fill-b 250 0 150 0 "multiple fillers B")
    (%assert-rect right 400 0 100 20 "multiple fillers right")))

(%deftest test-27-cross-axis-expansion-not-in-main-measure
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 20 :expand-y t))
         (b (make-instance 'color-rect :min-width 80 :min-height 30 :expand-y nil))
         (c (make-instance 'color-rect :min-width 40 :min-height 10 :expand-y t))
         (box (make-instance 'hbox
                             :children (list a b c)
                             :padding-left 10 :padding-right 20
                             :padding-top 5 :padding-bottom 5
                             :spacing 6)))
    (%assert-min-size box 212 40 "cross-axis expansion in hbox measure")
    (%assert-expand-flags box nil t "cross-axis expansion aggregate flags")))

(%deftest test-28-main-axis-expansion-not-in-cross-measure
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 20 :expand-y t))
         (b (make-instance 'color-rect :min-width 80 :min-height 30 :expand-y nil))
         (c (make-instance 'color-rect :min-width 40 :min-height 10 :expand-y t))
         (box (make-instance 'vbox
                             :children (list a b c)
                             :padding-left 3 :padding-right 4
                             :padding-top 10 :padding-bottom 20
                             :spacing 5)))
    (%assert-min-size box 87 100 "main-axis expansion in vbox measure")
    (%assert-expand-flags box nil t "main-axis expansion aggregate flags")))

(%deftest test-29-valid-layout-has-non-negative-rectangles
  (let* ((a (make-instance 'color-rect :min-width 30 :min-height 20))
         (b (make-instance 'color-rect :min-width 40 :min-height 10))
         (box (make-instance 'hbox
                             :children (list a b)
                             :padding-left 10 :padding-right 5
                             :padding-top 3 :padding-bottom 2
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

(%deftest test-30-layout-deterministic
  (let* ((top (make-instance 'color-rect :min-width 120 :min-height 40))
         (left (make-instance 'color-rect :min-width 40 :min-height 60))
         (fill (make-instance 'filler :min-width 0 :min-height 0 :expand-x t :expand-y nil))
         (right (make-instance 'color-rect :min-width 50 :min-height 30))
         (row (make-instance 'hbox
                             :children (list left fill right)
                             :padding-left 5 :padding-right 5
                             :padding-top 2 :padding-bottom 2
                             :spacing 10 :align-y :center))
         (column (make-instance 'vbox
                                :children (list top row)
                                :padding-left 7 :padding-right 7
                                :padding-top 9 :padding-bottom 9
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

(defun run-gui-layout-tests ()
  (setf *test-count* 0
        *test-failures* 0)
  (dolist (test-symbol '(test-01-window-passes-child-without-expand
                         test-02-window-expanding-child-fills
                         test-03-hbox-min-size
                         test-04-vbox-min-size
                         test-05-hbox-left-to-right-non-expanding
                         test-06-vbox-top-to-bottom-non-expanding
                         test-07-hbox-leftover-width-distribution
                         test-08-vbox-leftover-height-distribution
                         test-09-filler-pushes-siblings-no-spacing
                         test-10-filler-pushes-siblings-with-spacing
                         test-11-hbox-align-start
                         test-12-hbox-align-center
                         test-13-hbox-align-end
                         test-14-vbox-align-start
                         test-15-vbox-align-center
                         test-16-vbox-align-end
                         test-17-hbox-cross-axis-expansion
                         test-18-hbox-main-and-cross-expansion
                         test-19-padding-reduces-inner-area
                         test-20-nested-containers
                         test-21-empty-hbox-min-size-is-padding
                         test-22-empty-vbox-min-size-is-padding
                         test-23-single-child-hbox
                         test-24-single-child-vbox
                         test-25-no-expanders-leave-extra-unassigned
                         test-26-multiple-fillers-split-equally
                         test-27-cross-axis-expansion-not-in-main-measure
                         test-28-main-axis-expansion-not-in-cross-measure
                         test-29-valid-layout-has-non-negative-rectangles
                         test-30-layout-deterministic))
    (%run-test-case test-symbol))
  (format t "~%Executed ~D assertions.~%" *test-count*)
  (if (zerop *test-failures*)
      (format t "All GUI layout tests passed.~%")
      (error "GUI layout tests failed: ~D assertion(s)." *test-failures*)))
