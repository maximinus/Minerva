(defpackage :minerva.events.tests
  (:use :cl)
  (:import-from :minerva.gui
                :hbox
                :vbox
                :window
                :button
                :button-state
                :menu
                :menu-bar
                :menu-bar-buttons
                :menu-bar-open-index
                :menu-bar-button-state
                :color-rect
                :make-rect
                :layout
                :handle-event
                :measure
                :render
                :widget
                :widget-layout-rect
                :size-request-min-width
                :size-request-min-height
                :window-width
                :window-height)
  (:import-from :minerva.events
                :make-app-state
                :make-overlay
                :sdl-event->minerva-event
                :route-minerva-event
                :process-actions
                :process-minerva-event
                :layout-app-state
                :render-app-state
                :app-state-overlay-stack
                :push-overlay
                :pop-overlay
                :remove-overlay
                :top-overlay
                :overlay-stack-empty-p
                :overlay-rect
                :app-state-active-widget
                :app-state-should-quit
                :app-state-needs-redraw
                :app-state-last-command))

(in-package :minerva.events.tests)

(defvar *test-count* 0)
(defvar *test-failures* 0)
(defvar *current-test-name* nil)
(defvar *render-probe-events* nil)

(defmacro %deftest (name &body body)
  `(defun ,name ()
     ,@body))

(defmacro %with-stubbed-button-gfx (&body body)
  `(let ((old-load (symbol-function 'minerva.gui::%button-load-surface))
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
            ,@body)
       (setf (symbol-function 'minerva.gui::%button-load-surface) old-load)
       (setf (symbol-function 'minerva.gui::%button-render-text-surface) old-render-text))))

(defmacro %with-stubbed-menu-bar-gfx (&body body)
  `(%with-stubbed-button-gfx
     (let ((old-render (symbol-function 'minerva.gui::%render-label-text-surface))
           (old-load-default (symbol-function 'minerva.gui::%menu-load-default-panel-surface)))
       (unwind-protect
            (progn
              (setf (symbol-function 'minerva.gui::%render-label-text-surface)
                    (lambda (font-name text-size text color)
                      (declare (ignore font-name text-size color))
                      (list :width (max 1 (* 7 (length (or text ""))))
                            :height 14)))
              (setf (symbol-function 'minerva.gui::%menu-load-default-panel-surface)
                    (lambda ()
                      '(:width 48 :height 24)))
              ,@body)
         (setf (symbol-function 'minerva.gui::%render-label-text-surface) old-render)
         (setf (symbol-function 'minerva.gui::%menu-load-default-panel-surface) old-load-default)))))

(defun %menu-bar-test-state ()
  (let* ((bar (make-instance 'menu-bar
                             :entries (list '(:text "File"
                                              :items ((:text "Open" :command :open)
                                                      (:text "Save" :command :save)))
                                            '(:text "Edit"
                                              :items ((:text "Cut" :command :cut)
                                        (:text "Paste" :command :paste))))))
         (body-button (make-instance 'button :text "Body" :command :body))
         (root (make-instance 'window
                              :width 320
                              :height 200
                              :child (make-instance 'vbox
                                                    :spacing 0
                                                    :children (list bar body-button))))
         (state (make-app-state :root root)))
    (layout root (make-rect :x 0 :y 0 :width 320 :height 200))
    (values state bar body-button)))

(defun %click-point-inside (widget)
  (let ((rect (widget-layout-rect widget)))
    (list (+ (minerva.gui:rect-x rect) 2)
          (+ (minerva.gui:rect-y rect) 2))))

(defclass render-probe (widget)
  ((id :initarg :id :accessor render-probe-id)
   (min-width :initarg :min-width :accessor render-probe-min-width :initform 10)
   (min-height :initarg :min-height :accessor render-probe-min-height :initform 10)))

(defmethod measure ((probe render-probe))
  (minerva.gui:make-size-request :min-width (render-probe-min-width probe)
                                 :min-height (render-probe-min-height probe)
                                 :expand-x nil
                                 :expand-y nil))

(defmethod layout ((probe render-probe) rect)
  (setf (widget-layout-rect probe) rect)
  probe)

(defmethod render ((probe render-probe) backend-window)
  (declare (ignore backend-window))
  (push (render-probe-id probe) *render-probe-events*)
  probe)

(defmethod handle-event ((probe render-probe) app-state event)
  (declare (ignore app-state event))
  nil)

(defun %assert-equal (actual expected label)
  (incf *test-count*)
  (unless (equal actual expected)
    (incf *test-failures*)
    (format t "[FAIL] ~A expected=~S actual=~S~%" label expected actual)))

(defun %run-test-case (test-symbol)
  (let ((failures-before *test-failures*)
        (*current-test-name* test-symbol))
    (declare (ignore *current-test-name*))
    (handler-case
        (progn
          (funcall (symbol-function test-symbol))
          (if (= failures-before *test-failures*)
              (format t "* Pass ~(~A~)~%" test-symbol)
              (format t "- Fail ~(~A~)~%" test-symbol)))
      (error (condition)
        (incf *test-failures*)
        (format t "- Fail ~(~A~) (~A)~%" test-symbol condition)))))

(defun %test-symbol-p (symbol package)
  (and (fboundp symbol)
       (eq (symbol-package symbol) package)
       (let ((name (symbol-name symbol)))
         (and (>= (length name) 5)
              (string= name "TEST-" :end1 5 :end2 5)))))

(defun %collect-test-symbols ()
  (let ((package (find-package :minerva.events.tests)))
    (sort (loop for symbol being the symbols of package
                when (%test-symbol-p symbol package)
                collect symbol)
          #'string<
          :key #'symbol-name)))

(%deftest test-event-conversion-shapes
  (%assert-equal
   (sdl-event->minerva-event '(:mouse-move 120 60))
   '(:mouse-move :x 120 :y 60)
   "mouse move converts to keyword payload")
  (%assert-equal
   (sdl-event->minerva-event '(:mouse-button-down 1 300 40))
   '(:mouse-down :button :left :x 300 :y 40)
   "mouse button down converts with normalized button")
  (%assert-equal
   (sdl-event->minerva-event '(:key-down 27))
   '(:key-down :key :escape)
   "escape key down converts")
  (%assert-equal
   (sdl-event->minerva-event '(:text-input "abc"))
   '(:text-input :text "abc")
   "text input converts to payload event")
  (%assert-equal
   (sdl-event->minerva-event '(:window-resized 1400 900))
   '(:window-resized :width 1400 :height 900)
   "window resized converts")
  (%assert-equal
   (sdl-event->minerva-event '(:quit))
   '(:quit)
   "quit converts")
  (%assert-equal
   (sdl-event->minerva-event '(:unknown-event 1 2 3))
   nil
   "unknown event ignored"))

(%deftest test-mouse-routing-hit-tests-deepest-widget
  (let* ((left (make-instance 'color-rect :min-width 50 :min-height 40))
         (right (make-instance 'color-rect :min-width 50 :min-height 40))
         (box (make-instance 'hbox :children (list left right) :spacing 0))
         (root (make-instance 'window :width 120 :height 60 :child box))
         (state (make-app-state :root root)))
    (layout root (make-rect :x 0 :y 0 :width 120 :height 60))
    (%assert-equal
     (route-minerva-event state '(:mouse-down :button :left :x 10 :y 10))
     left
     "mouse event routes to left child")
    (%assert-equal
     (route-minerva-event state '(:mouse-down :button :left :x 70 :y 10))
     right
     "mouse event routes to right child")
    (%assert-equal
     (route-minerva-event state '(:quit))
     root
     "quit routes to root")))

(%deftest test-key-routing-prefers-focused-widget
  (let* ((focused (make-instance 'color-rect :min-width 20 :min-height 20))
         (other (make-instance 'color-rect :min-width 20 :min-height 20))
         (root (make-instance 'window :width 100 :height 50
                              :child (make-instance 'hbox :children (list focused other))))
         (state-with-focus (make-app-state :root root :focused-widget focused))
         (state-no-focus (make-app-state :root root :focused-widget nil)))
    (%assert-equal
     (route-minerva-event state-with-focus '(:key-down :key :escape))
     focused
     "key event routes to focused widget")
    (%assert-equal
     (route-minerva-event state-no-focus '(:key-down :key :escape))
     root
     "key event falls back to root when focus is nil")))

(%deftest test-text-input-routing-prefers-focused-widget
  (let* ((focused (make-instance 'color-rect :min-width 20 :min-height 20))
         (other (make-instance 'color-rect :min-width 20 :min-height 20))
         (root (make-instance 'window :width 100 :height 50
                              :child (make-instance 'hbox :children (list focused other))))
         (state-with-focus (make-app-state :root root :focused-widget focused))
         (state-no-focus (make-app-state :root root :focused-widget nil)))
    (%assert-equal
     (route-minerva-event state-with-focus '(:text-input :text "a"))
     focused
     "text input routes to focused widget")
    (%assert-equal
     (route-minerva-event state-no-focus '(:text-input :text "a"))
     root
     "text input falls back to root when focus is nil")))

(%deftest test-default-and-window-event-handlers
  (let* ((leaf (make-instance 'color-rect :min-width 10 :min-height 10))
         (root (make-instance 'window :width 200 :height 100 :child leaf))
         (state (make-app-state :root root)))
    (%assert-equal
     (handle-event leaf state '(:mouse-move :x 1 :y 2))
     nil
     "default widget handler is no-op")
    (process-minerva-event state '(:window-resized :width 300 :height 150))
    (%assert-equal
         (list (window-width root) (window-height root))
         '(300 150)
         "window resize updates root")
    (process-minerva-event state '(:quit))
    (%assert-equal
     (app-state-should-quit state)
     t
     "quit marks app-state should-quit")))

(%deftest test-mouse-up-routes-to-active-widget
  (%with-stubbed-button-gfx
    (let* ((left (make-instance 'button :text "L" :command :left-cmd))
           (right (make-instance 'button :text "R" :command :right-cmd))
           (root (make-instance 'window :width 120 :height 40
                                :child (make-instance 'hbox :children (list left right) :spacing 0)))
           (state (make-app-state :root root :active-widget left)))
      (layout root (make-rect :x 0 :y 0 :width 120 :height 40))
      (%assert-equal
       (route-minerva-event state '(:mouse-up :button :left :x 90 :y 20))
       left
       "mouse-up routes to active widget when set"))))

(%deftest test-button-click-emits-command-and-clears-active-widget
  (%with-stubbed-button-gfx
    (let* ((btn (make-instance 'button :text "Load" :command :load-file))
           (root (make-instance 'window :width 120 :height 40 :child btn))
           (state (make-app-state :root root)))
      (layout root (make-rect :x 0 :y 0 :width 120 :height 40))
      (setf (app-state-needs-redraw state) nil)
      (process-minerva-event state '(:mouse-move :x 10 :y 10))
      (%assert-equal (button-state btn) :highlighted "mouse move inside highlights button")
      (%assert-equal (app-state-needs-redraw state) t "hover transition requests redraw")
      (setf (app-state-needs-redraw state) nil)
      (process-minerva-event state '(:mouse-down :button :left :x 10 :y 10))
      (%assert-equal (button-state btn) :pressed "mouse down inside presses button")
      (%assert-equal (app-state-active-widget state) btn "mouse down sets active widget")
      (%assert-equal (app-state-needs-redraw state) t "press transition requests redraw")
      (setf (app-state-needs-redraw state) nil)
      (process-minerva-event state '(:mouse-up :button :left :x 10 :y 10))
      (%assert-equal (app-state-last-command state) :load-file "mouse up inside emits command action")
      (%assert-equal (app-state-active-widget state) nil "mouse up clears active widget")
      (%assert-equal (button-state btn) :highlighted "mouse up inside returns to highlighted")
      (%assert-equal (app-state-needs-redraw state) t "release transition requests redraw"))))

(%deftest test-button-release-outside-does-not-activate
  (%with-stubbed-button-gfx
    (let* ((btn (make-instance 'button :text "Load" :command :load-file))
           (root (make-instance 'window :width 120 :height 40 :child btn))
           (state (make-app-state :root root)))
      (layout root (make-rect :x 0 :y 0 :width 120 :height 40))
      (process-minerva-event state '(:mouse-down :button :left :x 10 :y 10))
      (process-minerva-event state '(:mouse-up :button :left :x 300 :y 300))
      (%assert-equal (app-state-last-command state) nil "mouse up outside does not emit command")
      (%assert-equal (app-state-active-widget state) nil "mouse up outside clears active widget")
      (%assert-equal (button-state btn) :normal "mouse up outside returns button to normal"))))

(%deftest test-button-hover-clears-when-mouse-leaves
  (%with-stubbed-button-gfx
    (let* ((btn (make-instance 'button :text "Load" :command :load-file))
           (root (make-instance 'window :width 120 :height 40 :child btn))
           (state (make-app-state :root root)))
      (layout root (make-rect :x 0 :y 0 :width 120 :height 40))
      (process-minerva-event state '(:mouse-move :x 10 :y 10))
      (%assert-equal (button-state btn) :highlighted "mouse move inside highlights button")
      (setf (app-state-needs-redraw state) nil)
      (process-minerva-event state '(:mouse-move :x 300 :y 300))
      (%assert-equal (button-state btn) :normal "mouse leave clears highlight")
      (%assert-equal (app-state-needs-redraw state) t "mouse leave requests redraw"))))

(%deftest test-process-actions-handles-command-centrally
  (let ((state (make-app-state)))
    (setf (app-state-needs-redraw state) nil)
    (process-actions state '((:command :load-file)))
    (%assert-equal (app-state-last-command state) :load-file "process-actions records handled command")
    (%assert-equal (app-state-needs-redraw state) t "load-file command marks redraw")
    (setf (app-state-should-quit state) nil)
    (process-actions state '((:command :quit-app)))
    (%assert-equal (app-state-should-quit state) t "quit-app command sets should-quit")))

(%deftest test-overlay-stack-push-pop-remove
  (let* ((root (make-instance 'window :width 120 :height 80 :child (make-instance 'color-rect)))
         (state (make-app-state :root root))
         (overlay-a (make-overlay :root-widget (make-instance 'color-rect)
                                  :rect (make-rect :x 0 :y 0 :width 20 :height 20)))
         (overlay-b (make-overlay :root-widget (make-instance 'color-rect)
                                  :rect (make-rect :x 4 :y 4 :width 20 :height 20))))
    (%assert-equal (overlay-stack-empty-p state) t "overlay stack starts empty")
    (push-overlay state overlay-a)
    (%assert-equal (top-overlay state) overlay-a "top overlay after first push")
    (push-overlay state overlay-b)
    (%assert-equal (length (app-state-overlay-stack state)) 2 "overlay push appends stack")
    (%assert-equal (top-overlay state) overlay-b "newest overlay is top")
    (%assert-equal (pop-overlay state) overlay-b "pop returns newest overlay")
    (%assert-equal (top-overlay state) overlay-a "top overlay updates after pop")
    (%assert-equal (remove-overlay state overlay-a) t "remove-overlay removes matching instance")
    (%assert-equal (overlay-stack-empty-p state) t "overlay stack empty after removals")))

(%deftest test-overlay-render-order-base-before_overlays
  (let* ((base-probe (make-instance 'render-probe :id :base :min-width 60 :min-height 40))
         (overlay-a-probe (make-instance 'render-probe :id :overlay-a :min-width 20 :min-height 20))
         (overlay-b-probe (make-instance 'render-probe :id :overlay-b :min-width 20 :min-height 20))
         (root (make-instance 'window :width 120 :height 80 :child base-probe :background-color nil))
         (state (make-app-state :root root)))
    (setf *render-probe-events* nil)
    (push-overlay state (make-overlay :root-widget overlay-a-probe
                                      :rect (make-rect :x 2 :y 2 :width 20 :height 20)))
    (push-overlay state (make-overlay :root-widget overlay-b-probe
                                      :rect (make-rect :x 6 :y 6 :width 20 :height 20)))
    (layout-app-state state)
    (render-app-state state nil)
    (%assert-equal (reverse *render-probe-events*)
                   '(:base :overlay-a :overlay-b)
                   "render order is base then overlays oldest-to-newest")))

(%deftest test-overlay-mouse-routing-prefers-newest
  (let* ((base (make-instance 'color-rect :min-width 120 :min-height 80))
         (root (make-instance 'window :width 120 :height 80 :child base))
         (state (make-app-state :root root))
         (lower (make-instance 'color-rect :min-width 30 :min-height 30))
         (upper (make-instance 'color-rect :min-width 30 :min-height 30)))
    (push-overlay state (make-overlay :root-widget lower
                                      :rect (make-rect :x 10 :y 10 :width 30 :height 30)))
    (push-overlay state (make-overlay :root-widget upper
                                      :rect (make-rect :x 10 :y 10 :width 30 :height 30)))
    (layout-app-state state)
    (%assert-equal (route-minerva-event state '(:mouse-down :button :left :x 12 :y 12))
                   upper
                   "mouse routes to newest overlay first")))

(%deftest test-overlay-pass-through-and-blocking
  (let* ((base-widget (make-instance 'color-rect :min-width 120 :min-height 50))
         (root (make-instance 'window :width 120 :height 50 :child base-widget))
         (state (make-app-state :root root))
         (pass-through-overlay (make-overlay :root-widget (make-instance 'color-rect :min-width 20 :min-height 20)
                                            :rect (make-rect :x 80 :y 80 :width 20 :height 20)
                                            :blocks-lower-input-p nil))
         (blocking-overlay (make-overlay :root-widget (make-instance 'color-rect :min-width 20 :min-height 20)
                                         :rect (make-rect :x 80 :y 80 :width 20 :height 20)
                                         :blocks-lower-input-p t)))
    (layout-app-state state)
    (push-overlay state pass-through-overlay)
    (layout-app-state state)
    (%assert-equal (route-minerva-event state '(:mouse-down :button :left :x 10 :y 10))
                   base-widget
                   "non-blocking top overlay allows lower layer routing")
    (remove-overlay state pass-through-overlay)
    (push-overlay state blocking-overlay)
    (layout-app-state state)
    (%assert-equal (route-minerva-event state '(:mouse-down :button :left :x 10 :y 10))
                   nil
                   "blocking top overlay prevents lower layer routing")))

(%deftest test-overlay-anchor-placement-and_independent_layout
  (let* ((base (make-instance 'color-rect :min-width 100 :min-height 60))
         (root (make-instance 'window :width 100 :height 60 :child base))
         (overlay-widget (make-instance 'color-rect :min-width 18 :min-height 12))
         (state (make-app-state :root root))
         (anchor (make-rect :x 7 :y 9 :width 20 :height 5))
         (overlay (make-overlay :root-widget overlay-widget
                                :anchor-rect anchor
                                :anchor-offset-y 3
                                :rect (make-rect :x 500 :y 500 :width 0 :height 0))))
    (push-overlay state overlay)
    (layout-app-state state)
    (%assert-equal (list (minerva.gui:rect-x (overlay-rect overlay))
                         (minerva.gui:rect-y (overlay-rect overlay))
                         (minerva.gui:rect-width (overlay-rect overlay))
                         (minerva.gui:rect-height (overlay-rect overlay)))
                   '(7 17 18 12)
                   "anchor placement resolves below anchor using measured size")
    (%assert-equal (list (minerva.gui:rect-x (widget-layout-rect overlay-widget))
                         (minerva.gui:rect-y (widget-layout-rect overlay-widget)))
                   '(7 17)
                   "overlay layout is independent from base tree flow")))

(%deftest test-menu-overlay-renders-above-base
  (let* ((draw-events '())
         (base-probe (make-instance 'render-probe :id :base :min-width 100 :min-height 60))
         (root (make-instance 'window :width 140 :height 90 :child base-probe :background-color nil))
         (menu-widget (make-instance 'menu :entries nil :panel-surface '(:width 24 :height 24)))
         (state (make-app-state :root root))
         (old-scaled (symbol-function 'minerva.gui::%call-draw-surface-rect-scaled)))
    (unwind-protect
         (progn
           (setf *render-probe-events* nil)
           (setf (symbol-function 'minerva.gui::%call-draw-surface-rect-scaled)
                 (lambda (&rest args)
                   (declare (ignore args))
                   (push :menu draw-events)))
           (push-overlay state (make-overlay :root-widget menu-widget
                                             :rect (make-rect :x 10 :y 10 :width 90 :height 50)))
           (layout-app-state state)
           (render-app-state state nil)
           (%assert-equal (first (reverse *render-probe-events*)) :base "base renders before menu overlay draws")
           (%assert-equal (car draw-events) :menu "menu overlay draws after base"))
      (setf (symbol-function 'minerva.gui::%call-draw-surface-rect-scaled) old-scaled))))

(%deftest test-menubar-click-opens-overlay-and-presses-button
  (%with-stubbed-menu-bar-gfx
    (multiple-value-bind (state bar body-button)
        (%menu-bar-test-state)
      (declare (ignore body-button))
      (let* ((file-button (first (menu-bar-buttons bar)))
             (file-point (%click-point-inside file-button)))
        (process-minerva-event state (list :mouse-down :button :left :x (first file-point) :y (second file-point)))
        (process-minerva-event state (list :mouse-up :button :left :x (first file-point) :y (second file-point)))
        (%assert-equal (length (app-state-overlay-stack state))
                       1
                       "clicking menubar button opens one overlay")
        (%assert-equal (menu-bar-open-index bar)
                       0
                       "clicking first menubar button marks first menu open")
        (%assert-equal (menu-bar-button-state file-button)
                       :pressed
                       "opened menubar button remains pressed")))))

(%deftest test-menubar-menu-item-click-closes-overlay-and-emits-command
  (%with-stubbed-menu-bar-gfx
    (multiple-value-bind (state bar body-button)
        (%menu-bar-test-state)
      (declare (ignore body-button))
      (let* ((file-button (first (menu-bar-buttons bar)))
             (file-point (%click-point-inside file-button)))
        (process-minerva-event state (list :mouse-down :button :left :x (first file-point) :y (second file-point)))
        (process-minerva-event state (list :mouse-up :button :left :x (first file-point) :y (second file-point)))
        (layout-app-state state)
        (let* ((overlay (first (last (app-state-overlay-stack state))))
               (menu-widget (minerva.gui::menu-bar-overlay-root-menu-widget
                             (minerva.events:overlay-root-widget overlay)))
               (first-item (first (remove-if-not (lambda (child)
                                                   (typep child 'minerva.gui:menu-item))
                                                 (minerva.gui:menu-children menu-widget))))
               (item-point (%click-point-inside first-item)))
          (process-minerva-event state (list :mouse-down :button :left :x (first item-point) :y (second item-point)))
          (process-minerva-event state (list :mouse-up :button :left :x (first item-point) :y (second item-point)))
          (%assert-equal (length (app-state-overlay-stack state))
                         0
                         "menu item click closes menubar overlay")
          (%assert-equal (menu-bar-open-index bar)
                         nil
                         "menu item click clears menubar open index")
          (%assert-equal (app-state-last-command state)
                         :open
                         "menu item click still emits command"))))))

(%deftest test-menubar-escape-closes-overlay
  (%with-stubbed-menu-bar-gfx
    (multiple-value-bind (state bar body-button)
        (%menu-bar-test-state)
      (declare (ignore body-button))
      (let* ((file-button (first (menu-bar-buttons bar)))
             (file-point (%click-point-inside file-button)))
        (process-minerva-event state (list :mouse-down :button :left :x (first file-point) :y (second file-point)))
        (process-minerva-event state (list :mouse-up :button :left :x (first file-point) :y (second file-point)))
        (process-minerva-event state '(:key-down :key :escape))
        (%assert-equal (length (app-state-overlay-stack state))
                       0
                       "escape closes menubar overlay")
        (%assert-equal (menu-bar-open-index bar)
                       nil
                       "escape clears menubar open index")
        (%assert-equal (menu-bar-button-state file-button)
                       :normal
                       "escape resets opened button to normal")))))

(%deftest test-menubar-outside-left-click-closes-and-consumes
  (%with-stubbed-menu-bar-gfx
    (multiple-value-bind (state bar body-button)
        (%menu-bar-test-state)
      (let* ((file-button (first (menu-bar-buttons bar)))
             (file-point (%click-point-inside file-button))
             (body-point (%click-point-inside body-button)))
        (process-minerva-event state (list :mouse-down :button :left :x (first file-point) :y (second file-point)))
        (process-minerva-event state (list :mouse-up :button :left :x (first file-point) :y (second file-point)))
        (setf (app-state-last-command state) nil)
        (process-minerva-event state (list :mouse-down :button :left :x (first body-point) :y (second body-point)))
        (process-minerva-event state (list :mouse-up :button :left :x (first body-point) :y (second body-point)))
        (%assert-equal (length (app-state-overlay-stack state))
                       0
                       "outside left click closes menu overlay")
        (%assert-equal (menu-bar-open-index bar)
                       nil
                       "outside left click clears open index")
        (%assert-equal (app-state-last-command state)
                       nil
                       "outside click is consumed and does not activate base button")))))

(%deftest test-menubar-clicking-another-button-switches-menus
  (%with-stubbed-menu-bar-gfx
    (multiple-value-bind (state bar body-button)
        (%menu-bar-test-state)
      (declare (ignore body-button))
      (let* ((file-button (first (menu-bar-buttons bar)))
             (edit-button (second (menu-bar-buttons bar)))
             (file-point (%click-point-inside file-button))
             (edit-point (%click-point-inside edit-button)))
        (process-minerva-event state (list :mouse-down :button :left :x (first file-point) :y (second file-point)))
        (process-minerva-event state (list :mouse-up :button :left :x (first file-point) :y (second file-point)))
        (process-minerva-event state (list :mouse-down :button :left :x (first edit-point) :y (second edit-point)))
        (%assert-equal (menu-bar-open-index bar)
                       1
                       "clicking second menubar button switches open menu")
        (%assert-equal (length (app-state-overlay-stack state))
                       1
                       "switching menus keeps a single overlay open")
        (%assert-equal (menu-bar-button-state file-button)
                       :normal
                       "previous menubar button returns to normal after switch")
        (%assert-equal (menu-bar-button-state edit-button)
                       :pressed
                       "newly opened menubar button is pressed")))))

(defun run-event-tests ()
  (setf *test-count* 0
        *test-failures* 0)
  (dolist (test-symbol (%collect-test-symbols))
    (%run-test-case test-symbol))
  (format t "~%Executed ~D event assertions.~%" *test-count*)
  (if (zerop *test-failures*)
      (format t "All event tests passed.~%")
      (error "Event tests failed: ~D assertion(s)." *test-failures*)))
