(in-package :minerva.gui)

(defclass menu (widget)
  ((entries :initarg :entries :accessor menu-entries :initform nil)
   (children :initarg :children :accessor menu-children :initform nil)
   (spacing :initarg :spacing :accessor menu-spacing :initform 0)
   (icon-resolver :initarg :icon-resolver :accessor menu-icon-resolver :initform nil)
   (panel-surface :initarg :panel-surface :accessor menu-panel-surface :initform nil)
  (border-left :initarg :border-left :accessor menu-border-left :initform theme:menu-nine-patch-border-left)
  (border-right :initarg :border-right :accessor menu-border-right :initform theme:menu-nine-patch-border-right)
  (border-top :initarg :border-top :accessor menu-border-top :initform theme:menu-nine-patch-border-top)
  (border-bottom :initarg :border-bottom :accessor menu-border-bottom :initform theme:menu-nine-patch-border-bottom)
   (icon-column-width :accessor menu-icon-column-width :initform 0)
   (label-column-width :accessor menu-label-column-width :initform 0)
   (key-column-width :accessor menu-key-column-width :initform 0)
   (content-box :accessor menu-content-box :initform nil)
   (panel :accessor menu-panel :initform nil)))

(defun %menu-default-panel-path ()
  (if (and (stringp theme:menu-nine-patch)
           (> (length theme:menu-nine-patch) 0)
           (char= (char theme:menu-nine-patch 0) #\/))
      (subseq theme:menu-nine-patch 1)
      theme:menu-nine-patch))

(defun %menu-load-default-panel-surface ()
  (let ((load-fn (%gfx-function "LOAD-SURFACE")))
    (unless load-fn
      (error "minerva.gfx:load-surface is unavailable. Load src/gfx/ffi.lisp and src/gfx/backend.lisp first."))
    (funcall load-fn (%menu-default-panel-path))))

(defun %menu-entry-spacer-p (entry)
  (or (eq entry :spacer)
      (eq entry 'spacer)
      (eq entry '(:spacer))))

(defun %menu-entry-plist-p (entry)
  (and (listp entry)
       (evenp (length entry))
       (every #'keywordp (loop for (key value) on entry by #'cddr
                               collect key))))

(defun %menu-coerce-icon-surface (menu icon-value)
  (cond
    ((null icon-value) nil)
    ((and (listp icon-value)
          (getf icon-value :width)
          (getf icon-value :height))
     icon-value)
    ((functionp (menu-icon-resolver menu))
     (funcall (menu-icon-resolver menu) icon-value))
    (t nil)))

(defun %make-menu-item-from-entry (menu entry)
  (unless (%menu-entry-plist-p entry)
    (error "Invalid menu entry ~S. Expected plist or :spacer." entry))
  (let* ((key-text (or (getf entry :key-text) (getf entry :key)))
         (icon-value (getf entry :icon))
         (icon-surface (%menu-coerce-icon-surface menu icon-value)))
    (make-instance 'menu-item
                   :id (getf entry :id)
                   :text (or (getf entry :text) "")
                   :command (getf entry :command)
                   :icon icon-value
                   :icon-surface icon-surface
                   :key-text key-text
                   :font-name (or (getf entry :font-name) theme:default-font)
                   :text-size (or (getf entry :text-size) theme:default-font-size)
                   :text-color (or (getf entry :text-color) theme:default-font-color)
                   :key-text-color (or (getf entry :key-text-color) theme:default-font-color)
                   :highlighted-color (or (getf entry :highlighted-color) theme:default-menu-background-highlight))))

(defun %menu-build-children (menu entries)
  (loop for entry in entries
        collect (if (%menu-entry-spacer-p entry)
                    (make-instance 'menu-spacer)
                    (%make-menu-item-from-entry menu entry))))

(defun %menu-column-metrics (menu)
  (let ((max-icon 0)
        (max-label 0)
        (max-key 0))
    (dolist (child (menu-children menu))
      (when (typep child 'menu-item)
        (setf max-icon (max max-icon (%menu-item-icon-width child))
              max-label (max max-label (%menu-item-label-width child))
              max-key (max max-key (%menu-item-key-width child)))))
    (values max-icon max-label max-key)))

(defun %menu-apply-column-widths (menu)
  (multiple-value-bind (icon-width label-width key-width)
      (%menu-column-metrics menu)
    (setf (menu-icon-column-width menu) icon-width
          (menu-label-column-width menu) label-width
          (menu-key-column-width menu) key-width)
    (dolist (child (menu-children menu))
      (when (typep child 'menu-item)
        (setf (menu-item-icon-column-width child) icon-width
              (menu-item-label-column-width child) label-width
              (menu-item-key-column-width child) key-width)))))

(defun %menu-ensure-structure (menu)
  (unless (menu-children menu)
    (setf (menu-children menu)
          (%menu-build-children menu (menu-entries menu))))
  (unless (menu-content-box menu)
    (setf (menu-content-box menu)
          (make-instance 'vbox
                         :children (menu-children menu)
                         :spacing (max 0 (%non-negative-int (menu-spacing menu)))
                         :expand-x nil
                         :expand-y nil)))
  (unless (menu-panel menu)
    (when (null (menu-panel-surface menu))
      (setf (menu-panel-surface menu)
            (handler-case
                (%menu-load-default-panel-surface)
              (error (condition)
                (warn "Failed to load default menu nine-patch image at ~A (~A)"
                      (%menu-default-panel-path)
                      condition)
                nil))))
    (setf (menu-panel menu)
          (make-instance 'nine-patch
                         :surface (menu-panel-surface menu)
                         :border-left (%non-negative-int (menu-border-left menu))
                         :border-right (%non-negative-int (menu-border-right menu))
                         :border-top (%non-negative-int (menu-border-top menu))
                         :border-bottom (%non-negative-int (menu-border-bottom menu))
                         :child (menu-content-box menu)
             :expand-x nil
                         :expand-y nil))))

(defmethod initialize-instance :after ((menu menu) &key)
  (%menu-ensure-structure menu)
  (%menu-apply-column-widths menu))

(defmethod measure ((menu menu))
  (%menu-ensure-structure menu)
  (%menu-apply-column-widths menu)
  (%apply-widget-margins-to-size-request
   menu
   (measure (menu-panel menu))))

(defmethod layout ((menu menu) rect)
  (%menu-ensure-structure menu)
  (%menu-apply-column-widths menu)
  (setf (widget-layout-rect menu) (%apply-widget-margins-to-rect menu rect))
  (layout (menu-panel menu) (widget-layout-rect menu))
  menu)

(defmethod render ((menu menu) backend-window)
  (%menu-ensure-structure menu)
  (render (menu-panel menu) backend-window)
  menu)

(defmethod event-children ((menu menu))
  (let ((panel (menu-panel menu)))
    (if panel (list panel) nil)))

(defmethod handle-event ((menu menu) app-state event)
  (declare (ignore app-state event))
  nil)

(defun make-menu (&rest entries)
  (make-instance 'menu :entries entries))