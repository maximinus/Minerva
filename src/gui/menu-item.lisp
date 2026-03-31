(in-package :minerva.gui)

(defclass menu-item (widget)
  ((id :initarg :id :accessor menu-item-id :initform nil)
   (text :initarg :text :accessor menu-item-text :initform "")
   (command :initarg :command :accessor menu-item-command :initform nil)
   (icon :initarg :icon :accessor menu-item-icon :initform nil)
   (key-text :initarg :key-text :accessor menu-item-key-text :initform nil)
  (font-name :initarg :font-name :accessor menu-item-font-name :initform theme:default-font)
  (text-size :initarg :text-size :accessor menu-item-text-size :initform theme:default-font-size)
  (text-color :initarg :text-color :accessor menu-item-text-color :initform theme:default-font-color)
  (key-text-color :initarg :key-text-color :accessor menu-item-key-text-color :initform theme:default-font-color)
   (highlighted-color :initarg :highlighted-color :accessor menu-item-highlighted-color :initform theme:default-menu-background-highlight)
   (padding-x :initarg :padding-x :accessor menu-item-padding-x :initform 8)
   (padding-y :initarg :padding-y :accessor menu-item-padding-y :initform 6)
   (icon-label-gap :initarg :icon-label-gap :accessor menu-item-icon-label-gap :initform 8)
   (label-key-gap :initarg :label-key-gap :accessor menu-item-label-key-gap :initform 12)
   (state :initarg :state :accessor menu-item-state :initform :normal)
   (pointer-down-p :accessor menu-item-pointer-down-p :initform nil)
   (icon-surface :initarg :icon-surface :accessor menu-item-icon-surface :initform nil)
   (label-surface :accessor menu-item-label-surface :initform nil)
   (key-surface :accessor menu-item-key-surface :initform nil)
   (icon-draw-rect :accessor menu-item-icon-draw-rect :initform (make-rect))
   (label-draw-rect :accessor menu-item-label-draw-rect :initform (make-rect))
   (key-draw-rect :accessor menu-item-key-draw-rect :initform (make-rect))
   (icon-column-width :initarg :icon-column-width :accessor menu-item-icon-column-width :initform nil)
   (label-column-width :initarg :label-column-width :accessor menu-item-label-column-width :initform nil)
   (key-column-width :initarg :key-column-width :accessor menu-item-key-column-width :initform nil)))

(defun %menu-item-point-in-rect-p (x y rect)
  (and (numberp x)
       (numberp y)
       (>= x (rect-x rect))
       (>= y (rect-y rect))
       (< x (+ (rect-x rect) (rect-width rect)))
       (< y (+ (rect-y rect) (rect-height rect)))))

(defun %menu-item-app-state-value (app-state accessor-name)
  (%button-app-state-value app-state accessor-name))

(defun %menu-item-set-app-state-value (app-state accessor-name value)
  (%set-button-app-state-value app-state accessor-name value))

(defun %menu-item-mark-redraw (app-state)
  (%menu-item-set-app-state-value app-state "APP-STATE-NEEDS-REDRAW" t))

(defun %menu-item-active-widget (app-state)
  (%menu-item-app-state-value app-state "APP-STATE-ACTIVE-WIDGET"))

(defun %menu-item-set-active-widget (app-state widget)
  (%menu-item-set-app-state-value app-state "APP-STATE-ACTIVE-WIDGET" widget))

(defun %menu-item-set-state (item app-state state)
  (unless (eq (menu-item-state item) state)
    (setf (menu-item-state item) state)
    (%menu-item-mark-redraw app-state))
  state)

(defun %menu-item-icon-width (item)
  (%surface-width (menu-item-icon-surface item)))

(defun %menu-item-icon-height (item)
  (%surface-height (menu-item-icon-surface item)))

(defun %menu-item-label-width (item)
  (%surface-width (menu-item-label-surface item)))

(defun %menu-item-label-height (item)
  (%surface-height (menu-item-label-surface item)))

(defun %menu-item-key-width (item)
  (%surface-width (menu-item-key-surface item)))

(defun %menu-item-key-height (item)
  (%surface-height (menu-item-key-surface item)))

(defun %menu-item-column-width (configured actual)
  (if (numberp configured)
      (%non-negative-int configured)
      (%non-negative-int actual)))

