(in-package :minerva.gui)

(defparameter *button-border-size* 4)

(defclass button (widget)
  ((text :initarg :text :accessor button-text :initform "")
  (command :initarg :command :accessor button-command :initform nil)
  (padding :initarg :padding :reader button-padding :initform nil)
  (font-name :initarg :font-name :accessor button-font-name :initform theme:default-font)
  (text-size :initarg :text-size :accessor button-text-size :initform theme:default-font-size)
  (color :initarg :color :accessor button-color :initform theme:default-font-color)
   (padding-x :initarg :padding-x :accessor button-padding-x :initform 0)
   (padding-y :initarg :padding-y :accessor button-padding-y :initform 0)
   (state :initarg :state :accessor button-state :initform :normal)
   (pointer-down-p :accessor button-pointer-down-p :initform nil)
   (normal-surface :initarg :normal-surface :accessor button-normal-surface :initform nil)
   (highlighted-surface :initarg :highlighted-surface :accessor button-highlighted-surface :initform nil)
   (pressed-surface :initarg :pressed-surface :accessor button-pressed-surface :initform nil)
   (text-surface :accessor button-text-surface :initform nil)
   (text-draw-rect :accessor button-text-draw-rect :initform (make-rect))))

  (defmethod initialize-instance :around ((btn button)
                 &rest initargs
                 &key padding padding-x padding-y
                 &allow-other-keys)
    (apply #'call-next-method btn initargs)
    (let* ((base-padding (%coerce-size padding))
      (final-padding-x (if (null padding-x) (size-width base-padding) padding-x))
      (final-padding-y (if (null padding-y) (size-height base-padding) padding-y)))
      (setf (button-padding-x btn) (%non-negative-int final-padding-x)
       (button-padding-y btn) (%non-negative-int final-padding-y))))

(defun %button-project-root ()
  (or (ignore-errors (asdf:system-source-directory "minerva"))
      (truename "./")))

(defun %button-theme-path (state)
  (case state
    (:normal theme:button-nine-patch-normal)
    (:highlighted theme:button-nine-patch-highlight)
    (:pressed theme:button-nine-patch-pressed)
    (otherwise (error "Invalid button state ~S" state))))

(defun %button-normalize-path (path)
  (if (and (stringp path)
           (> (length path) 0)
           (char= (char path 0) #\/))
      (subseq path 1)
      path))

(defun %button-state-surface-path (state)
  (%button-normalize-path (%button-theme-path state)))

(defun %button-color-components (color)
  (destructuring-bind (r g b &optional (a 255))
      (if (listp color)
          color
          (list (color-r color)
                (color-g color)
                (color-b color)
                (color-a color)))
    (values r g b a)))

(defun %button-load-surface (path)
  (let ((load-fn (%gfx-function "LOAD-SURFACE")))
    (unless load-fn
      (error "minerva.gfx:load-surface is unavailable. Load src/gfx/ffi.lisp and src/gfx/backend.lisp first."))
    (funcall load-fn path)))

(defun %button-render-text-surface (font-name text-size text color)
  (let ((get-font-fn (%gfx-function "GET-FONT"))
        (destroy-font-fn (%gfx-function "DESTROY-FONT"))
        (render-text-fn (%gfx-function "RENDER-TEXT-TO-SURFACE"))
        (make-color-fn (%gfx-function "MAKE-COLOR")))
    (unless (and get-font-fn destroy-font-fn render-text-fn make-color-fn)
      (error "minerva.gfx text rendering functions are unavailable. Load src/gfx/ffi.lisp and src/gfx/backend.lisp first."))
    (let ((font nil))
      (unwind-protect
           (progn
             (setf font (funcall get-font-fn (%label-font-path font-name) (max 1 (%non-negative-int text-size))))
             (multiple-value-bind (r g b a)
                 (%button-color-components color)
               (funcall render-text-fn
                        font
                        (or text "")
                        (funcall make-color-fn :r r :g g :b b :a a))))
        (when font
          (funcall destroy-font-fn font))))))

(defun %button-point-in-rect-p (x y rect)
  (and (numberp x)
       (numberp y)
       (>= x (rect-x rect))
       (>= y (rect-y rect))
       (< x (+ (rect-x rect) (rect-width rect)))
       (< y (+ (rect-y rect) (rect-height rect)))))

(defun %events-accessor (name)
  (let* ((events-package (find-package :minerva.events))
         (symbol (and events-package (find-symbol name events-package))))
    (and symbol
         (fboundp symbol)
         (symbol-function symbol))))

(defun %button-app-state-value (app-state accessor-name)
  (let ((accessor (%events-accessor accessor-name)))
    (when (and app-state accessor)
      (funcall accessor app-state))))

(defun %set-button-app-state-value (app-state accessor-name value)
  (let* ((events-package (find-package :minerva.events))
         (symbol (and events-package (find-symbol accessor-name events-package)))
         (setter-name (and symbol (list 'setf symbol)))
         (setter (and setter-name (fboundp setter-name) (fdefinition setter-name))))
    (when (and app-state setter)
      (funcall setter value app-state)))
  value)

(defun %button-mark-redraw (app-state)
  (%set-button-app-state-value app-state "APP-STATE-NEEDS-REDRAW" t))

(defun %button-active-widget (app-state)
  (%button-app-state-value app-state "APP-STATE-ACTIVE-WIDGET"))

(defun %button-set-active-widget (app-state widget)
  (%set-button-app-state-value app-state "APP-STATE-ACTIVE-WIDGET" widget))

(defun %button-set-state (btn app-state state)
  (unless (eq (button-state btn) state)
    (setf (button-state btn) state)
    (%button-mark-redraw app-state))
  state)

(defun %button-state-surface (btn)
  (case (button-state btn)
    (:normal (button-normal-surface btn))
    (:highlighted (button-highlighted-surface btn))
    (:pressed (button-pressed-surface btn))
    (otherwise (button-normal-surface btn))))

(defun %button-text-placement (btn)
  (let* ((layout-rect (widget-layout-rect btn))
         (text-surface (button-text-surface btn))
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

(defun %render-button-background (btn backend-window)
  (let* ((surface (%button-state-surface btn))
         (outer (widget-layout-rect btn)))
    (when surface
      (let* ((src-width (%surface-width surface))
             (src-height (%surface-height surface))
             (dst-width (rect-width outer))
             (dst-height (rect-height outer))
             (src-x-segments (multiple-value-list
                              (%patch-segment src-width *button-border-size* *button-border-size*)))
             (src-y-segments (multiple-value-list
                              (%patch-segment src-height *button-border-size* *button-border-size*)))
             (dst-x-segments (multiple-value-list
                              (%patch-segment dst-width *button-border-size* *button-border-size*)))
             (dst-y-segments (multiple-value-list
                              (%patch-segment dst-height *button-border-size* *button-border-size*))))
        (destructuring-bind (src-left src-center src-right) src-x-segments
          (destructuring-bind (src-top src-middle src-bottom) src-y-segments
            (destructuring-bind (dst-left dst-center dst-right) dst-x-segments
              (destructuring-bind (dst-top dst-middle dst-bottom) dst-y-segments
                (let* ((sx0 0)
                       (sx1 src-left)
                       (sx2 (+ src-left src-center))
                       (sy0 0)
                       (sy1 src-top)
                       (sy2 (+ src-top src-middle))
                       (dx0 (rect-x outer))
                       (dx1 (+ (rect-x outer) dst-left))
                       (dx2 (+ (rect-x outer) dst-left dst-center))
                       (dy0 (rect-y outer))
                       (dy1 (+ (rect-y outer) dst-top))
                       (dy2 (+ (rect-y outer) dst-top dst-middle)))
                  (%render-nine-patch-part backend-window
                                           surface
                                           (make-position :x sx0 :y sy0)
                                           (make-size :width src-left :height src-top)
                                           (make-position :x dx0 :y dy0)
                                           (make-size :width dst-left :height dst-top))
                  (%render-nine-patch-part backend-window
                                           surface
                                           (make-position :x sx1 :y sy0)
                                           (make-size :width src-center :height src-top)
                                           (make-position :x dx1 :y dy0)
                                           (make-size :width dst-center :height dst-top))
                  (%render-nine-patch-part backend-window
                                           surface
                                           (make-position :x sx2 :y sy0)
                                           (make-size :width src-right :height src-top)
                                           (make-position :x dx2 :y dy0)
                                           (make-size :width dst-right :height dst-top))
                  (%render-nine-patch-part backend-window
                                           surface
                                           (make-position :x sx0 :y sy1)
                                           (make-size :width src-left :height src-middle)
                                           (make-position :x dx0 :y dy1)
                                           (make-size :width dst-left :height dst-middle))
                  (%render-nine-patch-part backend-window
                                           surface
                                           (make-position :x sx1 :y sy1)
                                           (make-size :width src-center :height src-middle)
                                           (make-position :x dx1 :y dy1)
                                           (make-size :width dst-center :height dst-middle))
                  (%render-nine-patch-part backend-window
                                           surface
                                           (make-position :x sx2 :y sy1)
                                           (make-size :width src-right :height src-middle)
                                           (make-position :x dx2 :y dy1)
                                           (make-size :width dst-right :height dst-middle))
                  (%render-nine-patch-part backend-window
                                           surface
                                           (make-position :x sx0 :y sy2)
                                           (make-size :width src-left :height src-bottom)
                                           (make-position :x dx0 :y dy2)
                                           (make-size :width dst-left :height dst-bottom))
                  (%render-nine-patch-part backend-window
                                           surface
                                           (make-position :x sx1 :y sy2)
                                           (make-size :width src-center :height src-bottom)
                                           (make-position :x dx1 :y dy2)
                                           (make-size :width dst-center :height dst-bottom))
                  (%render-nine-patch-part backend-window
                                           surface
                                           (make-position :x sx2 :y sy2)
                                           (make-size :width src-right :height src-bottom)
                                           (make-position :x dx2 :y dy2)
                                           (make-size :width dst-right :height dst-bottom)))))))))))

(defmethod initialize-instance :after ((btn button) &key)
  (setf (button-padding-x btn) (%non-negative-int (button-padding-x btn))
        (button-padding-y btn) (%non-negative-int (button-padding-y btn)))
  (unless (button-normal-surface btn)
    (setf (button-normal-surface btn)
          (%button-load-surface (%button-state-surface-path :normal))))
  (unless (button-highlighted-surface btn)
    (setf (button-highlighted-surface btn)
          (%button-load-surface (%button-state-surface-path :highlighted))))
  (unless (button-pressed-surface btn)
    (setf (button-pressed-surface btn)
          (%button-load-surface (%button-state-surface-path :pressed))))
  (setf (button-text-surface btn)
        (%button-render-text-surface (button-font-name btn)
                                     (button-text-size btn)
                                     (button-text btn)
                                     (button-color btn))))

(defmethod measure ((btn button))
  (let* ((text-width (%surface-width (button-text-surface btn)))
         (text-height (%surface-height (button-text-surface btn)))
         (padded-width (+ text-width (* 2 (%non-negative-int (button-padding-x btn)))))
         (padded-height (+ text-height (* 2 (%non-negative-int (button-padding-y btn))))))
    (%apply-widget-margins-to-size-request
     btn
    (%widget-size-request btn
              (+ padded-width (* 2 *button-border-size*))
              (+ padded-height (* 2 *button-border-size*))
              :expand-x nil
              :expand-y nil))))

(defmethod layout ((btn button) rect)
  (setf (widget-layout-rect btn) (%apply-widget-margins-to-rect btn rect))
  (multiple-value-bind (dest-rect source-rect)
      (%button-text-placement btn)
    (declare (ignore source-rect))
    (setf (button-text-draw-rect btn) dest-rect))
  btn)

(defmethod render ((btn button) backend-window)
  (%render-button-background btn backend-window)
  (let ((surface (button-text-surface btn)))
    (when surface
      (multiple-value-bind (dest-rect source-rect)
          (%button-text-placement btn)
        (setf (button-text-draw-rect btn) dest-rect)
        (when (and (> (rect-width dest-rect) 0)
                   (> (rect-height dest-rect) 0))
          (%call-draw-surface-rect backend-window
                                   surface
                                   source-rect
                                   (rect-x dest-rect)
                                   (rect-y dest-rect))))))
  btn)

(defmethod handle-event ((btn button) app-state event)
  (case (first event)
    (:mouse-down
     (let* ((button (getf (rest event) :button))
            (x (getf (rest event) :x))
            (y (getf (rest event) :y))
            (inside (%button-point-in-rect-p x y (widget-layout-rect btn))))
       (when (and (eq button :left) inside)
         (setf (button-pointer-down-p btn) t)
         (%button-set-active-widget app-state btn)
         (%button-set-state btn app-state :pressed)
         nil)))
    (:mouse-up
     (let* ((button (getf (rest event) :button))
            (x (getf (rest event) :x))
            (y (getf (rest event) :y))
            (inside (%button-point-in-rect-p x y (widget-layout-rect btn)))
            (was-down (button-pointer-down-p btn))
            (was-active (eq (%button-active-widget app-state) btn))
            (activate-p (and (eq button :left)
                             inside
                             (or was-active
                                 (and (null app-state) was-down)))))
       (when (eq button :left)
         (setf (button-pointer-down-p btn) nil)
         (when was-active
           (%button-set-active-widget app-state nil))
         (%button-set-state btn app-state (if inside :highlighted :normal))
         (when (and activate-p (button-command btn))
           (list (list :command (button-command btn)))))))
    (:mouse-move
     (let* ((x (getf (rest event) :x))
            (y (getf (rest event) :y))
            (inside (%button-point-in-rect-p x y (widget-layout-rect btn))))
       (%button-set-state btn app-state
                          (if (button-pointer-down-p btn)
                              :pressed
                              (if inside :highlighted :normal)))
       nil))
    (:mouse-leave
     (unless (button-pointer-down-p btn)
       (%button-set-state btn app-state :normal))
     nil)
    (otherwise nil)))