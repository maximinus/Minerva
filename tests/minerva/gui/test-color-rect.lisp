(in-package :minerva.gui)

(%deftest test-widget-margins-affect-min-size-and-layout
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

(%deftest test-widget-background-color-nil-does-not-fill
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