(defmethod initialize-instance :after ((item menu-item) &key)
  (setf (menu-item-padding-x item) (%non-negative-int (menu-item-padding-x item))
        (menu-item-padding-y item) (%non-negative-int (menu-item-padding-y item))
        (menu-item-icon-label-gap item) (%non-negative-int (menu-item-icon-label-gap item))
        (menu-item-label-key-gap item) (%non-negative-int (menu-item-label-key-gap item)))
  (unless (menu-item-icon-surface item)
    (let ((icon (menu-item-icon item)))
      (when (and (listp icon)
                 (getf icon :width)
                 (getf icon :height))
        (setf (menu-item-icon-surface item) icon))))
  (setf (menu-item-label-surface item)
        (%render-label-text-surface (menu-item-font-name item)
                                    (menu-item-text-size item)
                                    (menu-item-text item)
                                    (menu-item-text-color item)))
  (when (menu-item-key-text item)
    (setf (menu-item-key-surface item)
          (%render-label-text-surface (menu-item-font-name item)
                                      (menu-item-text-size item)
                                      (menu-item-key-text item)
                                      (menu-item-key-text-color item)))))

(defmethod measure ((item menu-item))
  (let* ((icon-width (%menu-item-column-width (menu-item-icon-column-width item)
                                              (%menu-item-icon-width item)))
         (label-width (%menu-item-column-width (menu-item-label-column-width item)
                                               (%menu-item-label-width item)))
         (key-width (%menu-item-column-width (menu-item-key-column-width item)
                                             (%menu-item-key-width item)))
         (padding-x (%non-negative-int (menu-item-padding-x item)))
         (padding-y (%non-negative-int (menu-item-padding-y item)))
         (icon-gap (if (> icon-width 0) (%non-negative-int (menu-item-icon-label-gap item)) 0))
         (key-gap (if (> key-width 0) (%non-negative-int (menu-item-label-key-gap item)) 0))
         (content-width (+ icon-width icon-gap label-width key-gap key-width))
         (content-height (max (%menu-item-icon-height item)
                              (%menu-item-label-height item)
                              (%menu-item-key-height item))))
    (%apply-widget-margins-to-size-request
     item
      (%widget-size-request item
                (+ (* 2 padding-x) content-width)
                (+ (* 2 padding-y) content-height)
                :expand-x t
                :expand-y nil))))

(defmethod layout ((item menu-item) rect)
  (setf (widget-layout-rect item) (%apply-widget-margins-to-rect item rect))
  (let* ((inner (widget-layout-rect item))
         (padding-x (%non-negative-int (menu-item-padding-x item)))
         (padding-y (%non-negative-int (menu-item-padding-y item)))
         (content-left (+ (rect-x inner) padding-x))
         (content-right (- (+ (rect-x inner) (rect-width inner)) padding-x))
         (content-top (+ (rect-y inner) padding-y))
         (content-height (max 0 (- (rect-height inner) (* 2 padding-y))))
         (icon-col-width (%menu-item-column-width (menu-item-icon-column-width item)
                                                  (%menu-item-icon-width item)))
         (label-col-width (%menu-item-column-width (menu-item-label-column-width item)
                                                   (%menu-item-label-width item)))
         (key-col-width (%menu-item-column-width (menu-item-key-column-width item)
                                                 (%menu-item-key-width item)))
         (icon-gap (if (> icon-col-width 0) (%non-negative-int (menu-item-icon-label-gap item)) 0))
         (key-gap (if (> key-col-width 0) (%non-negative-int (menu-item-label-key-gap item)) 0))
         (icon-area-x content-left)
         (label-area-x (+ icon-area-x icon-col-width icon-gap))
         (key-area-x (if (> key-col-width 0)
                         (- content-right key-col-width)
                         content-right))
         (label-area-width (max 0 (- key-area-x key-gap label-area-x)))
         (row-center-y (+ content-top (floor content-height 2)))
         (icon-width (%menu-item-icon-width item))
         (icon-height (%menu-item-icon-height item))
         (icon-draw-x (+ icon-area-x (max 0 (floor (- icon-col-width icon-width) 2))))
         (icon-draw-y (+ content-top (max 0 (floor (- content-height icon-height) 2))))
         (label-width (min (%menu-item-label-width item) label-area-width))
         (label-height (%menu-item-label-height item))
         (label-draw-y (- row-center-y (floor label-height 2)))
         (key-width (min (%menu-item-key-width item) key-col-width))
         (key-height (%menu-item-key-height item))
         (key-draw-x (+ key-area-x (max 0 (- key-col-width key-width))))
         (key-draw-y (- row-center-y (floor key-height 2))))
    (setf (menu-item-icon-draw-rect item)
          (if (and (> icon-width 0) (> icon-height 0))
              (make-rect :x icon-draw-x
                         :y icon-draw-y
                         :width (min icon-width icon-col-width)
                         :height (min icon-height content-height))
              (make-rect :x icon-area-x :y content-top :width 0 :height 0)))
    (setf (menu-item-label-draw-rect item)
          (if (and (> label-width 0) (> label-height 0))
              (make-rect :x label-area-x
                         :y label-draw-y
                         :width label-width
                         :height (min label-height content-height))
              (make-rect :x label-area-x :y content-top :width 0 :height 0)))
    (setf (menu-item-key-draw-rect item)
          (if (and (> key-width 0) (> key-height 0) (> key-col-width 0))
              (make-rect :x key-draw-x
                         :y key-draw-y
                         :width key-width
                         :height (min key-height content-height))
              (make-rect :x key-area-x :y content-top :width 0 :height 0))))
  item)

