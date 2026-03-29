(in-package :minerva.gui)

(%deftest test-button-min-size-includes-padding-and-borders
  (let ((old-load (symbol-function 'minerva.gui::%button-load-surface))
        (old-render-text (symbol-function 'minerva.gui::%button-render-text-surface)))
    (unwind-protect
         (progn
           (setf (symbol-function 'minerva.gui::%button-load-surface)
                 (lambda (path)
                   (declare (ignore path))
                   '(:width 24 :height 24)))
           (setf (symbol-function 'minerva.gui::%button-render-text-surface)
                 (lambda (font-name text-size text color)
                   (declare (ignore font-name text-size text color))
                   '(:width 100 :height 20)))
           (let ((btn (make-instance 'button
                                     :text "Play"
                                     :font-name "inconsolata"
                                     :text-size 32
                                     :padding-x 10
                                     :padding-y 8)))
             (%assert-min-size btn
                               (+ 100 (* 2 10) (* 2 4))
                               (+ 20 (* 2 8) (* 2 4))
                               "button min-size includes text padding and corners")))
      (setf (symbol-function 'minerva.gui::%button-load-surface) old-load)
      (setf (symbol-function 'minerva.gui::%button-render-text-surface) old-render-text))))

(%deftest test-button-padding-size-initarg
  (let ((old-load (symbol-function 'minerva.gui::%button-load-surface))
        (old-render-text (symbol-function 'minerva.gui::%button-render-text-surface)))
    (unwind-protect
         (progn
           (setf (symbol-function 'minerva.gui::%button-load-surface)
                 (lambda (path)
                   (declare (ignore path))
                   '(:width 24 :height 24)))
           (setf (symbol-function 'minerva.gui::%button-render-text-surface)
                 (lambda (&rest args)
                   (declare (ignore args))
                   '(:width 50 :height 20)))
           (let ((btn (make-instance 'button
                                     :text "Pad"
                                     :padding (minerva.common:make-size :width 14 :height 6))))
             (%assert-equal (button-padding-x btn) 14 "button :padding size sets x padding")
             (%assert-equal (button-padding-y btn) 6 "button :padding size sets y padding"))
           (let ((btn (make-instance 'button
                                     :text "Pad"
                                     :padding (minerva.common:make-size :width 14 :height 6)
                                     :padding-x 9)))
             (%assert-equal (button-padding-x btn) 9 "button :padding-x overrides :padding width")
             (%assert-equal (button-padding-y btn) 6 "button :padding height remains from size")))
      (setf (symbol-function 'minerva.gui::%button-load-surface) old-load)
      (setf (symbol-function 'minerva.gui::%button-render-text-surface) old-render-text))))

(%deftest test-button-text-draw-rect-is-centered
  (let ((old-load (symbol-function 'minerva.gui::%button-load-surface))
        (old-render-text (symbol-function 'minerva.gui::%button-render-text-surface)))
    (unwind-protect
         (progn
           (setf (symbol-function 'minerva.gui::%button-load-surface)
                 (lambda (path)
                   (declare (ignore path))
                   '(:width 24 :height 24)))
           (setf (symbol-function 'minerva.gui::%button-render-text-surface)
                 (lambda (&rest args)
                   (declare (ignore args))
                   '(:width 40 :height 20)))
           (let ((btn (make-instance 'button :text "OK" :padding-x 0 :padding-y 0)))
             (layout btn (make-rect :x 0 :y 0 :width 120 :height 80))
             (%assert-equal (%rect-value-list (button-text-draw-rect btn))
                            '(40 30 40 20)
                            "button text draw rect centered")))
      (setf (symbol-function 'minerva.gui::%button-load-surface) old-load)
      (setf (symbol-function 'minerva.gui::%button-render-text-surface) old-render-text))))

(%deftest test-button-state-transitions
  (let ((old-load (symbol-function 'minerva.gui::%button-load-surface))
        (old-render-text (symbol-function 'minerva.gui::%button-render-text-surface)))
    (unwind-protect
         (progn
           (setf (symbol-function 'minerva.gui::%button-load-surface)
                 (lambda (path)
                   (declare (ignore path))
                   '(:width 24 :height 24)))
           (setf (symbol-function 'minerva.gui::%button-render-text-surface)
                 (lambda (&rest args)
                   (declare (ignore args))
                   '(:width 20 :height 12)))
           (let ((btn (make-instance 'button :text "Go")))
             (layout btn (make-rect :x 10 :y 10 :width 100 :height 50))
             (handle-event btn nil '(:mouse-move :x 20 :y 20))
             (%assert-equal (button-state btn) :highlighted "button becomes highlighted on hover")
             (handle-event btn nil '(:mouse-down :button :left :x 20 :y 20))
             (%assert-equal (button-state btn) :pressed "button becomes pressed on mouse down")
             (handle-event btn nil '(:mouse-up :button :left :x 20 :y 20))
             (%assert-equal (button-state btn) :highlighted "button returns to highlighted on mouse up inside")
             (handle-event btn nil '(:mouse-move :x 500 :y 500))
             (%assert-equal (button-state btn) :normal "button returns to normal when pointer leaves")))
      (setf (symbol-function 'minerva.gui::%button-load-surface) old-load)
      (setf (symbol-function 'minerva.gui::%button-render-text-surface) old-render-text))))

(%deftest test-button-render-uses-state-specific-surface
  (let ((old-load (symbol-function 'minerva.gui::%button-load-surface))
        (old-render-text (symbol-function 'minerva.gui::%button-render-text-surface))
        (old-nine (symbol-function 'minerva.gui::%render-nine-patch-part))
  (old-draw-text (symbol-function 'minerva.gui::%call-draw-surface-rect))
        (captured-surface nil))
    (unwind-protect
         (progn
           (setf (symbol-function 'minerva.gui::%button-load-surface)
                 (lambda (path)
                   (cond
                     ((search "button_normal" path) '(:id :normal :width 24 :height 24))
                     ((search "button_highlight" path) '(:id :highlighted :width 24 :height 24))
                     ((search "button_pressed" path) '(:id :pressed :width 24 :height 24))
                     (t '(:id :unknown :width 24 :height 24)))))
           (setf (symbol-function 'minerva.gui::%button-render-text-surface)
                 (lambda (&rest args)
                   (declare (ignore args))
                   '(:width 20 :height 12)))
           (setf (symbol-function 'minerva.gui::%render-nine-patch-part)
                 (lambda (backend-window surface src-position src-size dst-position dst-size)
                   (declare (ignore backend-window src-position src-size dst-position dst-size))
                   (unless captured-surface
                     (setf captured-surface surface))))
           (setf (symbol-function 'minerva.gui::%call-draw-surface-rect)
                 (lambda (&rest args)
                   (declare (ignore args))
                   nil))
           (let ((btn (make-instance 'button :text "Go" :state :pressed)))
             (layout btn (make-rect :x 0 :y 0 :width 80 :height 40))
             (render btn nil)
             (%assert-equal (getf captured-surface :id) :pressed
                            "button uses pressed 9-patch in pressed state")))
      (setf (symbol-function 'minerva.gui::%button-load-surface) old-load)
      (setf (symbol-function 'minerva.gui::%button-render-text-surface) old-render-text)
      (setf (symbol-function 'minerva.gui::%render-nine-patch-part) old-nine)
      (setf (symbol-function 'minerva.gui::%call-draw-surface-rect) old-draw-text))))
