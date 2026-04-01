;; Run from project root with: sbcl --script demos/scrollbar-demo.lisp
;; shows a 600x400 scroll area inside an 800x600 window with a larger image

(load (merge-pathnames #P"../tools/tooling/demo-bootstrap.lisp"
                       (make-pathname :name nil :type nil :defaults (or *load-truename* *load-pathname*))))

(minerva.tooling.demo-bootstrap:load-minerva)

(defclass demo-fixed-size (minerva.gui:widget)
  ((child :initarg :child :accessor demo-fixed-size-child)
   (fixed-width :initarg :fixed-width :accessor demo-fixed-size-width)
   (fixed-height :initarg :fixed-height :accessor demo-fixed-size-height)))

(defmethod minerva.gui:measure ((widget demo-fixed-size))
  (minerva.gui::%apply-widget-margins-to-size-request
   widget
   (minerva.gui::%widget-size-request widget
                                      (demo-fixed-size-width widget)
                                      (demo-fixed-size-height widget)
                                      :expand-x nil
                                      :expand-y nil)))

(defmethod minerva.gui:layout ((widget demo-fixed-size) rect)
  (setf (minerva.gui:widget-layout-rect widget) (minerva.gui::%apply-widget-margins-to-rect widget rect))
  (let ((child (demo-fixed-size-child widget)))
    (when child
      (minerva.gui:layout child (minerva.gui:widget-layout-rect widget))))
  widget)

(defmethod minerva.gui:render ((widget demo-fixed-size) backend-window)
  (let ((child (demo-fixed-size-child widget)))
    (when child
      (minerva.gui:render child backend-window)))
  widget)

(defmethod minerva.gui:event-children ((widget demo-fixed-size))
  (let ((child (demo-fixed-size-child widget)))
    (if child (list child) nil)))

(defmethod minerva.gui:handle-event ((widget demo-fixed-size) app-state event)
  (declare (ignore app-state event))
  nil)

(defun run-scrollbar-demo (&key (title "Minerva Scrollbar Demo")
                                 (width 800)
                                 (height 600)
                                 (image-path "assets/images/cat.png"))
  (minerva.gfx:init-backend)
  (let* ((window (minerva.gfx:create-window :title title :width width :height height))
         (surface (minerva.gfx:load-surface image-path))
         (image-widget (make-instance 'minerva.gui:image
                                      :surface surface))
         (scroll-area (make-instance 'minerva.gui:scroll-area
                                     :child image-widget))
         (fixed-scroll-holder (make-instance 'demo-fixed-size
                                             :child scroll-area
                                             :fixed-width 600
                                             :fixed-height 400))
         (centered-layout
           (make-instance 'minerva.gui:vbox
                          :children
                          (list (make-instance 'minerva.gui:filler :expand-y t :expand-x nil)
                                (make-instance 'minerva.gui:hbox
                                       :expand-x t
                                               :children
                                               (list (make-instance 'minerva.gui:filler :expand-x t :expand-y nil)
                                                     fixed-scroll-holder
                                                     (make-instance 'minerva.gui:filler :expand-x t :expand-y nil)))
                                (make-instance 'minerva.gui:filler :expand-y t :expand-x nil))))
         (root-widget (make-instance 'minerva.gui:window
                                     :size (minerva.common:make-size :width width :height height)
                                     :child centered-layout))
         (app-state (minerva.events:make-app-state :root root-widget)))
    (unwind-protect
         (loop until (minerva.gfx:window-should-close-p window) do
           (dolist (raw-event (minerva.gfx:poll-events))
             (let ((event (minerva.events:sdl-event->minerva-event raw-event)))
               (when event
                 (minerva.events:process-minerva-event app-state event)
                 (when (minerva.events:app-state-should-quit app-state)
                   (minerva.gfx:request-window-close window)))))

           (multiple-value-bind (window-width window-height)
               (minerva.gfx:window-size window)
             (setf (minerva.gui:window-size root-widget)
                   (minerva.common:make-size :width window-width :height window-height))
             (minerva.events:layout-app-state app-state)
             (minerva.gfx:begin-frame window)
             (minerva.gfx:clear-screen window (minerva.gfx:make-color :r 18 :g 18 :b 18 :a 255))
             (minerva.events:render-app-state app-state window)
             (minerva.gfx:end-frame window))
           (minerva.gfx:sleep-ms 16))
      (minerva.gfx:destroy-surface surface)
      (minerva.gfx:destroy-window window)
      (minerva.gfx:shutdown-backend))))

(run-scrollbar-demo)
