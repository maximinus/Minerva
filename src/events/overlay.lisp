(in-package :minerva.events)

(defstruct (overlay
            (:constructor %make-overlay (&key root-widget
                                             (rect (minerva.gui:make-rect))
                                             anchor-rect
                                             (anchor-offset-x 0)
                                             (anchor-offset-y 0)
                                             (capture-all nil)
                                             (focus :pass-through)
                                             (takes-focus-p nil)
                                             (blocks-lower-input-p nil))))
  (root-widget nil)
  (rect (minerva.gui:make-rect))
  (anchor-rect nil)
  (anchor-offset-x 0)
  (anchor-offset-y 0)
  (capture-all nil)
  (focus :pass-through)
  (takes-focus-p nil)
  (blocks-lower-input-p nil))

(defun %coerce-overlay-focus (value)
  (case value
    ((:capture :pass-through :ignore) value)
    (otherwise :pass-through)))

(defun make-overlay (&key root-widget
                          (rect (minerva.gui:make-rect))
                          anchor-rect
                          (anchor-offset-x 0)
                          (anchor-offset-y 0)
                          (capture-all nil)
                          (focus :pass-through)
                          (takes-focus-p nil)
                          (blocks-lower-input-p nil))
  (%make-overlay :root-widget root-widget
                 :rect rect
                 :anchor-rect anchor-rect
                 :anchor-offset-x (truncate anchor-offset-x)
                 :anchor-offset-y (truncate anchor-offset-y)
                 :capture-all (not (null capture-all))
                 :focus (%coerce-overlay-focus focus)
                 :takes-focus-p (not (null takes-focus-p))
                 :blocks-lower-input-p (not (null blocks-lower-input-p))))

(defun overlay-stack-empty-p (state)
  (null (app-state-overlay-stack state)))

(defun top-overlay (state)
  (car (last (app-state-overlay-stack state))))

(defun push-overlay (state overlay)
  (setf (app-state-overlay-stack state)
        (append (app-state-overlay-stack state) (list overlay))
        (app-state-needs-redraw state) t)
  overlay)

(defun pop-overlay (state)
  (let ((stack (app-state-overlay-stack state)))
    (when stack
      (let ((top (car (last stack))))
        (setf (app-state-overlay-stack state) (butlast stack)
              (app-state-needs-redraw state) t)
        top))))

