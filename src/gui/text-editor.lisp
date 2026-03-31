(in-package :minerva.gui)

(defparameter *text-editor-default-min-width* 200)
(defparameter *text-editor-default-text-size* theme:default-font-size)

(defclass text-editor (widget)
  ((text :initarg :text :accessor text-editor-text :initform "")
   (caret-position :initarg :caret-position :accessor text-editor-caret-position :initform 0)
   (focused-p :initarg :focused-p :accessor text-editor-focused-p :initform nil)
   (caret-visible-p :initarg :caret-visible-p :accessor text-editor-caret-visible-p :initform nil)
   (last-blink-ms :initarg :last-blink-ms :accessor text-editor-last-blink-ms :initform 0)
   (blink-interval-ms :initarg :blink-interval-ms :accessor text-editor-blink-interval-ms :initform 500)
   (font-name :initarg :font-name :accessor text-editor-font-name :initform theme:default-font)
   (text-size :initarg :text-size :accessor text-editor-text-size :initform *text-editor-default-text-size*)
   (text-color :initarg :text-color :accessor text-editor-text-color :initform theme:default-font-color)
   (caret-color :initarg :caret-color :accessor text-editor-caret-color :initform '(20 20 20 255))
   (padding-x :initarg :padding-x :accessor text-editor-padding-x :initform 6)
   (padding-y :initarg :padding-y :accessor text-editor-padding-y :initform 4)
   (min-width :initarg :min-width :accessor text-editor-min-width :initform *text-editor-default-min-width*)
   (min-height :initarg :min-height :accessor text-editor-min-height :initform 0)
   (text-surface :accessor text-editor-text-surface :initform nil)
  (surface-text-cache :accessor text-editor-surface-text-cache :initform nil))
  (:default-initargs
  :background-color '(245 245 245 255)))

(defmethod initialize-instance :after ((editor text-editor) &key)
  (setf (text-editor-text editor) (or (text-editor-text editor) "")
        (text-editor-padding-x editor) (%non-negative-int (text-editor-padding-x editor))
        (text-editor-padding-y editor) (%non-negative-int (text-editor-padding-y editor))
        (text-editor-min-width editor) (%non-negative-int (text-editor-min-width editor))
        (text-editor-min-height editor) (%non-negative-int (text-editor-min-height editor))
        (text-editor-text-size editor) (max 1 (%non-negative-int (text-editor-text-size editor)))
        (text-editor-blink-interval-ms editor) (%non-negative-int (text-editor-blink-interval-ms editor)))
  (%text-editor-clamp-caret editor)
  (unless (text-editor-focused-p editor)
    (setf (text-editor-caret-visible-p editor) nil)))

(defun %text-editor-color-components (color)
  (destructuring-bind (r g b &optional (a 255))
      (if (listp color)
          color
          (list (color-r color)
                (color-g color)
                (color-b color)
                (color-a color)))
    (values r g b a)))

(defun %text-editor-app-state-value (app-state accessor-name)
  (let* ((events-package (find-package :minerva.events))
         (symbol (and events-package (find-symbol accessor-name events-package))))
    (when (and app-state symbol (fboundp symbol))
      (funcall (symbol-function symbol) app-state))))

  (defun text-editor-expand-x (editor)
    (widget-expand-x editor))

  (defun text-editor-expand-y (editor)
    (widget-expand-y editor))

  (defun (setf text-editor-expand-x) (value editor)
    (setf (widget-expand-x editor) value))

  (defun (setf text-editor-expand-y) (value editor)
    (setf (widget-expand-y editor) value))

(defun %set-text-editor-app-state-value (app-state accessor-name value)
  (let* ((events-package (find-package :minerva.events))
         (symbol (and events-package (find-symbol accessor-name events-package)))
         (setter-name (and symbol (list 'setf symbol)))
         (setter (and setter-name (fboundp setter-name) (fdefinition setter-name))))
    (when (and app-state setter)
      (funcall setter value app-state)))
  value)

(defun %text-editor-mark-redraw (app-state)
  (%set-text-editor-app-state-value app-state "APP-STATE-NEEDS-REDRAW" t))

(defun %text-editor-focused-widget (app-state)
  (%text-editor-app-state-value app-state "APP-STATE-FOCUSED-WIDGET"))

(defun %text-editor-set-focused-widget (app-state widget)
  (let* ((events-package (find-package :minerva.events))
         (setter-symbol (and events-package (find-symbol "SET-FOCUSED-WIDGET" events-package))))
    (if (and setter-symbol (fboundp setter-symbol))
        (funcall (symbol-function setter-symbol) app-state widget)
        (%set-text-editor-app-state-value app-state "APP-STATE-FOCUSED-WIDGET" widget))))

(defun %text-editor-point-in-rect-p (x y rect)
  (and (numberp x)
       (numberp y)
       (>= x (rect-x rect))
       (>= y (rect-y rect))
       (< x (+ (rect-x rect) (rect-width rect)))
       (< y (+ (rect-y rect) (rect-height rect)))))

(defun %text-editor-current-ticks ()
  (let ((ticks-fn (%gfx-function "TICKS-MS")))
    (if ticks-fn
        (funcall ticks-fn)
        (truncate (* (/ (get-internal-real-time) internal-time-units-per-second) 1000)))))

(defun %text-editor-clamp-caret (editor)
  (let* ((text (text-editor-text editor))
         (text-length (length text)))
    (setf (text-editor-caret-position editor)
          (max 0 (min text-length (truncate (text-editor-caret-position editor)))))))

(defun %text-editor-reset-blink (editor &optional now-ms)
  (let ((stamp (or now-ms (%text-editor-current-ticks))))
    (setf (text-editor-caret-visible-p editor) t
          (text-editor-last-blink-ms editor) stamp))
  editor)

(defun %text-editor-destroy-surface (surface)
  (let ((destroy-fn (%gfx-function "DESTROY-SURFACE")))
    (when (and destroy-fn surface)
      (ignore-errors (funcall destroy-fn surface)))))

(defun %text-editor-render-text-surface (editor text)
  (let ((get-font-fn (%gfx-function "GET-FONT"))
        (destroy-font-fn (%gfx-function "DESTROY-FONT"))
        (render-text-fn (%gfx-function "RENDER-TEXT-TO-SURFACE"))
        (make-color-fn (%gfx-function "MAKE-COLOR")))
    (unless (and get-font-fn destroy-font-fn render-text-fn make-color-fn)
      (return-from %text-editor-render-text-surface nil))
    (let ((font nil))
      (unwind-protect
           (handler-case
               (progn
                 (setf font (funcall get-font-fn (%label-font-path (text-editor-font-name editor))
                                     (max 1 (%non-negative-int (text-editor-text-size editor)))))
                 (multiple-value-bind (r g b a)
                     (%text-editor-color-components (text-editor-text-color editor))
                   (funcall render-text-fn
                            font
                            (or text "")
                            (funcall make-color-fn :r r :g g :b b :a a))))
             (error () nil))
        (when font
          (ignore-errors (funcall destroy-font-fn font)))))))

(defun %text-editor-measure-text (editor text)
  (let ((get-font-fn (%gfx-function "GET-FONT"))
        (destroy-font-fn (%gfx-function "DESTROY-FONT"))
        (measure-text-fn (%gfx-function "MEASURE-TEXT")))
    (if (and get-font-fn destroy-font-fn measure-text-fn)
        (let ((font nil)
              (fallback-width (* (length (or text "")) (max 1 (floor (text-editor-text-size editor) 2))))
              (fallback-height (max 1 (text-editor-text-size editor))))
          (unwind-protect
               (handler-case
                   (progn
                     (setf font (funcall get-font-fn (%label-font-path (text-editor-font-name editor))
                                         (max 1 (%non-negative-int (text-editor-text-size editor)))))
                     (funcall measure-text-fn font (or text "")))
                 (error ()
                   (values fallback-width fallback-height)))
            (when font
              (ignore-errors (funcall destroy-font-fn font)))))
        (values (* (length (or text "")) (max 1 (floor (text-editor-text-size editor) 2)))
                (max 1 (text-editor-text-size editor))))))

(defun %text-editor-refresh-surface (editor)
  (let ((text (or (text-editor-text editor) "")))
    (unless (equal text (text-editor-surface-text-cache editor))
      (%text-editor-destroy-surface (text-editor-text-surface editor))
      (setf (text-editor-text-surface editor)
            (%text-editor-render-text-surface editor text)
            (text-editor-surface-text-cache editor) text))))

(defun %text-editor-content-rect (editor)
  (let* ((layout-rect (widget-layout-rect editor))
         (inner (%compute-inner-rect layout-rect
                                     (text-editor-padding-x editor)
                                     (text-editor-padding-x editor)
                                     (text-editor-padding-y editor)
                                     (text-editor-padding-y editor))))
    inner))

(defun %text-editor-caret-prefix (editor)
  (subseq (text-editor-text editor) 0 (text-editor-caret-position editor)))

(defun %text-editor-keyword->text (key)
  (cond
    ((eq key :space) " ")
    ((keywordp key)
     (let ((name (symbol-name key)))
       (if (and (= (length name) 1)
                (alphanumericp (char name 0)))
           (string-downcase name)
           nil)))
    (t nil)))

(defun %text-editor-insert-text (editor text)
  (when (and (stringp text) (> (length text) 0))
    (%text-editor-clamp-caret editor)
    (let* ((current (text-editor-text editor))
           (caret (text-editor-caret-position editor)))
      (setf (text-editor-text editor)
            (concatenate 'string
                         (subseq current 0 caret)
                         text
                         (subseq current caret))
            (text-editor-caret-position editor) (+ caret (length text))))
    (%text-editor-clamp-caret editor)
    (%text-editor-refresh-surface editor))
  editor)

(defun %text-editor-set-focused-local (editor focused app-state)
  (unless (eq (text-editor-focused-p editor) focused)
    (setf (text-editor-focused-p editor) focused)
    (%text-editor-mark-redraw app-state))
  (if focused
      (%text-editor-reset-blink editor)
      (setf (text-editor-caret-visible-p editor) nil))
  editor)

(defun text-editor-update-blink (editor &optional now-ms)
  (let* ((stamp (or now-ms (%text-editor-current-ticks)))
         (elapsed (- stamp (text-editor-last-blink-ms editor))))
    (if (and (text-editor-focused-p editor)
             (> (text-editor-blink-interval-ms editor) 0)
             (>= elapsed (text-editor-blink-interval-ms editor)))
        (progn
          (setf (text-editor-caret-visible-p editor) (not (text-editor-caret-visible-p editor))
                (text-editor-last-blink-ms editor) stamp)
          t)
        nil)))

(defmethod measure ((editor text-editor))
  (multiple-value-bind (sample-width sample-height)
      (%text-editor-measure-text editor "Mg")
    (declare (ignore sample-width))
    (let ((line-height (1+ sample-height)))
    (%apply-widget-margins-to-size-request
     editor
     (%widget-size-request editor
                           (max *text-editor-default-min-width* (text-editor-min-width editor))
                           (max (text-editor-min-height editor)
                                (+ line-height
                                   (* 2 (+ 1 (text-editor-padding-y editor))))))))))

(defmethod layout ((editor text-editor) rect)
  (setf (widget-layout-rect editor) (%apply-widget-margins-to-rect editor rect))
  (%text-editor-clamp-caret editor)
  editor)

(defmethod render ((editor text-editor) backend-window)
  (%text-editor-refresh-surface editor)
  (let* ((content (%text-editor-content-rect editor))
         (surface (text-editor-text-surface editor)))
    (when surface
      (let* ((text-width (%surface-width surface))
             (text-height (%surface-height surface))
             (dest-x (rect-x content))
             (dest-y (rect-y content))
             (clip-left (max (rect-x content) dest-x))
             (clip-top (max (rect-y content) dest-y))
             (clip-right (min (+ (rect-x content) (rect-width content)) (+ dest-x text-width)))
             (clip-bottom (min (+ (rect-y content) (rect-height content)) (+ dest-y text-height)))
             (draw-width (max 0 (- clip-right clip-left)))
             (draw-height (max 0 (- clip-bottom clip-top))))
        (when (and (> draw-width 0) (> draw-height 0))
          (%call-draw-surface-rect backend-window
                                   surface
                                   (make-rect :x (max 0 (- clip-left dest-x))
                                              :y (max 0 (- clip-top dest-y))
                                              :width draw-width
                                              :height draw-height)
                                   clip-left
                                   clip-top))))
    (when (and (text-editor-focused-p editor)
               (text-editor-caret-visible-p editor))
      (multiple-value-bind (prefix-width prefix-height)
          (%text-editor-measure-text editor (%text-editor-caret-prefix editor))
        (declare (ignore prefix-height))
        (multiple-value-bind (caret-width text-height)
            (%text-editor-measure-text editor "Mg")
          (declare (ignore caret-width))
        (let* ((content-left (rect-x content))
               (content-right (+ (rect-x content) (rect-width content)))
               (caret-x (max content-left (min (+ content-left prefix-width) content-right)))
               (caret-height (max 1 (min (1+ text-height) (rect-height content)))))
          (%call-fill-rect backend-window
                           (make-rect :x caret-x
                                      :y (rect-y content)
                                      :width 1
                                      :height caret-height)
                           (text-editor-caret-color editor)))))))
  editor)

(defmethod handle-event ((editor text-editor) app-state event)
  (case (first event)
    (:focus-gained
     (%text-editor-set-focused-local editor t app-state)
     nil)
    (:focus-lost
     (%text-editor-set-focused-local editor nil app-state)
     nil)
    (:mouse-down
     (let* ((button (getf (rest event) :button))
            (x (getf (rest event) :x))
            (y (getf (rest event) :y))
            (inside (%text-editor-point-in-rect-p x y (widget-layout-rect editor))))
       (when (and (eq button :left) inside)
         (setf (text-editor-caret-position editor) (length (text-editor-text editor)))
         (if app-state
             (%text-editor-set-focused-widget app-state editor)
             (%text-editor-set-focused-local editor t app-state))
         (%text-editor-reset-blink editor)
         (%text-editor-mark-redraw app-state)
         nil)))
    (:text-input
     (when (text-editor-focused-p editor)
       (let ((text (or (getf (rest event) :text) "")))
         (when (> (length text) 0)
           (%text-editor-insert-text editor text)
           (%text-editor-reset-blink editor)
           (%text-editor-mark-redraw app-state))))
     nil)
    (:key-down
     (when (text-editor-focused-p editor)
       (let ((inserted-text (%text-editor-keyword->text (getf (rest event) :key))))
         (when inserted-text
           (%text-editor-insert-text editor inserted-text)
           (%text-editor-reset-blink editor)
           (%text-editor-mark-redraw app-state))))
     nil)
    (:tick
     (let ((now-ms (or (getf (rest event) :now-ms)
                       (%text-editor-current-ticks))))
       (when (text-editor-update-blink editor now-ms)
         (%text-editor-mark-redraw app-state)))
     nil)
    (otherwise nil)))

(defmethod tick-widget ((editor text-editor) app-state now-ms)
  (when (text-editor-update-blink editor now-ms)
    (%text-editor-mark-redraw app-state))
  nil)