(defun %menu-item-draw-surface-at-rect (backend-window surface draw-rect)
  (when (and surface
             (> (rect-width draw-rect) 0)
             (> (rect-height draw-rect) 0))
    (%call-draw-surface-rect backend-window
                             surface
                             (make-rect :x 0
                                        :y 0
                                        :width (rect-width draw-rect)
                                        :height (rect-height draw-rect))
                             (rect-x draw-rect)
                             (rect-y draw-rect))))

(defmethod render ((item menu-item) backend-window)
  (when (member (menu-item-state item) '(:hovered :pressed))
    (%call-fill-rect backend-window
                     (widget-layout-rect item)
                     (menu-item-highlighted-color item)))
  (%menu-item-draw-surface-at-rect backend-window
                                   (menu-item-icon-surface item)
                                   (menu-item-icon-draw-rect item))
  (%menu-item-draw-surface-at-rect backend-window
                                   (menu-item-label-surface item)
                                   (menu-item-label-draw-rect item))
  (%menu-item-draw-surface-at-rect backend-window
                                   (menu-item-key-surface item)
                                   (menu-item-key-draw-rect item))
  item)

(defmethod handle-event ((item menu-item) app-state event)
  (case (first event)
    (:mouse-down
     (let* ((button (getf (rest event) :button))
            (x (getf (rest event) :x))
            (y (getf (rest event) :y))
            (inside (%menu-item-point-in-rect-p x y (widget-layout-rect item))))
       (when (and (eq button :left) inside)
         (setf (menu-item-pointer-down-p item) t)
         (%menu-item-set-active-widget app-state item)
         (%menu-item-set-state item app-state :pressed)
         nil)))
    (:mouse-up
     (let* ((button (getf (rest event) :button))
            (x (getf (rest event) :x))
            (y (getf (rest event) :y))
            (inside (%menu-item-point-in-rect-p x y (widget-layout-rect item)))
            (was-down (menu-item-pointer-down-p item))
            (was-active (eq (%menu-item-active-widget app-state) item))
            (activate-p (and (eq button :left)
                             inside
                             (or was-active
                                 (and (null app-state) was-down)))))
       (when (eq button :left)
         (setf (menu-item-pointer-down-p item) nil)
         (when was-active
           (%menu-item-set-active-widget app-state nil))
         (%menu-item-set-state item app-state (if inside :hovered :normal))
         (when (and activate-p (menu-item-command item))
           (when app-state
             (ignore-errors
               (let ((close-fn (and (fboundp 'minerva.gui::%menu-bar-close-from-app-state)
                                    (symbol-function 'minerva.gui::%menu-bar-close-from-app-state))))
                 (when close-fn
                   (funcall close-fn app-state)))))
           (list (list :command (menu-item-command item)))))))
    (:mouse-move
     (let* ((x (getf (rest event) :x))
            (y (getf (rest event) :y))
            (inside (%menu-item-point-in-rect-p x y (widget-layout-rect item))))
       (%menu-item-set-state item app-state
                             (if (menu-item-pointer-down-p item)
                                 :pressed
                                 (if inside :hovered :normal)))
       nil))
    (:mouse-leave
     (unless (menu-item-pointer-down-p item)
       (%menu-item-set-state item app-state :normal))
     nil)
    (otherwise nil)))