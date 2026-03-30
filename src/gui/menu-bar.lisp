(in-package :minerva.gui)

(defclass menu-bar-button (widget)
  ((text :initarg :text :accessor menu-bar-button-text :initform "")
   (menu-bar :initarg :menu-bar :accessor menu-bar-button-menu-bar :initform nil)
   (entry-index :initarg :entry-index :accessor menu-bar-button-entry-index :initform 0)
   (font-name :initarg :font-name :accessor menu-bar-button-font-name :initform theme:default-font)
   (text-size :initarg :text-size :accessor menu-bar-button-text-size :initform theme:default-font-size)
   (padding-x :initarg :padding-x :accessor menu-bar-button-padding-x :initform 10)
   (padding-y :initarg :padding-y :accessor menu-bar-button-padding-y :initform 6)
   (state :initarg :state :accessor menu-bar-button-state :initform :normal)
   (pointer-down-p :accessor menu-bar-button-pointer-down-p :initform nil)
   (normal-text-surface :accessor menu-bar-button-normal-text-surface :initform nil)
   (pressed-text-surface :accessor menu-bar-button-pressed-text-surface :initform nil)))

(defclass menu-bar (widget)
  ((entries :initarg :entries :accessor menu-bar-entries :initform nil)
   (buttons :accessor menu-bar-buttons :initform nil)
   (button-row :accessor menu-bar-button-row :initform nil)
   (panel :accessor menu-bar-panel :initform nil)
   (panel-surface :initarg :panel-surface :accessor menu-bar-panel-surface :initform nil)
   (spacing :initarg :spacing :accessor menu-bar-spacing :initform 0)
   (icon-resolver :initarg :icon-resolver :accessor menu-bar-icon-resolver :initform nil)
   (open-index :accessor menu-bar-open-index :initform nil)
   (open-overlay :accessor menu-bar-open-overlay :initform nil)))

(defclass menu-bar-overlay-root (widget)
  ((menu-bar :initarg :menu-bar :accessor menu-bar-overlay-root-menu-bar :initform nil)
   (menu-widget :initarg :menu-widget :accessor menu-bar-overlay-root-menu-widget :initform nil)
   (overlay :initarg :overlay :accessor menu-bar-overlay-root-overlay :initform nil)))

(defun %menu-bar-point-in-rect-p (x y rect)
  (and (numberp x)
       (numberp y)
       (>= x (rect-x rect))
       (>= y (rect-y rect))
       (< x (+ (rect-x rect) (rect-width rect)))
       (< y (+ (rect-y rect) (rect-height rect)))))

(defun %menu-bar-load-panel-surface ()
  (%menu-load-default-panel-surface))

(defun %menu-bar-events-function (name)
  (let* ((events-package (find-package :minerva.events))
         (symbol (and events-package (find-symbol name events-package))))
    (and symbol (fboundp symbol) (symbol-function symbol))))

(defun %menu-bar-ensure-events-function (name)
  (or (%menu-bar-events-function name)
      (error "Missing minerva.events function ~A" name)))

(defun %menu-bar-push-overlay (app-state overlay)
  (funcall (%menu-bar-ensure-events-function "PUSH-OVERLAY") app-state overlay))

(defun %menu-bar-remove-overlay (app-state overlay)
  (funcall (%menu-bar-ensure-events-function "REMOVE-OVERLAY") app-state overlay))

(defun %menu-bar-make-overlay (&rest args)
  (apply (%menu-bar-ensure-events-function "MAKE-OVERLAY") args))

(defun %menu-bar-mark-redraw (app-state)
  (%set-button-app-state-value app-state "APP-STATE-NEEDS-REDRAW" t))

(defun %menu-bar-set-button-state (button app-state state)
  (unless (eq (menu-bar-button-state button) state)
    (setf (menu-bar-button-state button) state)
    (%menu-bar-mark-redraw app-state))
  state)

(defun %menu-bar-button-open-p (button)
  (let ((menu-bar (menu-bar-button-menu-bar button)))
    (and menu-bar
         (eql (menu-bar-open-index menu-bar)
              (menu-bar-button-entry-index button)))))

