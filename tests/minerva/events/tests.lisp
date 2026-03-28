(defpackage :minerva.events.tests
  (:use :cl)
  (:import-from :minerva.gui
                :hbox
                :window
                :color-rect
                :make-rect
                :layout
                :handle-event
                :window-width
                :window-height)
  (:import-from :minerva.events
                :make-app-state
                :sdl-event->minerva-event
                :route-minerva-event
                :process-minerva-event
                :app-state-should-quit
                :app-state-window-width
                :app-state-window-height))

(in-package :minerva.events.tests)

(defvar *test-count* 0)
(defvar *test-failures* 0)
(defvar *current-test-name* nil)

(defmacro %deftest (name &body body)
  `(defun ,name ()
     ,@body))

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
     (list (window-width root) (window-height root)
           (app-state-window-width state)
           (app-state-window-height state))
     '(300 150 300 150)
     "window resize updates root and app-state")
    (process-minerva-event state '(:quit))
    (%assert-equal
     (app-state-should-quit state)
     t
     "quit marks app-state should-quit")))

(defun run-event-tests ()
  (setf *test-count* 0
        *test-failures* 0)
  (dolist (test-symbol (%collect-test-symbols))
    (%run-test-case test-symbol))
  (format t "~%Executed ~D event assertions.~%" *test-count*)
  (if (zerop *test-failures*)
      (format t "All event tests passed.~%")
      (error "Event tests failed: ~D assertion(s)." *test-failures*)))
