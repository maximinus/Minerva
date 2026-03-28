(in-package :minerva.gui)

(%deftest test-label-measure-uses-rendered-surface-size
  (let ((old (symbol-function 'minerva.gui::%render-label-text-surface)))
    (unwind-protect
         (progn
           (setf (symbol-function 'minerva.gui::%render-label-text-surface)
                 (lambda (&rest args)
                   (declare (ignore args))
                   '(:width 72 :height 19)))
           (let ((lbl (make-instance 'label
                                     :text "Hello"
                                     :font-name "inconsolata"
                                     :text-size 16)))
             (%assert-min-size lbl 72 19 "label min-size from rendered surface")))
      (setf (symbol-function 'minerva.gui::%render-label-text-surface) old))))

(%deftest test-label-default-color-is-black
  (let ((captured-color nil)
        (old (symbol-function 'minerva.gui::%render-label-text-surface)))
    (unwind-protect
         (progn
           (setf (symbol-function 'minerva.gui::%render-label-text-surface)
                 (lambda (font-name text-size text color)
                   (declare (ignore font-name text-size text))
                   (setf captured-color color)
                   '(:width 1 :height 1)))
           (make-instance 'label :text "A" :font-name "inconsolata" :text-size 12)
           (%assert-equal captured-color '(0 0 0 255) "label default color black"))
      (setf (symbol-function 'minerva.gui::%render-label-text-surface) old))))

(%deftest test-label-font-name-resolves-to-project-assets
  (let ((path (minerva.gui::%label-font-path "inconsolata")))
    (%assert-equal (not (null (search "/minerva/assets/fonts/inconsolata.ttf" path))) t
                   "label font name resolves to project font path")))

(%deftest test-label-explicit-font-path-preserved
  (let ((path (minerva.gui::%label-font-path "/tmp/custom-font.ttf")))
    (%assert-equal path "/tmp/custom-font.ttf"
                   "label explicit font path preserved")))

(%deftest test-label-render-draws-clipped-surface
  (let* ((draw-calls '())
         (old-render-surface (symbol-function 'minerva.gui::%render-label-text-surface))
         (old-draw (symbol-function 'minerva.gui::%call-draw-surface-rect))
         (lbl nil))
    (unwind-protect
         (progn
           (setf (symbol-function 'minerva.gui::%render-label-text-surface)
                 (lambda (&rest args)
                   (declare (ignore args))
                   '(:width 40 :height 20)))
           (setf (symbol-function 'minerva.gui::%call-draw-surface-rect)
                 (lambda (backend-window surface source-rect dest-x dest-y)
                   (declare (ignore backend-window surface))
                   (push (list (%rect-value-list source-rect) dest-x dest-y) draw-calls)))
           (setf lbl (make-instance 'label
                                    :text "Hello"
                                    :font-name "inconsolata"
                                    :text-size 16
                                    :alignment :center))
           (layout lbl (make-rect :x 0 :y 0 :width 10 :height 10))
           (render lbl nil)
           (%assert-equal draw-calls
                          '(((15 5 10 10) 0 0))
                          "label render clips to allocated rect"))
      (setf (symbol-function 'minerva.gui::%render-label-text-surface) old-render-surface)
      (setf (symbol-function 'minerva.gui::%call-draw-surface-rect) old-draw))))