(defun %menu-bar-button-bg-color (button)
  (case (menu-bar-button-state button)
    (:hovered theme:menubar-button-bg-hovered)
    (:pressed theme:menubar-button-bg-pressed)
    (otherwise theme:menubar-button-bg-normal)))

(defun %menu-bar-button-text-surface-for-state (button)
  (if (eq (menu-bar-button-state button) :pressed)
      (menu-bar-button-pressed-text-surface button)
      (menu-bar-button-normal-text-surface button)))

(defun %menu-bar-button-text-placement (button)
  (let* ((layout-rect (widget-layout-rect button))
         (text-surface (%menu-bar-button-text-surface-for-state button))
         (text-width (%surface-width text-surface))
         (text-height (%surface-height text-surface))
         (allocated-x (rect-x layout-rect))
         (allocated-y (rect-y layout-rect))
         (allocated-width (rect-width layout-rect))
         (allocated-height (rect-height layout-rect))
         (dest-x (%align-position allocated-x allocated-width text-width :center))
         (dest-y (%align-position allocated-y allocated-height text-height :center))
         (clip-left (max allocated-x dest-x))
         (clip-top (max allocated-y dest-y))
         (clip-right (min (+ allocated-x allocated-width) (+ dest-x text-width)))
         (clip-bottom (min (+ allocated-y allocated-height) (+ dest-y text-height)))
         (draw-width (max 0 (- clip-right clip-left)))
         (draw-height (max 0 (- clip-bottom clip-top))))
    (values (make-rect :x clip-left :y clip-top :width draw-width :height draw-height)
            (make-rect :x (max 0 (- clip-left dest-x))
                       :y (max 0 (- clip-top dest-y))
                       :width draw-width
                       :height draw-height))))

(defun %menu-bar-button-inside-p (button x y)
  (%menu-bar-point-in-rect-p x y (widget-layout-rect button)))

(defun %menu-bar-button-release-state (button x y)
  (cond
    ((%menu-bar-button-open-p button) :pressed)
    ((%menu-bar-button-inside-p button x y) :hovered)
    (t :normal)))

(defun %menu-bar-hit-button-index (bar x y)
  (loop for button in (menu-bar-buttons bar)
        for index from 0
        when (%menu-bar-point-in-rect-p x y (widget-layout-rect button))
        do (return index)))

(defun %menu-bar-entry-for-index (bar index)
  (nth index (menu-bar-entries bar)))

(defun %menu-bar-items-for-index (bar index)
  (let ((entry (%menu-bar-entry-for-index bar index)))
    (or (getf entry :items) nil)))

(defun %menu-bar-button-for-index (bar index)
  (nth index (menu-bar-buttons bar)))

(defun %menu-bar-clear-open-state (bar app-state)
  (setf (menu-bar-open-index bar) nil
        (menu-bar-open-overlay bar) nil)
  (dolist (button (menu-bar-buttons bar))
    (setf (menu-bar-button-pointer-down-p button) nil)
    (%menu-bar-set-button-state button app-state :normal))
  (%menu-bar-mark-redraw app-state)
  bar)

(defun %menu-bar-close-open-menu (bar app-state)
  (let ((overlay (menu-bar-open-overlay bar)))
    (when overlay
      (%menu-bar-remove-overlay app-state overlay))
    (%menu-bar-clear-open-state bar app-state)))

