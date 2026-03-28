(in-package :minerva.gui)

(defvar *test-count* 0)
(defvar *test-failures* 0)
(defvar *current-test-name* nil)

(defun current-test-name ()
  *current-test-name*)

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

(defun %rect-value-list (r)
  (list (rect-x r) (rect-y r) (rect-width r) (rect-height r)))

(defun %project-root ()
  (or (ignore-errors (asdf:system-source-directory "minerva"))
      (truename "./")))

(defun %font-path ()
  (namestring (merge-pathnames "minerva/assets/fonts/inconsolata.ttf" (%project-root))))

(defun %run-test-case (test-symbol)
  (let ((failures-before *test-failures*)
        (*current-test-name* test-symbol))
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
                             :margin-left 10 :margin-right 20
                             :margin-top 5 :margin-bottom 5
                             :spacing 7)))
    (%assert-min-size box 214 70 "hbox measure")))

(%deftest test-04-vbox-min-size
  (let* ((a (make-instance 'color-rect :min-width 50 :min-height 30))
         (b (make-instance 'color-rect :min-width 80 :min-height 20))
         (c (make-instance 'color-rect :min-width 40 :min-height 60))
         (box (make-instance 'vbox
                             :children (list a b c)
                             :margin-left 3 :margin-right 4
                             :margin-top 10 :margin-bottom 20
                             :spacing 5)))
    (%assert-min-size box 87 150 "vbox measure")))

(%deftest test-05-hbox-left-to-right-non-expanding
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

(%deftest test-06-vbox-top-to-bottom-non-expanding
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

(%deftest test-19-margin-reduces-inner-area
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

(%deftest test-20-nested-containers
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

(%deftest test-21-empty-hbox-min-size-is-margin
  (let ((box (make-instance 'hbox
                            :children nil
                            :margin-left 10 :margin-right 20
                            :margin-top 5 :margin-bottom 15
                            :spacing 0)))
    (%assert-min-size box 30 20 "empty hbox")))

(%deftest test-22-empty-vbox-min-size-is-margin
  (let ((box (make-instance 'vbox
                            :children nil
                            :margin-left 10 :margin-right 20
                            :margin-top 5 :margin-bottom 15
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
                             :margin-left 10 :margin-right 20
                             :margin-top 5 :margin-bottom 5
                             :spacing 6)))
    (%assert-min-size box 212 40 "cross-axis expansion in hbox measure")
                (%assert-expand-flags box nil nil "cross-axis expansion does not propagate upward")))

(%deftest test-28-main-axis-expansion-not-in-cross-measure
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

(%deftest test-29-valid-layout-has-non-negative-rectangles
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

(%deftest test-30-layout-deterministic
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

(%deftest test-31-image-min-size-from-surface
  (let ((img (make-instance 'image :surface '(:width 64 :height 48))))
    (%assert-min-size img 64 48 "image min-size from surface")))

(%deftest test-32-image-alignment-and-clipping
  (let* ((img (make-instance 'image
                             :surface '(:width 80 :height 40)
                             :alignment :center))
         (root (make-instance 'window :width 120 :height 60 :child img)))
    (layout root (make-rect :x 0 :y 0 :width 120 :height 60))
    (%assert-rect img 20 10 80 40 "image widget layout rect")
    (%assert-equal (let ((r (image-draw-rect img)))
             (list (rect-x r) (rect-y r) (rect-width r) (rect-height r)))
                   '(20 10 80 40)
                   "image draw rect equals native size when no clipping")
    (layout img (make-rect :x 0 :y 0 :width 30 :height 20))
    (%assert-equal (let ((r (image-draw-rect img)))
             (list (rect-x r) (rect-y r) (rect-width r) (rect-height r)))
                   '(0 0 30 20)
                   "image draw rect clipped when allocated smaller")))

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

(%deftest test-34-nine-patch-child-layout-uses-center-rect
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

(%deftest test-35-image-clips-when-smaller-than-surface
  (let ((img (make-instance 'image :surface '(:width 20 :height 20))))
    (layout img (make-rect :x 0 :y 0 :width 5 :height 5))
    (%assert-equal (%rect-value-list (image-draw-rect img)) '(0 0 5 5) "image clipped draw rect")))

(%deftest test-36-image-default-alignment-top-left
  (let ((img (make-instance 'image :surface '(:width 20 :height 10))))
    (layout img (make-rect :x 100 :y 50 :width 100 :height 100))
    (%assert-equal (%rect-value-list (image-draw-rect img)) '(100 50 20 10) "default top-left alignment")))

(%deftest test-37-image-center-alignment
  (let ((img (make-instance 'image :surface '(:width 20 :height 10) :alignment :center)))
    (layout img (make-rect :x 0 :y 0 :width 100 :height 60))
    (%assert-equal (%rect-value-list (image-draw-rect img)) '(40 25 20 10) "center alignment")))

(%deftest test-38-image-top-right-alignment
  (let ((img (make-instance 'image :surface '(:width 20 :height 10) :alignment :top-right)))
    (layout img (make-rect :x 0 :y 0 :width 100 :height 60))
    (%assert-equal (%rect-value-list (image-draw-rect img)) '(80 0 20 10) "top-right alignment")))

(%deftest test-39-image-bottom-left-alignment
  (let ((img (make-instance 'image :surface '(:width 20 :height 10) :alignment :bottom-left)))
    (layout img (make-rect :x 0 :y 0 :width 100 :height 60))
    (%assert-equal (%rect-value-list (image-draw-rect img)) '(0 50 20 10) "bottom-left alignment")))

(%deftest test-40-image-bottom-right-alignment
  (let ((img (make-instance 'image :surface '(:width 20 :height 10) :alignment :bottom-right)))
    (layout img (make-rect :x 0 :y 0 :width 100 :height 60))
    (%assert-equal (%rect-value-list (image-draw-rect img)) '(80 50 20 10) "bottom-right alignment")))

(%deftest test-68-image-top-center-alignment
  (let ((img (make-instance 'image :surface '(:width 20 :height 10) :alignment :top-center)))
    (layout img (make-rect :x 0 :y 0 :width 100 :height 60))
    (%assert-equal (%rect-value-list (image-draw-rect img)) '(40 0 20 10) "top-center alignment")))

(%deftest test-69-image-bottom-center-alignment
  (let ((img (make-instance 'image :surface '(:width 20 :height 10) :alignment :bottom-center)))
    (layout img (make-rect :x 0 :y 0 :width 100 :height 60))
    (%assert-equal (%rect-value-list (image-draw-rect img)) '(40 50 20 10) "bottom-center alignment")))

(%deftest test-70-image-left-alignment
  (let ((img (make-instance 'image :surface '(:width 20 :height 10) :alignment :left)))
    (layout img (make-rect :x 0 :y 0 :width 100 :height 60))
    (%assert-equal (%rect-value-list (image-draw-rect img)) '(0 25 20 10) "left alignment")))

(%deftest test-71-image-right-alignment
  (let ((img (make-instance 'image :surface '(:width 20 :height 10) :alignment :right)))
    (layout img (make-rect :x 0 :y 0 :width 100 :height 60))
    (%assert-equal (%rect-value-list (image-draw-rect img)) '(80 25 20 10) "right alignment")))

(%deftest test-72-widget-margins-affect-min-size-and-layout
  (let* ((child (make-instance 'color-rect
                               :min-width 50
                               :min-height 30
                               :margin-left 10
                               :margin-right 20
                               :margin-top 5
                               :margin-bottom 7))
         (box (make-instance 'hbox :children (list child) :spacing 0 :align-y :start))
         (root (make-instance 'window :width 120 :height 80 :child box)))
    (%assert-min-size child 80 42 "leaf margin min-size")
    (%assert-min-size box 80 42 "hbox includes child margin min-size")
    (layout root (make-rect :x 0 :y 0 :width 120 :height 80))
    (%assert-rect child 10 5 50 30 "leaf margin shrinks allocated rect")))

(%deftest test-73-container-margins-affect-min-size-and-child-placement
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

(%deftest test-75-hbox-expanding-wrappers-equal-space-with-different-margin
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

(%deftest test-76-vbox-expanding-wrappers-equal-space-with-different-margin
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

(%deftest test-41-nine-patch-min-size-no-child-borders-only
  (let ((panel (make-instance 'nine-patch
                              :surface '(:width 20 :height 20)
                              :border-left 3 :border-right 4 :border-top 5 :border-bottom 6)))
    (%assert-min-size panel 7 11 "nine-patch no child min-size")))

(%deftest test-42-nine-patch-min-size-includes-child
  (let* ((child (make-instance 'color-rect :min-width 100 :min-height 50))
         (panel (make-instance 'nine-patch
                               :surface '(:width 20 :height 20)
                               :border-left 3 :border-right 4 :border-top 5 :border-bottom 6
                               :child child)))
    (%assert-min-size panel 107 61 "nine-patch with child min-size")))

(%deftest test-43-nine-patch-min-size-updates-with-child-change
  (let* ((small (make-instance 'color-rect :min-width 10 :min-height 10))
         (large (make-instance 'color-rect :min-width 30 :min-height 40))
         (panel (make-instance 'nine-patch
                               :surface '(:width 20 :height 20)
                               :border-left 2 :border-right 3 :border-top 4 :border-bottom 5
                               :child small)))
    (%assert-min-size panel 15 19 "nine-patch with small child")
    (setf (nine-patch-child panel) large)
    (%assert-min-size panel 35 49 "nine-patch with large child")))

(%deftest test-44-nine-patch-child-layout-center-area
  (let* ((child (make-instance 'color-rect :min-width 1 :min-height 1 :expand-x t :expand-y t))
         (panel (make-instance 'nine-patch
                               :surface '(:width 20 :height 20)
                               :border-left 10 :border-right 20 :border-top 5 :border-bottom 15
                               :child child)))
    (layout panel (make-rect :x 100 :y 50 :width 200 :height 100))
    (%assert-rect child 110 55 170 80 "nine-patch child center layout")))

(%deftest test-45-nine-patch-no-child-layout-safe
  (let ((panel (make-instance 'nine-patch
                              :surface '(:width 20 :height 20)
                              :border-left 2 :border-right 2 :border-top 2 :border-bottom 2)))
    (layout panel (make-rect :x 0 :y 0 :width 40 :height 30))
    (%assert-equal (%rect-value-list (nine-patch-content-rect panel)) '(2 2 36 26) "nine-patch no child content rect")))

(%deftest test-46-nine-patch-nested-child-layout
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

(%deftest test-47-nine-patch-corners-fixed-size
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

(%deftest test-48-nine-patch-top-bottom-edges-stretch-horizontally
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

(%deftest test-49-nine-patch-left-right-edges-stretch-vertically
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

(%deftest test-50-nine-patch-center-stretches
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

(%deftest test-51-nine-patch-small-output-clips-safely
  (let ((panel (make-instance 'nine-patch :surface '(:width 20 :height 20)
                              :border-left 10 :border-right 10 :border-top 10 :border-bottom 10)))
    (layout panel (make-rect :x 0 :y 0 :width 5 :height 5))
    (%assert-equal (%rect-value-list (nine-patch-content-rect panel)) '(10 10 0 0) "small output clipped content area")))

(%deftest test-52-nine-patch-renders-before-child
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

(%deftest test-53-child-confined-to-content-area
  (let* ((child (make-instance 'color-rect :min-width 100 :min-height 100 :expand-x t :expand-y t))
         (panel (make-instance 'nine-patch :surface '(:width 20 :height 20)
                               :border-left 4 :border-right 4 :border-top 3 :border-bottom 3
                               :child child)))
    (layout panel (make-rect :x 10 :y 10 :width 30 :height 20))
    (%assert-equal (%rect-value-list (widget-layout-rect child)) '(14 13 22 14) "child confined to center rect")))

(%deftest test-54-image-inside-nine-patch-min-size
  (let* ((img (make-instance 'image :surface '(:width 20 :height 10)))
         (panel (make-instance 'nine-patch :surface '(:width 20 :height 20)
                               :border-left 3 :border-right 4 :border-top 5 :border-bottom 6
                               :child img)))
    (%assert-min-size panel 27 21 "image + borders minimum size")))

(%deftest test-74-nine-patch-256-image-min-size-is-288
  (let* ((img (make-instance 'image :surface '(:width 256 :height 256)))
         (panel (make-instance 'nine-patch :surface '(:width 48 :height 48)
                               :border-left 16 :border-right 16
                               :border-top 16 :border-bottom 16
                               :child img)))
    (%assert-min-size panel 288 288 "nine-patch + 256 image min-size")))

(%deftest test-55-rendered-text-surface-wraps-in-image-widget
  (let* ((gfx-pkg (find-package :minerva.gfx))
         (init (and gfx-pkg (find-symbol "INIT-BACKEND" gfx-pkg)))
         (shutdown (and gfx-pkg (find-symbol "SHUTDOWN-BACKEND" gfx-pkg)))
         (get-font (and gfx-pkg (find-symbol "GET-FONT" gfx-pkg)))
         (destroy-font (and gfx-pkg (find-symbol "DESTROY-FONT" gfx-pkg)))
         (measure-text (and gfx-pkg (find-symbol "MEASURE-TEXT" gfx-pkg)))
         (render-text (and gfx-pkg (find-symbol "RENDER-TEXT-TO-SURFACE" gfx-pkg)))
         (make-color-gfx (and gfx-pkg (find-symbol "MAKE-COLOR" gfx-pkg)))
         (font nil)
         (surface nil))
    (unless (and init shutdown get-font destroy-font measure-text render-text make-color-gfx)
      (error "Required minerva.gfx API not available for integration test"))
    (unwind-protect
         (progn
           (funcall (symbol-function init))
           (setf font (funcall (symbol-function get-font)
                               (%font-path)
                               16))
           (multiple-value-bind (w h) (funcall (symbol-function measure-text) font "Hello")
             (setf surface (funcall (symbol-function render-text) font "Hello"
                                    (funcall (symbol-function make-color-gfx) :r 255 :g 255 :b 255 :a 255)))
             (let ((img (make-instance 'image :surface surface)))
               (%assert-min-size img w h "image min-size matches rendered text"))))
      (when font
        (ignore-errors (funcall (symbol-function destroy-font) font)))
      (when (and shutdown (symbol-function shutdown))
        (ignore-errors (funcall (symbol-function shutdown)))))))

(%deftest test-56-nine-patch-containing-text-image-layout
  (let ((img (make-instance 'image :surface '(:width 40 :height 12)))
        (panel nil))
    (setf panel (make-instance 'nine-patch :surface '(:width 20 :height 20)
                               :border-left 3 :border-right 3 :border-top 3 :border-bottom 3
                               :child img))
    (layout panel (make-rect :x 0 :y 0 :width 80 :height 40))
    (%assert-equal (%rect-value-list (widget-layout-rect img)) '(3 3 74 34) "text-image child center placement")))

(%deftest test-57-hbox-with-images-and-filler
  (let* ((left (make-instance 'image :surface '(:width 20 :height 10)))
         (fill (make-instance 'filler :min-width 0 :min-height 0 :expand-x t :expand-y nil))
         (right (make-instance 'image :surface '(:width 30 :height 10)))
         (row (make-instance 'hbox :children (list left fill right) :spacing 0))
         (root (make-instance 'window :width 200 :height 40 :child row)))
    (layout root (make-rect :x 0 :y 0 :width 200 :height 40))
    (%assert-equal (rect-width (widget-layout-rect left)) 20 "left image keeps native width")
    (%assert-equal (rect-width (widget-layout-rect right)) 30 "right image keeps native width")
    (%assert-equal (rect-width (widget-layout-rect fill)) 150 "filler absorbs extra width")))

(%deftest test-58-window-centers-image-child
  (let* ((img (make-instance 'image
                             :surface '(:width 20 :height 10)
                             :alignment :center))
         (root (make-instance 'window :width 100 :height 60 :child img)))
    (layout root (make-rect :x 0 :y 0 :width 100 :height 60))
    (%assert-equal (%rect-value-list (image-draw-rect img))
                   '(40 25 20 10)
                   "window child image draw rect is centered")))

(%deftest test-59-window-centers-color-rect-child
  (let* ((child (make-instance 'color-rect
                               :min-width 20
                               :min-height 10
                               :expand-x nil
                               :expand-y nil
                               :alignment :center))
         (root (make-instance 'window :width 100 :height 60 :child child)))
    (layout root (make-rect :x 0 :y 0 :width 100 :height 60))
    (%assert-rect child 40 25 20 10 "window child color-rect is centered")))

(%deftest test-60-window-hbox-image-centers-like-direct-image
  (let* ((img (make-instance 'image
                             :surface '(:width 20 :height 10)
                             :alignment :center))
         (row (make-instance 'hbox
                             :children (list img)
                             :alignment :center))
         (root (make-instance 'window :width 100 :height 60 :child row)))
    (layout root (make-rect :x 0 :y 0 :width 100 :height 60))
    (%assert-equal (%rect-value-list (image-draw-rect img))
                   '(40 25 20 10)
                   "window->hbox->image is centered in same location")))

(%deftest test-65-expand-does-not-change-min-size
  (let* ((fixed (make-instance 'color-rect :min-width 40 :min-height 10 :expand-x nil :expand-y nil))
         (expanding (make-instance 'color-rect :min-width 40 :min-height 10 :expand-x t :expand-y nil))
         (fixed-box (make-instance 'hbox :children (list fixed)))
         (expanding-box (make-instance 'hbox :children (list expanding))))
    (%assert-min-size fixed-box 40 10 "fixed child min-size")
    (%assert-min-size expanding-box 40 10 "expanding child same min-size")
    (%assert-expand-flags fixed-box nil nil "fixed child does not propagate expand")
    (%assert-expand-flags expanding-box nil nil "expanding child does not propagate eligibility")))

(%deftest test-66-expand-does-not-force-upward-through-window
  (let* ((child (make-instance 'color-rect :min-width 30 :min-height 12 :expand-x t :expand-y t))
         (root (make-instance 'window :width 200 :height 100 :child child))
         (request (measure root)))
    (%assert-equal (size-request-min-width request) 30 "window min-width unchanged by child expand")
    (%assert-equal (size-request-min-height request) 12 "window min-height unchanged by child expand")
    (%assert-equal (size-request-expand-x request) nil "window does not force expand upward x")
    (%assert-equal (size-request-expand-y request) nil "window does not force expand upward y")))

(%deftest test-67-container-expand-is-parent-level-eligibility
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

(%deftest test-77-container-expands-only-when-explicitly-set
  (let* ((left-leaf (make-instance 'color-rect :min-width 20 :min-height 10 :expand-x nil :expand-y nil))
         (right-leaf (make-instance 'color-rect :min-width 20 :min-height 10 :expand-x t :expand-y nil))
         (left-box (make-instance 'hbox :children (list left-leaf) :expand-x nil))
         (right-box (make-instance 'hbox :children (list right-leaf) :expand-x t))
         (parent (make-instance 'hbox :children (list left-box right-box) :spacing 0))
         (root (make-instance 'window :width 100 :height 20 :child parent)))
    (layout root (make-rect :x 0 :y 0 :width 100 :height 20))
    (%assert-rect left-box 0 0 20 10 "non-expanding container keeps min width")
    (%assert-rect right-box 20 0 80 10 "container expands only when explicitly set")))

(%deftest test-63-nine-patch-layout-deterministic
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

(%deftest test-64-image-render-deterministic
  (let* ((img (make-instance 'image :surface '(:width 20 :height 10) :alignment :center))
         (calls-a '())
         (calls-b '())
         (old (symbol-function 'minerva.gui::%call-draw-surface-rect)))
    (unwind-protect
         (progn
           (layout img (make-rect :x 0 :y 0 :width 100 :height 60))
           (setf (symbol-function 'minerva.gui::%call-draw-surface-rect)
                 (lambda (backend-window surface source-rect dest-x dest-y)
                   (declare (ignore backend-window surface))
                   (push (list (%rect-value-list source-rect) dest-x dest-y) calls-a)))
           (render img nil)
           (setf (symbol-function 'minerva.gui::%call-draw-surface-rect)
                 (lambda (backend-window surface source-rect dest-x dest-y)
                   (declare (ignore backend-window surface))
                   (push (list (%rect-value-list source-rect) dest-x dest-y) calls-b)))
           (render img nil))
      (setf (symbol-function 'minerva.gui::%call-draw-surface-rect) old))
    (%assert-equal calls-a calls-b "image render deterministic draw calls")))

(%deftest test-78-widget-background-color-fills-consumed-area-including-margins
  (let* ((calls '())
         (img (make-instance 'image
                             :surface '(:width 5 :height 5)
                             :background-color (minerva.common:make-color :r 10 :g 20 :b 30 :a 40)
                             :margin-left 3 :margin-right 4 :margin-top 5 :margin-bottom 6))
         (old-fill (symbol-function 'minerva.gui::%call-fill-rect))
         (old-draw (symbol-function 'minerva.gui::%call-draw-surface-rect)))
    (unwind-protect
         (progn
           (setf (symbol-function 'minerva.gui::%call-fill-rect)
                 (lambda (backend-window rect color)
                   (declare (ignore backend-window))
                   (push (list :fill (%rect-value-list rect) color) calls)))
           (setf (symbol-function 'minerva.gui::%call-draw-surface-rect)
                 (lambda (&rest args)
                   (declare (ignore args))
                   (push (list :draw) calls)))
           (layout img (make-rect :x 10 :y 20 :width 30 :height 40))
           (render img nil))
      (setf (symbol-function 'minerva.gui::%call-fill-rect) old-fill)
      (setf (symbol-function 'minerva.gui::%call-draw-surface-rect) old-draw))
    (%assert-equal (second (first (last calls))) '(10 20 30 40) "background covers consumed area including margins")
    (%assert-equal (first (car calls)) :draw "image draws after background fill")))

(%deftest test-79-widget-background-color-nil-does-not-fill
  (let* ((fill-count 0)
         (rect-widget (make-instance 'color-rect :min-width 10 :min-height 10 :color '(1 2 3 255)))
         (old-fill (symbol-function 'minerva.gui::%call-fill-rect)))
    (unwind-protect
         (progn
           (setf (symbol-function 'minerva.gui::%call-fill-rect)
                 (lambda (&rest args)
                   (declare (ignore args))
                   (incf fill-count)))
           (layout rect-widget (make-rect :x 0 :y 0 :width 10 :height 10))
           (render rect-widget nil))
      (setf (symbol-function 'minerva.gui::%call-fill-rect) old-fill))
    (%assert-equal fill-count 1 "only widget draw fill called when background-color is nil")))

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
                         test-19-margin-reduces-inner-area
                         test-20-nested-containers
                         test-21-empty-hbox-min-size-is-margin
                         test-22-empty-vbox-min-size-is-margin
                         test-23-single-child-hbox
                         test-24-single-child-vbox
                         test-25-no-expanders-leave-extra-unassigned
                         test-26-multiple-fillers-split-equally
                         test-27-cross-axis-expansion-not-in-main-measure
                         test-28-main-axis-expansion-not-in-cross-measure
                         test-29-valid-layout-has-non-negative-rectangles
                         test-30-layout-deterministic
                         test-31-image-min-size-from-surface
                         test-32-image-alignment-and-clipping
                         test-33-nine-patch-min-size-includes-child-and-borders
                         test-34-nine-patch-child-layout-uses-center-rect
                         test-35-image-clips-when-smaller-than-surface
                         test-36-image-default-alignment-top-left
                         test-37-image-center-alignment
                         test-38-image-top-right-alignment
                         test-39-image-bottom-left-alignment
                         test-40-image-bottom-right-alignment
                         test-68-image-top-center-alignment
                         test-69-image-bottom-center-alignment
                         test-70-image-left-alignment
                         test-71-image-right-alignment
                         test-72-widget-margins-affect-min-size-and-layout
                         test-73-container-margins-affect-min-size-and-child-placement
                         test-75-hbox-expanding-wrappers-equal-space-with-different-margin
                         test-76-vbox-expanding-wrappers-equal-space-with-different-margin
                         test-41-nine-patch-min-size-no-child-borders-only
                         test-42-nine-patch-min-size-includes-child
                         test-43-nine-patch-min-size-updates-with-child-change
                         test-44-nine-patch-child-layout-center-area
                         test-45-nine-patch-no-child-layout-safe
                         test-46-nine-patch-nested-child-layout
                         test-47-nine-patch-corners-fixed-size
                         test-48-nine-patch-top-bottom-edges-stretch-horizontally
                         test-49-nine-patch-left-right-edges-stretch-vertically
                         test-50-nine-patch-center-stretches
                         test-51-nine-patch-small-output-clips-safely
                         test-52-nine-patch-renders-before-child
                         test-53-child-confined-to-content-area
                         test-54-image-inside-nine-patch-min-size
                         test-74-nine-patch-256-image-min-size-is-288
                         test-55-rendered-text-surface-wraps-in-image-widget
                         test-56-nine-patch-containing-text-image-layout
                         test-57-hbox-with-images-and-filler
                         test-58-window-centers-image-child
                         test-59-window-centers-color-rect-child
                         test-60-window-hbox-image-centers-like-direct-image
                         test-65-expand-does-not-change-min-size
                         test-66-expand-does-not-force-upward-through-window
                         test-67-container-expand-is-parent-level-eligibility
                         test-77-container-expands-only-when-explicitly-set
                         test-63-nine-patch-layout-deterministic
                         test-64-image-render-deterministic
                         test-78-widget-background-color-fills-consumed-area-including-margins
                         test-79-widget-background-color-nil-does-not-fill))
    (%run-test-case test-symbol))
  (format t "~%Executed ~D assertions.~%" *test-count*)
  (if (zerop *test-failures*)
      (format t "All GUI layout tests passed.~%")
      (error "GUI layout tests failed: ~D assertion(s)." *test-failures*)))
