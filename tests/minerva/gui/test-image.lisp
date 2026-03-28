(in-package :minerva.gui)

(%deftest test-image-min-size-from-surface
  (let ((img (make-instance 'image :surface '(:width 64 :height 48))))
    (%assert-min-size img 64 48 "image min-size from surface")))

(%deftest test-image-alignment-and-clipping
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

(%deftest test-image-clips-when-smaller-than-surface
  (let ((img (make-instance 'image :surface '(:width 20 :height 20))))
    (layout img (make-rect :x 0 :y 0 :width 5 :height 5))
    (%assert-equal (%rect-value-list (image-draw-rect img)) '(0 0 5 5) "image clipped draw rect")))

(%deftest test-image-default-alignment-top-left
  (let ((img (make-instance 'image :surface '(:width 20 :height 10))))
    (layout img (make-rect :x 100 :y 50 :width 100 :height 100))
    (%assert-equal (%rect-value-list (image-draw-rect img)) '(100 50 20 10) "default top-left alignment")))

(%deftest test-image-center-alignment
  (let ((img (make-instance 'image :surface '(:width 20 :height 10) :alignment :center)))
    (layout img (make-rect :x 0 :y 0 :width 100 :height 60))
    (%assert-equal (%rect-value-list (image-draw-rect img)) '(40 25 20 10) "center alignment")))

(%deftest test-image-top-right-alignment
  (let ((img (make-instance 'image :surface '(:width 20 :height 10) :alignment :top-right)))
    (layout img (make-rect :x 0 :y 0 :width 100 :height 60))
    (%assert-equal (%rect-value-list (image-draw-rect img)) '(80 0 20 10) "top-right alignment")))

(%deftest test-image-bottom-left-alignment
  (let ((img (make-instance 'image :surface '(:width 20 :height 10) :alignment :bottom-left)))
    (layout img (make-rect :x 0 :y 0 :width 100 :height 60))
    (%assert-equal (%rect-value-list (image-draw-rect img)) '(0 50 20 10) "bottom-left alignment")))

(%deftest test-image-bottom-right-alignment
  (let ((img (make-instance 'image :surface '(:width 20 :height 10) :alignment :bottom-right)))
    (layout img (make-rect :x 0 :y 0 :width 100 :height 60))
    (%assert-equal (%rect-value-list (image-draw-rect img)) '(80 50 20 10) "bottom-right alignment")))

(%deftest test-image-top-center-alignment
  (let ((img (make-instance 'image :surface '(:width 20 :height 10) :alignment :top-center)))
    (layout img (make-rect :x 0 :y 0 :width 100 :height 60))
    (%assert-equal (%rect-value-list (image-draw-rect img)) '(40 0 20 10) "top-center alignment")))

(%deftest test-image-bottom-center-alignment
  (let ((img (make-instance 'image :surface '(:width 20 :height 10) :alignment :bottom-center)))
    (layout img (make-rect :x 0 :y 0 :width 100 :height 60))
    (%assert-equal (%rect-value-list (image-draw-rect img)) '(40 50 20 10) "bottom-center alignment")))

(%deftest test-image-left-alignment
  (let ((img (make-instance 'image :surface '(:width 20 :height 10) :alignment :left)))
    (layout img (make-rect :x 0 :y 0 :width 100 :height 60))
    (%assert-equal (%rect-value-list (image-draw-rect img)) '(0 25 20 10) "left alignment")))

(%deftest test-image-right-alignment
  (let ((img (make-instance 'image :surface '(:width 20 :height 10) :alignment :right)))
    (layout img (make-rect :x 0 :y 0 :width 100 :height 60))
    (%assert-equal (%rect-value-list (image-draw-rect img)) '(80 25 20 10) "right alignment")))

(%deftest test-rendered-text-surface-wraps-in-image-widget
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

(%deftest test-image-render-deterministic
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

(%deftest test-widget-background-color-fills-consumed-area-including-margins
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
