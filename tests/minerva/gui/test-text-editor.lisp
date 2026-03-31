(in-package :minerva.gui)

(defun %editor-click-inside-point (editor)
  (let ((rect (widget-layout-rect editor)))
    (list (+ (rect-x rect) 2)
          (+ (rect-y rect) 2))))

(%deftest test-text-editor-initial-state
  (let ((editor (make-instance 'text-editor)))
    (%assert-equal (text-editor-text editor) "" "editor text defaults to empty")
    (%assert-equal (text-editor-caret-position editor) 0 "editor caret defaults to 0")
    (%assert-equal (text-editor-focused-p editor) nil "editor starts unfocused")
    (%assert-equal (text-editor-caret-visible-p editor) nil "caret hidden when unfocused")))

(%deftest test-text-editor-focus-click
  (let* ((editor (make-instance 'text-editor))
         (root (make-instance 'window :width 320 :height 80 :child editor))
         (state (minerva.events:make-app-state :root root)))
    (layout root (make-rect :x 0 :y 0 :width 320 :height 80))
    (setf (minerva.events:app-state-needs-redraw state) nil)
    (let ((point (%editor-click-inside-point editor)))
      (minerva.events:process-minerva-event state
                                            (list :mouse-down :button :left
                                                  :x (first point)
                                                  :y (second point))))
    (%assert-equal (minerva.events:app-state-focused-widget state)
                   editor
                   "clicking editor gives it focus")
    (%assert-equal (text-editor-focused-p editor) t "focused editor tracks focused flag")
    (%assert-equal (text-editor-caret-visible-p editor) t "focus click shows caret")
    (%assert-equal (minerva.events:app-state-needs-redraw state) t "focus click requests redraw")))

(%deftest test-text-editor-inserts-text-input-at-caret
  (let* ((editor (make-instance 'text-editor))
         (root (make-instance 'window :width 320 :height 80 :child editor))
         (state (minerva.events:make-app-state :root root)))
    (layout root (make-rect :x 0 :y 0 :width 320 :height 80))
    (minerva.events:set-focused-widget state editor)
    (minerva.events:process-minerva-event state '(:text-input :text "a"))
    (%assert-equal (text-editor-text editor) "a" "first insertion appends text")
    (%assert-equal (text-editor-caret-position editor) 1 "caret advances after first insertion")
    (minerva.events:process-minerva-event state '(:text-input :text "b"))
    (%assert-equal (text-editor-text editor) "ab" "second insertion appends text")
    (%assert-equal (text-editor-caret-position editor) 2 "caret advances after second insertion")))

(%deftest test-text-editor-ignores-text-input-when-unfocused
  (let* ((editor (make-instance 'text-editor))
         (root (make-instance 'window :width 320 :height 80 :child editor))
         (state (minerva.events:make-app-state :root root)))
    (layout root (make-rect :x 0 :y 0 :width 320 :height 80))
    (minerva.events:process-minerva-event state '(:text-input :text "x"))
    (%assert-equal (text-editor-text editor) "" "unfocused editor ignores text input")
    (%assert-equal (text-editor-caret-position editor) 0 "caret does not move when unfocused")))

(%deftest test-text-editor-blink-toggle
  (let ((editor (make-instance 'text-editor :focused-p t :caret-visible-p t :last-blink-ms 0 :blink-interval-ms 500)))
    (%assert-equal (text-editor-update-blink editor 400)
                   nil
                   "blink does not toggle before interval")
    (%assert-equal (text-editor-caret-visible-p editor)
                   t
                   "caret stays visible before interval")
    (%assert-equal (text-editor-update-blink editor 600)
                   t
                   "blink toggles at interval")
    (%assert-equal (text-editor-caret-visible-p editor)
                   nil
                   "caret visibility toggles when blink fires")))

(%deftest test-text-editor-blink-resets-on-input
  (let* ((editor (make-instance 'text-editor))
     (state (minerva.events:make-app-state)))
    (minerva.events:set-focused-widget state editor)
    (setf (text-editor-caret-visible-p editor) nil
          (text-editor-last-blink-ms editor) 10)
    (handle-event editor state '(:text-input :text "z"))
    (%assert-equal (text-editor-caret-visible-p editor)
                   t
                   "typing makes caret visible again")
    (%assert-equal (/= (text-editor-last-blink-ms editor) 10)
             t
             "typing resets blink timestamp")))

(%deftest test-text-editor-caret-position-is-clamped
  (let ((editor (make-instance 'text-editor :text "ab" :caret-position 99)))
    (layout editor (make-rect :x 0 :y 0 :width 200 :height 40))
    (%assert-equal (text-editor-caret-position editor)
                   2
                   "caret is clamped to text length")
    (setf (text-editor-caret-position editor) -7)
    (layout editor (make-rect :x 0 :y 0 :width 200 :height 40))
    (%assert-equal (text-editor-caret-position editor)
                   0
                   "caret is clamped to zero lower bound")))