(defun remove-overlay (state overlay)
  (let ((before (length (app-state-overlay-stack state))))
    (setf (app-state-overlay-stack state)
          (remove overlay (app-state-overlay-stack state) :test #'eq))
    (when (< (length (app-state-overlay-stack state)) before)
      (setf (app-state-needs-redraw state) t)
      t)))

(defun %event-overlay-point (event)
  (let ((x (getf (rest event) :x))
        (y (getf (rest event) :y)))
    (if (and (numberp x) (numberp y))
        (values x y t)
        (values 0 0 nil))))

(defun %resolve-overlay-rect (overlay)
  (let* ((root-widget (overlay-root-widget overlay))
         (request (and root-widget (measure root-widget)))
         (base-rect (or (overlay-rect overlay) (minerva.gui:make-rect)))
         (anchor (overlay-anchor-rect overlay))
         (resolved-width (if (> (rect-width base-rect) 0)
                             (rect-width base-rect)
                             (if request (max 0 (truncate (minerva.gui:size-request-min-width request))) 0)))
         (resolved-height (if (> (rect-height base-rect) 0)
                              (rect-height base-rect)
                              (if request (max 0 (truncate (minerva.gui:size-request-min-height request))) 0)))
         (x (if anchor
                (+ (rect-x anchor) (truncate (overlay-anchor-offset-x overlay)))
                (rect-x base-rect)))
         (y (if anchor
                (+ (rect-y anchor)
                   (rect-height anchor)
                   (truncate (overlay-anchor-offset-y overlay)))
                (rect-y base-rect))))
    (minerva.gui:make-rect :x x :y y :width resolved-width :height resolved-height)))

(defun layout-app-state (state)
  (let ((root (app-state-root state)))
    (when root
      (let ((root-rect (minerva.gui:make-rect :x 0
                                              :y 0
                                              :width (if (typep root 'minerva.gui:window)
                                                         (max 0 (truncate (window-width root)))
                                                         (max 0 (truncate (rect-width (widget-layout-rect root)))))
                                              :height (if (typep root 'minerva.gui:window)
                                                          (max 0 (truncate (window-height root)))
                                                          (max 0 (truncate (rect-height (widget-layout-rect root))))))))
        (layout root root-rect))))
  (dolist (overlay (app-state-overlay-stack state))
    (let* ((root-widget (overlay-root-widget overlay))
           (overlay-rect (%resolve-overlay-rect overlay)))
      (setf (overlay-rect overlay) overlay-rect)
      (when root-widget
        (layout root-widget overlay-rect))))
  state)

(defun render-app-state (state backend-window)
  (%tick-app-state state)
  (let ((root (app-state-root state)))
    (when root
      (render root backend-window)))
  (dolist (overlay (app-state-overlay-stack state))
    (let ((root-widget (overlay-root-widget overlay)))
      (when root-widget
        (render root-widget backend-window))))
  state)

(defun %overlay-target-for-mouse (state event)
  (multiple-value-bind (x y has-point)
      (%event-overlay-point event)
    (when has-point
      (block decide
        (dolist (overlay (reverse (app-state-overlay-stack state)))
          (let* ((focus (overlay-focus overlay))
                 (root-widget (overlay-root-widget overlay)))
            (unless (eq focus :ignore)
              (let ((inside (%point-in-rect-p x y (overlay-rect overlay))))
                (when inside
                  (let ((target (and root-widget
                                     (widget-at-point root-widget x y))))
                    (return-from decide
                      (or target
                          (and (or (overlay-capture-all overlay)
                                   (eq focus :capture))
                               root-widget)))))
                (when (or (overlay-capture-all overlay)
                          (eq focus :capture))
                  (return-from decide
                    (or root-widget :blocked)))
                (when (overlay-blocks-lower-input-p overlay)
                  (return-from decide :blocked))))))))))

(defun %overlay-target-for-keyboard (state)
  (block decide
    (dolist (overlay (reverse (app-state-overlay-stack state)))
      (let ((focus (overlay-focus overlay)))
        (cond
          ((eq focus :ignore) nil)
          ((or (eq focus :capture)
               (overlay-takes-focus-p overlay))
           (return-from decide (or (overlay-root-widget overlay) :blocked)))
          ((overlay-blocks-lower-input-p overlay)
           (return-from decide :blocked)))))))

(defun route-minerva-event (state event)
  (let* ((root (app-state-root state))
         (focused (app-state-focused-widget state))
         (active (app-state-active-widget state))
         (type (first event)))
    (case type
      ((:window-resized :quit)
       root)
      ((:key-down :key-up :text-input)
       (let ((overlay-target (%overlay-target-for-keyboard state)))
         (if (eq overlay-target :blocked)
             nil
             (or overlay-target focused root))))
      (:mouse-up
       (let ((overlay-target (%overlay-target-for-mouse state event)))
         (cond
           ((eq overlay-target :blocked) nil)
           (overlay-target overlay-target)
           (t
            (or active
                (let ((x (getf (rest event) :x))
                      (y (getf (rest event) :y)))
                  (or (and (numberp x)
                           (numberp y)
                           root
                           (widget-at-point root x y))
                      root)))))))
      ((:mouse-move :mouse-down)
       (let ((overlay-target (%overlay-target-for-mouse state event)))
         (cond
           ((eq overlay-target :blocked) nil)
           (overlay-target overlay-target)
           (t
            (let ((x (getf (rest event) :x))
                  (y (getf (rest event) :y)))
              (or (and (numberp x)
                       (numberp y)
                       root
                       (widget-at-point root x y))
                  root))))))
      (otherwise nil))))

(defun %walk-widget-tree (root fn)
  (labels ((visit (widget)
             (when widget
               (funcall fn widget)
               (dolist (child (event-children widget))
                 (visit child)))))
    (visit root)))

(defun %tick-app-state (state)
  (let ((ticks-fn (minerva.gui::%gfx-function "TICKS-MS")))
    (when ticks-fn
      (let ((now-ms (funcall ticks-fn)))
        (%walk-widget-tree (app-state-root state)
                           (lambda (widget)
                             (minerva.gui:tick-widget widget state now-ms)))
        (dolist (overlay (app-state-overlay-stack state))
          (%walk-widget-tree (overlay-root-widget overlay)
                             (lambda (widget)
                               (minerva.gui:tick-widget widget state now-ms))))))))

(defun %update-hovered-widget (state event)
  (when (eq (first event) :mouse-move)
    (let* ((previous (app-state-hovered-widget state))
           (current (route-minerva-event state event)))
      (unless (eq previous current)
        (when previous
          (process-actions state (handle-event previous state '(:mouse-leave))))
        (setf (app-state-hovered-widget state) current))))
  state)

(defun process-minerva-event (state event)
  (%apply-app-state-event-updates state event)
  (%update-hovered-widget state event)
  (let* ((target (route-minerva-event state event))
         (result (and target (handle-event target state event))))
    (when (and (eq (first event) :mouse-down)
               (eq (getf (rest event) :button) :left)
               (not (eq target (app-state-focused-widget state))))
      (set-focused-widget state nil))
    (process-actions state result)
    target))