(defun %menu-bar-close-from-app-state (app-state)
  (let* ((overlay-stack (%button-app-state-value app-state "APP-STATE-OVERLAY-STACK"))
         (overlay (car (last overlay-stack)))
         (root-widget (and overlay
                           (funcall (%menu-bar-ensure-events-function "OVERLAY-ROOT-WIDGET")
                                    overlay))))
    (when (and root-widget
               (typep root-widget 'menu-bar-overlay-root))
      (%menu-bar-close-open-menu (menu-bar-overlay-root-menu-bar root-widget)
                                 app-state)
      t)))

(defun %menu-bar-button-anchor-rect (button)
  (or (widget-last-render-position button)
      (widget-layout-rect button)
      (make-rect)))

(defun %menu-bar-open-menu (bar app-state index)
  (let ((currently-open-index (menu-bar-open-index bar)))
    (when (and (eql currently-open-index index)
               (menu-bar-open-overlay bar))
      (let ((button (%menu-bar-button-for-index bar index)))
        (when button
          (%menu-bar-set-button-state button app-state :pressed)))
      (return-from %menu-bar-open-menu (menu-bar-open-overlay bar))))
  (when (menu-bar-open-overlay bar)
    (%menu-bar-close-open-menu bar app-state))
  (let* ((entry (%menu-bar-entry-for-index bar index))
         (items (or (getf entry :items) nil))
         (button (%menu-bar-button-for-index bar index))
         (menu-widget (make-instance 'menu
                                     :entries items
                                     :icon-resolver (menu-bar-icon-resolver bar)))
         (overlay-root (make-instance 'menu-bar-overlay-root
                                      :menu-bar bar
                                      :menu-widget menu-widget))
         (overlay (%menu-bar-make-overlay
                   :root-widget overlay-root
                   :anchor-rect (%menu-bar-button-anchor-rect button)
                   :anchor-offset-y theme:menubar-menu-overlay-offset-y
                   :focus :capture
                   :takes-focus-p t
                   :blocks-lower-input-p t
                   :rect (make-rect :x 0 :y 0 :width 0 :height 0))))
    (setf (menu-bar-overlay-root-overlay overlay-root) overlay)
    (%menu-bar-push-overlay app-state overlay)
    (setf (menu-bar-open-index bar) index
          (menu-bar-open-overlay bar) overlay)
    (dolist (candidate (menu-bar-buttons bar))
      (%menu-bar-set-button-state candidate
                                  app-state
                                  (if (eq candidate button) :pressed :normal)))
    (%menu-bar-mark-redraw app-state)
    overlay))

(defmethod initialize-instance :after ((button menu-bar-button) &key)
  (setf (menu-bar-button-padding-x button) (%non-negative-int (menu-bar-button-padding-x button))
        (menu-bar-button-padding-y button) (%non-negative-int (menu-bar-button-padding-y button))
        (menu-bar-button-normal-text-surface button)
        (%render-label-text-surface (menu-bar-button-font-name button)
                                    (menu-bar-button-text-size button)
                                    (menu-bar-button-text button)
                                    theme:menubar-button-text-normal)
        (menu-bar-button-pressed-text-surface button)
        (%render-label-text-surface (menu-bar-button-font-name button)
                                    (menu-bar-button-text-size button)
                                    (menu-bar-button-text button)
                                    theme:menubar-button-text-pressed)))

(defmethod measure ((button menu-bar-button))
  (let* ((normal-surface (menu-bar-button-normal-text-surface button))
         (pressed-surface (menu-bar-button-pressed-text-surface button))
         (text-width (max (%surface-width normal-surface)
                          (%surface-width pressed-surface)))
         (text-height (max (%surface-height normal-surface)
                           (%surface-height pressed-surface)))
         (padding-x (%non-negative-int (menu-bar-button-padding-x button)))
         (padding-y (%non-negative-int (menu-bar-button-padding-y button))))
    (%apply-widget-margins-to-size-request
     button
     (make-size-request
      :min-width (+ text-width (* 2 padding-x))
      :min-height (+ text-height (* 2 padding-y))
      :expand-x nil
      :expand-y nil))))

(defmethod layout ((button menu-bar-button) rect)
  (setf (widget-layout-rect button) (%apply-widget-margins-to-rect button rect))
  button)

(defmethod render ((button menu-bar-button) backend-window)
  (let ((background (%menu-bar-button-bg-color button)))
    (when (> (color-a background) 0)
      (%call-fill-rect backend-window (widget-layout-rect button) background)))
  (let ((surface (%menu-bar-button-text-surface-for-state button)))
    (when surface
      (multiple-value-bind (dest-rect source-rect)
          (%menu-bar-button-text-placement button)
        (when (and (> (rect-width dest-rect) 0)
                   (> (rect-height dest-rect) 0))
          (%call-draw-surface-rect backend-window
                                   surface
                                   source-rect
                                   (rect-x dest-rect)
                                   (rect-y dest-rect))))))
  button)

(defmethod handle-event ((button menu-bar-button) app-state event)
  (let ((menu-bar (menu-bar-button-menu-bar button)))
    (case (first event)
      (:mouse-down
       (let* ((mouse-button (getf (rest event) :button))
              (x (getf (rest event) :x))
              (y (getf (rest event) :y)))
         (when (and (eq mouse-button :left)
                    (%menu-bar-button-inside-p button x y))
           (setf (menu-bar-button-pointer-down-p button) t)
           (%button-set-active-widget app-state button)
           (%menu-bar-set-button-state button app-state :pressed)
           nil)))
      (:mouse-up
       (let* ((mouse-button (getf (rest event) :button))
              (x (getf (rest event) :x))
              (y (getf (rest event) :y))
              (inside (%menu-bar-button-inside-p button x y))
              (was-down (menu-bar-button-pointer-down-p button))
              (was-active (eq (%button-active-widget app-state) button))
              (activate-p (and (eq mouse-button :left)
                               inside
                               (or was-active
                                   (and (null app-state) was-down)))))
         (when (eq mouse-button :left)
           (setf (menu-bar-button-pointer-down-p button) nil)
           (when was-active
             (%button-set-active-widget app-state nil))
           (when activate-p
             (%menu-bar-open-menu menu-bar app-state (menu-bar-button-entry-index button)))
           (%menu-bar-set-button-state button
                                       app-state
                                       (%menu-bar-button-release-state button x y))
           nil)))
      (:mouse-move
       (let* ((x (getf (rest event) :x))
              (y (getf (rest event) :y)))
         (%menu-bar-set-button-state button
                                     app-state
                                     (cond
                                       ((%menu-bar-button-open-p button) :pressed)
                                       ((menu-bar-button-pointer-down-p button) :pressed)
                                       ((%menu-bar-button-inside-p button x y) :hovered)
                                       (t :normal)))
         nil))
      (:mouse-leave
       (unless (menu-bar-button-pointer-down-p button)
         (%menu-bar-set-button-state button
                                     app-state
                                     (if (%menu-bar-button-open-p button)
                                         :pressed
                                         :normal)))
       nil)
      (otherwise nil))))

(defun %menu-bar-valid-entry-p (entry)
  (and (listp entry)
       (getf entry :text)
       (listp (getf entry :items))))

(defun %menu-bar-build-buttons (bar)
  (loop for entry in (menu-bar-entries bar)
        for index from 0
        collect (make-instance 'menu-bar-button
                               :menu-bar bar
                               :entry-index index
                               :text (or (getf entry :text) ""))))

(defun %menu-bar-ensure-structure (bar)
  (unless (menu-bar-buttons bar)
    (setf (menu-bar-buttons bar) (%menu-bar-build-buttons bar)))
  (unless (menu-bar-button-row bar)
    (setf (menu-bar-button-row bar)
          (make-instance 'hbox
                         :children (menu-bar-buttons bar)
                         :spacing (%non-negative-int (menu-bar-spacing bar))
                         :expand-x nil
                         :expand-y nil)))
  (unless (menu-bar-panel-surface bar)
    (setf (menu-bar-panel-surface bar)
          (handler-case
              (%menu-bar-load-panel-surface)
            (error (condition)
              (warn "Failed to load default menu bar nine-patch image (~A)" condition)
              nil))))
  (unless (menu-bar-panel bar)
    (setf (menu-bar-panel bar)
          (make-instance 'nine-patch
                         :surface (menu-bar-panel-surface bar)
                         :border-left theme:menubar-nine-patch-border-left
                         :border-right theme:menubar-nine-patch-border-right
                         :border-top theme:menubar-nine-patch-border-top
                         :border-bottom theme:menubar-nine-patch-border-bottom
                         :child (menu-bar-button-row bar)
                         :expand-x nil
                         :expand-y nil)))
  bar)

(defmethod initialize-instance :after ((bar menu-bar) &key)
  (unless (every #'%menu-bar-valid-entry-p (menu-bar-entries bar))
    (error "MenuBar entries must be plists with :text and list :items."))
  (%menu-bar-ensure-structure bar))

(defmethod measure ((bar menu-bar))
  (%menu-bar-ensure-structure bar)
  (%apply-widget-margins-to-size-request
   bar
   (measure (menu-bar-panel bar))))

(defmethod layout ((bar menu-bar) rect)
  (%menu-bar-ensure-structure bar)
  (setf (widget-layout-rect bar) (%apply-widget-margins-to-rect bar rect))
  (layout (menu-bar-panel bar) (widget-layout-rect bar))
  bar)

(defmethod render ((bar menu-bar) backend-window)
  (%menu-bar-ensure-structure bar)
  (render (menu-bar-panel bar) backend-window)
  bar)

(defmethod event-children ((bar menu-bar))
  (let ((panel (menu-bar-panel bar)))
    (if panel (list panel) nil)))

(defmethod handle-event ((bar menu-bar) app-state event)
  (declare (ignore app-state event))
  nil)

(defun %menu-bar-action-form-p (value)
  (and (consp value)
       (keywordp (first value))))

(defun %menu-bar-normalize-actions (actions)
  (cond
    ((null actions) nil)
    ((%menu-bar-action-form-p actions) (list actions))
    ((and (listp actions)
          (every #'%menu-bar-action-form-p actions))
     actions)
    (t nil)))

(defun %menu-bar-command-action-present-p (actions)
  (some (lambda (action)
          (eq (first action) :command))
        (%menu-bar-normalize-actions actions)))

(defmethod initialize-instance :after ((root menu-bar-overlay-root) &key)
  (unless (menu-bar-overlay-root-menu-widget root)
    (error "menu-bar-overlay-root requires a :menu-widget.")))

(defmethod measure ((root menu-bar-overlay-root))
  (measure (menu-bar-overlay-root-menu-widget root)))

(defmethod layout ((root menu-bar-overlay-root) rect)
  (setf (widget-layout-rect root) (%apply-widget-margins-to-rect root rect))
  (layout (menu-bar-overlay-root-menu-widget root) (widget-layout-rect root))
  root)

(defmethod render ((root menu-bar-overlay-root) backend-window)
  (render (menu-bar-overlay-root-menu-widget root) backend-window)
  root)

(defmethod event-children ((root menu-bar-overlay-root))
  (list (menu-bar-overlay-root-menu-widget root)))

(defmethod handle-event ((root menu-bar-overlay-root) app-state event)
  (let* ((menu-bar (menu-bar-overlay-root-menu-bar root))
         (menu-widget (menu-bar-overlay-root-menu-widget root))
         (event-type (first event)))
    (case event-type
      (:key-down
       (when (eq (getf (rest event) :key) :escape)
         (%menu-bar-close-open-menu menu-bar app-state)
         (return-from handle-event nil)))
      (:mouse-down
       (let* ((mouse-button (getf (rest event) :button))
              (x (getf (rest event) :x))
              (y (getf (rest event) :y))
              (inside-menu (%menu-bar-point-in-rect-p x y (widget-layout-rect menu-widget))))
         (when (and (eq mouse-button :left)
                    (not inside-menu))
           (let ((clicked-index (%menu-bar-hit-button-index menu-bar x y)))
             (if (null clicked-index)
                 (%menu-bar-close-open-menu menu-bar app-state)
                 (%menu-bar-open-menu menu-bar app-state clicked-index)))
           (return-from handle-event nil)))))
    (let ((actions (handle-event menu-widget app-state event)))
      (when (%menu-bar-command-action-present-p actions)
        (%menu-bar-close-open-menu menu-bar app-state))
      actions)))

(defun make-menu-bar (&rest entries)
  (make-instance 'menu-bar :entries entries))
