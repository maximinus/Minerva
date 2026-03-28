(in-package :minerva.gui)

(%deftest test-window-passes-child-without-expand
  (let* ((child (make-instance 'color-rect :min-width 100 :min-height 50 :expand-x nil :expand-y nil))
         (root (make-instance 'window :width 800 :height 600 :child child)))
    (%assert-min-size root 100 50 "window with fixed child")
    (layout root (make-rect :x 0 :y 0 :width 800 :height 600))
    (%assert-rect child 0 0 100 50 "window fixed child final rect")))

(%deftest test-window-expanding-child-fills
  (let* ((child (make-instance 'color-rect :min-width 100 :min-height 50 :expand-x t :expand-y t))
         (root (make-instance 'window :width 800 :height 600 :child child)))
    (%assert-min-size root 100 50 "window with expanding child")
    (%assert-expand-flags child t t "expanding child flags")
    (layout root (make-rect :x 0 :y 0 :width 800 :height 600))
    (%assert-rect child 0 0 800 600 "window expanding child final rect")))

(%deftest test-window-centers-image-child
  (let* ((img (make-instance 'image
                             :surface '(:width 20 :height 10)
                             :alignment :center))
         (root (make-instance 'window :width 100 :height 60 :child img)))
    (layout root (make-rect :x 0 :y 0 :width 100 :height 60))
    (%assert-equal (%rect-value-list (image-draw-rect img))
                   '(40 25 20 10)
                   "window child image draw rect is centered")))

(%deftest test-window-centers-color-rect-child
  (let* ((child (make-instance 'color-rect
                               :min-width 20
                               :min-height 10
                               :expand-x nil
                               :expand-y nil
                               :alignment :center))
         (root (make-instance 'window :width 100 :height 60 :child child)))
    (layout root (make-rect :x 0 :y 0 :width 100 :height 60))
    (%assert-rect child 40 25 20 10 "window child color-rect is centered")))

(%deftest test-window-hbox-image-centers-like-direct-image
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

(%deftest test-expand-does-not-force-upward-through-window
  (let* ((child (make-instance 'color-rect :min-width 30 :min-height 12 :expand-x t :expand-y t))
         (root (make-instance 'window :width 200 :height 100 :child child))
         (request (measure root)))
    (%assert-equal (size-request-min-width request) 30 "window min-width unchanged by child expand")
    (%assert-equal (size-request-min-height request) 12 "window min-height unchanged by child expand")
    (%assert-equal (size-request-expand-x request) nil "window does not force expand upward x")
    (%assert-equal (size-request-expand-y request) nil "window does not force expand upward y")))
