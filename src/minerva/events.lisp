(defpackage :minerva.events
  (:use :cl)
  (:import-from :minerva.gui
                :widget
                :window
                :window-width
                :window-height
                :widget-layout-rect
                :event-children
                :handle-event
                :rect-x
                :rect-y
                :rect-width
                :rect-height)
  (:export
   :app-state
   :make-app-state
   :app-state-root
   :app-state-focused-widget
   :app-state-should-quit
   :app-state-window-width
   :app-state-window-height
   :sdl-event->minerva-event
   :route-minerva-event
   :process-minerva-event
   :widget-at-point))

(in-package :minerva.events)

(defstruct (app-state
            (:constructor %make-app-state (&key root focused-widget should-quit window-width window-height)))
  (root nil)
  (focused-widget nil)
  (should-quit nil)
  (window-width 0 :type integer)
  (window-height 0 :type integer))

(defun make-app-state (&key root focused-widget (should-quit nil) window-width window-height)
  (let ((width (or window-width
                   (when (typep root 'window)
                     (window-width root))
                   0))
        (height (or window-height
                    (when (typep root 'window)
                      (window-height root))
                    0)))
    (%make-app-state :root root
                     :focused-widget focused-widget
                     :should-quit should-quit
                     :window-width (max 0 (truncate width))
                     :window-height (max 0 (truncate height)))))

(defun %normalize-mouse-button (button)
  (case button
    ((1 :left) :left)
    ((2 :middle) :middle)
    ((3 :right) :right)
    (otherwise nil)))

(defun %key-fallback-keyword (key)
  (intern (string-upcase (format nil "KEY-~A" key)) :keyword))

(defun %normalize-key (key)
  (cond
    ((keywordp key) key)
    ((symbolp key) (intern (string-upcase (symbol-name key)) :keyword))
    ((integerp key)
     (cond
       ((= key 27) :escape)
       ((or (= key 13) (= key 10)) :enter)
       ((= key 32) :space)
       ((or (= key 1073741904) (= key 276)) :left)
       ((or (= key 1073741903) (= key 275)) :right)
       ((or (= key 1073741906) (= key 273)) :up)
       ((or (= key 1073741905) (= key 274)) :down)
       ((and (>= key 65) (<= key 90))
        (intern (string (code-char (+ key 32))) :keyword))
       ((and (>= key 97) (<= key 122))
        (intern (string (code-char key)) :keyword))
       (t (%key-fallback-keyword key))))
    (t (%key-fallback-keyword key))))

(defun sdl-event->minerva-event (raw-event)
  (unless (and (listp raw-event) raw-event)
    (return-from sdl-event->minerva-event nil))
  (let ((type (first raw-event)))
    (case type
      (:quit '(:quit))
      (:window-resized
       (list :window-resized
             :width (max 0 (truncate (or (second raw-event) 0)))
             :height (max 0 (truncate (or (third raw-event) 0)))) )
      (:key-down
       (list :key-down :key (%normalize-key (second raw-event))))
      (:key-up
       (list :key-up :key (%normalize-key (second raw-event))))
      (:mouse-move
       (list :mouse-move
             :x (truncate (or (second raw-event) 0))
             :y (truncate (or (third raw-event) 0))))
      (:mouse-button-down
       (let ((button (%normalize-mouse-button (second raw-event))))
         (when button
           (list :mouse-down
                 :button button
                 :x (truncate (or (third raw-event) 0))
                 :y (truncate (or (fourth raw-event) 0))))))
      (:mouse-button-up
       (let ((button (%normalize-mouse-button (second raw-event))))
         (when button
           (list :mouse-up
                 :button button
                 :x (truncate (or (third raw-event) 0))
                 :y (truncate (or (fourth raw-event) 0))))))
      (otherwise nil))))

(defun %point-in-rect-p (x y rect)
  (and (>= x (rect-x rect))
       (>= y (rect-y rect))
       (< x (+ (rect-x rect) (rect-width rect)))
       (< y (+ (rect-y rect) (rect-height rect)))))

(defun widget-at-point (root-widget x y)
  (labels ((visit (widget)
             (when (and widget (%point-in-rect-p x y (widget-layout-rect widget)))
               (or (loop for child in (reverse (event-children widget))
                         for found = (visit child)
                         when found do (return found))
                   widget))))
    (visit root-widget)))

(defun route-minerva-event (state event)
  (let* ((root (app-state-root state))
         (focused (app-state-focused-widget state))
         (type (first event)))
    (case type
      ((:window-resized :quit)
       root)
      ((:key-down :key-up)
       (or focused root))
      ((:mouse-move :mouse-down :mouse-up)
       (let ((x (getf (rest event) :x))
             (y (getf (rest event) :y)))
         (or (and (numberp x)
                  (numberp y)
                  root
                  (widget-at-point root x y))
             root)))
      (otherwise nil))))

(defun %apply-app-state-event-updates (state event)
  (case (first event)
    (:window-resized
     (setf (app-state-window-width state) (max 0 (truncate (or (getf (rest event) :width) 0)))
           (app-state-window-height state) (max 0 (truncate (or (getf (rest event) :height) 0)))))
    (otherwise nil))
  state)

(defun process-minerva-event (state event)
  (%apply-app-state-event-updates state event)
  (let* ((target (route-minerva-event state event))
         (result (and target (handle-event target state event))))
    (when (and (listp result) (getf result :quit))
      (setf (app-state-should-quit state) t))
    target))
