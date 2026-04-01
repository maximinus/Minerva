(in-package :minerva.gui)

(defparameter +scrollbar-thumb-join-color+ (make-color :r 32 :g 32 :b 32 :a 255))

(defun %scrollbar-button-size ()
  (max 1 (%non-negative-int theme:scrollbar-button-size)))

(defun %scrollbar-scroll-step ()
  (max 1 (%non-negative-int theme:scrollbar-scroll-step)))

(defun %scrollbar-min-thumb-size ()
  (max 1 (%non-negative-int theme:scrollbar-min-thumb-size)))

(defclass scroll-area (widget)
  ((child :initarg :child :accessor scroll-area-child :initform nil)
   (scroll-x :initarg :scroll-x :accessor scroll-area-scroll-x :initform 0)
   (scroll-y :initarg :scroll-y :accessor scroll-area-scroll-y :initform 0)
   (content-width :accessor scroll-area-content-width :initform 0)
   (content-height :accessor scroll-area-content-height :initform 0)
   (horizontal-visible-p :accessor scroll-area-horizontal-visible-p :initform nil)
   (vertical-visible-p :accessor scroll-area-vertical-visible-p :initform nil)
   (viewport-rect :accessor scroll-area-viewport-rect :initform (make-rect))
   (horizontal-bar-rect :accessor scroll-area-horizontal-bar-rect :initform (make-rect))
   (vertical-bar-rect :accessor scroll-area-vertical-bar-rect :initform (make-rect))
   (corner-rect :accessor scroll-area-corner-rect :initform (make-rect))
   (horizontal-left-button-rect :accessor scroll-area-horizontal-left-button-rect :initform (make-rect))
   (horizontal-right-button-rect :accessor scroll-area-horizontal-right-button-rect :initform (make-rect))
   (horizontal-track-rect :accessor scroll-area-horizontal-track-rect :initform (make-rect))
   (horizontal-thumb-rect :accessor scroll-area-horizontal-thumb-rect :initform (make-rect))
   (vertical-top-button-rect :accessor scroll-area-vertical-top-button-rect :initform (make-rect))
   (vertical-bottom-button-rect :accessor scroll-area-vertical-bottom-button-rect :initform (make-rect))
   (vertical-track-rect :accessor scroll-area-vertical-track-rect :initform (make-rect))
   (vertical-thumb-rect :accessor scroll-area-vertical-thumb-rect :initform (make-rect))
   (left-button-surface :accessor scroll-area-left-button-surface :initform nil)
   (right-button-surface :accessor scroll-area-right-button-surface :initform nil)
   (top-button-surface :accessor scroll-area-top-button-surface :initform nil)
   (bottom-button-surface :accessor scroll-area-bottom-button-surface :initform nil)
   (left-bar-surface :accessor scroll-area-left-bar-surface :initform nil)
   (right-bar-surface :accessor scroll-area-right-bar-surface :initform nil)
   (top-bar-surface :accessor scroll-area-top-bar-surface :initform nil)
   (bottom-bar-surface :accessor scroll-area-bottom-bar-surface :initform nil)))

(defun %scroll-area-project-root ()
  (or (ignore-errors (asdf:system-source-directory "minerva"))
      (truename "./")))

(defun %scroll-area-load-surface (relative-path)
  (let ((load-fn (%gfx-function "LOAD-SURFACE")))
    (unless load-fn
      (error "minerva.gfx:load-surface is unavailable. Load src/gfx/ffi.lisp and src/gfx/backend.lisp first."))
    (funcall load-fn relative-path)))

(defun %scroll-area-load-default-surfaces (area)
  (setf (scroll-area-left-button-surface area) (%scroll-area-load-surface "assets/scrollbar/left_button.png")
        (scroll-area-right-button-surface area) (%scroll-area-load-surface "assets/scrollbar/right_button.png")
        (scroll-area-top-button-surface area) (%scroll-area-load-surface "assets/scrollbar/top_button.png")
        (scroll-area-bottom-button-surface area) (%scroll-area-load-surface "assets/scrollbar/bottom_button.png")
        (scroll-area-left-bar-surface area) (%scroll-area-load-surface "assets/scrollbar/left_bar.png")
        (scroll-area-right-bar-surface area) (%scroll-area-load-surface "assets/scrollbar/right_bar.png")
        (scroll-area-top-bar-surface area) (%scroll-area-load-surface "assets/scrollbar/top_bar.png")
        (scroll-area-bottom-bar-surface area) (%scroll-area-load-surface "assets/scrollbar/bottom_bar.png")))

(defmethod initialize-instance :after ((area scroll-area) &key)
  (setf (scroll-area-scroll-x area) (%non-negative-int (scroll-area-scroll-x area))
        (scroll-area-scroll-y area) (%non-negative-int (scroll-area-scroll-y area)))
  (%scroll-area-load-default-surfaces area))

(defun %scroll-area-point-in-rect-p (x y rect)
  (and (numberp x)
       (numberp y)
       (>= x (rect-x rect))
       (>= y (rect-y rect))
       (< x (+ (rect-x rect) (rect-width rect)))
       (< y (+ (rect-y rect) (rect-height rect)))))

(defun %scroll-area-events-accessor (name)
  (let* ((events-package (find-package :minerva.events))
         (symbol (and events-package (find-symbol name events-package))))
    (and symbol (fboundp symbol) (symbol-function symbol))))

(defun %set-scroll-area-app-state-value (app-state accessor-name value)
  (let* ((events-package (find-package :minerva.events))
         (symbol (and events-package (find-symbol accessor-name events-package)))
         (setter-name (and symbol (list 'setf symbol)))
         (setter (and setter-name (fboundp setter-name) (fdefinition setter-name))))
    (when (and app-state setter)
      (funcall setter value app-state)))
  value)

(defun %scroll-area-mark-redraw (app-state)
  (%set-scroll-area-app-state-value app-state "APP-STATE-NEEDS-REDRAW" t))

(defun %scroll-area-max-scroll-x (area)
  (max 0 (- (scroll-area-content-width area)
            (rect-width (scroll-area-viewport-rect area)))))

(defun %scroll-area-max-scroll-y (area)
  (max 0 (- (scroll-area-content-height area)
            (rect-height (scroll-area-viewport-rect area)))))

(defun %scroll-area-clamp-scroll (area)
  (setf (scroll-area-scroll-x area)
        (max 0 (min (%non-negative-int (scroll-area-scroll-x area))
                    (%scroll-area-max-scroll-x area)))
        (scroll-area-scroll-y area)
        (max 0 (min (%non-negative-int (scroll-area-scroll-y area))
                    (%scroll-area-max-scroll-y area))))
  area)

(defun %scroll-area-resolve-visibility (content-width content-height area-width area-height)
  (let ((thickness (%scrollbar-button-size))
        (show-h nil)
        (show-v nil)
        (changed t))
    (loop while changed do
      (setf changed nil)
      (let* ((viewport-width (max 0 (- area-width (if show-v thickness 0))))
             (viewport-height (max 0 (- area-height (if show-h thickness 0))))
             (need-h (> content-width viewport-width))
             (need-v (> content-height viewport-height)))
        (unless (eq need-h show-h)
          (setf show-h need-h
                changed t))
        (unless (eq need-v show-v)
          (setf show-v need-v
                changed t))))
    (values show-h
            show-v
          (max 0 (- area-width (if show-v thickness 0)))
          (max 0 (- area-height (if show-h thickness 0))))))

(defun %scroll-area-thumb-rect-horizontal (track-rect viewport-width content-width scroll-x)
  (let ((track-width (rect-width track-rect)))
    (if (<= track-width 0)
        (make-rect :x (rect-x track-rect) :y (rect-y track-rect) :width 0 :height (rect-height track-rect))
        (let* ((thumb-width (if (<= content-width 0)
                                track-width
                                (min track-width
                      (max (%scrollbar-min-thumb-size)
                                          (floor (* track-width viewport-width)
                                                 (max 1 content-width))))))
               (max-scroll (max 0 (- content-width viewport-width)))
               (travel (max 0 (- track-width thumb-width)))
               (thumb-offset (if (<= max-scroll 0)
                                 0
                                 (floor (* travel scroll-x) max-scroll))))
          (make-rect :x (+ (rect-x track-rect) thumb-offset)
                     :y (rect-y track-rect)
                     :width thumb-width
                     :height (rect-height track-rect))))))

(defun %scroll-area-thumb-rect-vertical (track-rect viewport-height content-height scroll-y)
  (let ((track-height (rect-height track-rect)))
    (if (<= track-height 0)
        (make-rect :x (rect-x track-rect) :y (rect-y track-rect) :width (rect-width track-rect) :height 0)
        (let* ((thumb-height (if (<= content-height 0)
                                 track-height
                                 (min track-height
                       (max (%scrollbar-min-thumb-size)
                                           (floor (* track-height viewport-height)
                                                  (max 1 content-height))))))
               (max-scroll (max 0 (- content-height viewport-height)))
               (travel (max 0 (- track-height thumb-height)))
               (thumb-offset (if (<= max-scroll 0)
                                 0
                                 (floor (* travel scroll-y) max-scroll))))
          (make-rect :x (rect-x track-rect)
                     :y (+ (rect-y track-rect) thumb-offset)
                     :width (rect-width track-rect)
                     :height thumb-height)))))

(defun %scroll-area-set-empty-geometry (area)
  (setf (scroll-area-horizontal-visible-p area) nil
        (scroll-area-vertical-visible-p area) nil
        (scroll-area-viewport-rect area) (make-rect :x (rect-x (widget-layout-rect area))
                                                    :y (rect-y (widget-layout-rect area))
                                                    :width (rect-width (widget-layout-rect area))
                                                    :height (rect-height (widget-layout-rect area)))
        (scroll-area-horizontal-bar-rect area) (make-rect)
        (scroll-area-vertical-bar-rect area) (make-rect)
        (scroll-area-corner-rect area) (make-rect)
        (scroll-area-horizontal-left-button-rect area) (make-rect)
        (scroll-area-horizontal-right-button-rect area) (make-rect)
        (scroll-area-horizontal-track-rect area) (make-rect)
        (scroll-area-horizontal-thumb-rect area) (make-rect)
        (scroll-area-vertical-top-button-rect area) (make-rect)
        (scroll-area-vertical-bottom-button-rect area) (make-rect)
        (scroll-area-vertical-track-rect area) (make-rect)
        (scroll-area-vertical-thumb-rect area) (make-rect)
        (scroll-area-content-width area) 0
        (scroll-area-content-height area) 0
        (scroll-area-scroll-x area) 0
        (scroll-area-scroll-y area) 0)
  area)

(defun %scroll-area-update-geometry (area)
  (let* ((outer (widget-layout-rect area))
         (child (scroll-area-child area)))
    (if (null child)
        (%scroll-area-set-empty-geometry area)
        (let* ((child-request (measure child))
               (content-width (max 0 (size-request-min-width child-request)))
               (content-height (max 0 (size-request-min-height child-request)))
               (area-width (rect-width outer))
               (area-height (rect-height outer)))
          (multiple-value-bind (show-h show-v viewport-width viewport-height)
              (%scroll-area-resolve-visibility content-width content-height area-width area-height)
            (let ((thickness (%scrollbar-button-size)))
              (setf (scroll-area-content-width area) content-width
                  (scroll-area-content-height area) content-height
                  (scroll-area-horizontal-visible-p area) show-h
                  (scroll-area-vertical-visible-p area) show-v
                  (scroll-area-viewport-rect area) (make-rect :x (rect-x outer)
                                                              :y (rect-y outer)
                                                              :width viewport-width
                                                              :height viewport-height)
                  (scroll-area-horizontal-bar-rect area)
                  (if show-h
                      (make-rect :x (rect-x outer)
                                 :y (+ (rect-y outer) viewport-height)
                                 :width viewport-width
                           :height thickness)
                      (make-rect))
                  (scroll-area-vertical-bar-rect area)
                  (if show-v
                      (make-rect :x (+ (rect-x outer) viewport-width)
                                 :y (rect-y outer)
                           :width thickness
                                 :height viewport-height)
                      (make-rect))
                  (scroll-area-corner-rect area)
                  (if (and show-h show-v)
                      (make-rect :x (+ (rect-x outer) viewport-width)
                                 :y (+ (rect-y outer) viewport-height)
                           :width thickness
                           :height thickness)
                      (make-rect)))
              
            (%scroll-area-clamp-scroll area)
            (let ((viewport (scroll-area-viewport-rect area)))
              (layout child (make-rect :x (- (rect-x viewport) (scroll-area-scroll-x area))
                                      :y (- (rect-y viewport) (scroll-area-scroll-y area))
                                      :width content-width
                                      :height content-height)))
            (if show-h
                (let* ((bar (scroll-area-horizontal-bar-rect area))
                       (left-rect (make-rect :x (rect-x bar)
                                             :y (rect-y bar)
                                 :width thickness
                                 :height thickness))
                       (right-rect (make-rect :x (+ (rect-x bar)
                                    (max 0 (- (rect-width bar) thickness)))
                                              :y (rect-y bar)
                                  :width thickness
                                  :height thickness))
                       (track-width (max 0 (- (rect-width bar) (* 2 thickness))))
                       (track-rect (make-rect :x (+ (rect-x bar) thickness)
                                              :y (rect-y bar)
                                              :width track-width
                                  :height thickness)))
                  (setf (scroll-area-horizontal-left-button-rect area) left-rect
                        (scroll-area-horizontal-right-button-rect area) right-rect
                        (scroll-area-horizontal-track-rect area) track-rect
                        (scroll-area-horizontal-thumb-rect area)
                        (%scroll-area-thumb-rect-horizontal track-rect
                                                            (rect-width (scroll-area-viewport-rect area))
                                                            content-width
                                                            (scroll-area-scroll-x area))))
                (setf (scroll-area-horizontal-left-button-rect area) (make-rect)
                      (scroll-area-horizontal-right-button-rect area) (make-rect)
                      (scroll-area-horizontal-track-rect area) (make-rect)
                      (scroll-area-horizontal-thumb-rect area) (make-rect)))
            (if show-v
                (let* ((bar (scroll-area-vertical-bar-rect area))
                       (top-rect (make-rect :x (rect-x bar)
                                            :y (rect-y bar)
                            :width thickness
                            :height thickness))
                       (bottom-rect (make-rect :x (rect-x bar)
                                               :y (+ (rect-y bar)
                                 (max 0 (- (rect-height bar) thickness)))
                               :width thickness
                               :height thickness))
                       (track-height (max 0 (- (rect-height bar) (* 2 thickness))))
                       (track-rect (make-rect :x (rect-x bar)
                              :y (+ (rect-y bar) thickness)
                              :width thickness
                                              :height track-height)))
                  (setf (scroll-area-vertical-top-button-rect area) top-rect
                        (scroll-area-vertical-bottom-button-rect area) bottom-rect
                        (scroll-area-vertical-track-rect area) track-rect
                        (scroll-area-vertical-thumb-rect area)
                        (%scroll-area-thumb-rect-vertical track-rect
                                                          (rect-height (scroll-area-viewport-rect area))
                                                          content-height
                                                          (scroll-area-scroll-y area))))
                (setf (scroll-area-vertical-top-button-rect area) (make-rect)
                      (scroll-area-vertical-bottom-button-rect area) (make-rect)
                      (scroll-area-vertical-track-rect area) (make-rect)
                      (scroll-area-vertical-thumb-rect area) (make-rect)))))))))

(defun %scroll-area-source-rect-for-surface (surface)
  (make-rect :x 0
             :y 0
             :width (%surface-width surface)
             :height (%surface-height surface)))

(defun %scroll-area-draw-surface-fit (backend-window surface dest-rect)
  (when (and surface
             (> (rect-width dest-rect) 0)
             (> (rect-height dest-rect) 0))
    (%call-draw-surface-rect-scaled backend-window
                                    surface
                                    (%scroll-area-source-rect-for-surface surface)
                                    dest-rect)))

(defun %scroll-area-render-horizontal-thumb (area backend-window)
  (let ((thumb (scroll-area-horizontal-thumb-rect area)))
    (when (and (> (rect-width thumb) 0)
               (> (rect-height thumb) 0))
      (let* ((left-surface (scroll-area-left-bar-surface area))
             (right-surface (scroll-area-right-bar-surface area))
             (left-width (if left-surface (%surface-width left-surface) 0))
             (right-width (if right-surface (%surface-width right-surface) 0))
             (center-x (+ (rect-x thumb) left-width))
             (center-width (max 0 (- (rect-width thumb) left-width right-width))))
        (if (and left-surface right-surface
                 (>= (rect-width thumb) (+ left-width right-width)))
            (progn
              (%scroll-area-draw-surface-fit backend-window
                                             left-surface
                                             (make-rect :x (rect-x thumb)
                                                        :y (rect-y thumb)
                                                        :width left-width
                                                        :height (rect-height thumb)))
              (when (> center-width 0)
                (%call-fill-rect backend-window
                                 (make-rect :x center-x
                                            :y (rect-y thumb)
                                            :width center-width
                                            :height (rect-height thumb))
                                 +scrollbar-thumb-join-color+))
              (%scroll-area-draw-surface-fit backend-window
                                             right-surface
                                             (make-rect :x (+ (rect-x thumb)
                                                              (max 0 (- (rect-width thumb) right-width)))
                                                        :y (rect-y thumb)
                                                        :width right-width
                                                        :height (rect-height thumb))))
            (%call-fill-rect backend-window thumb +scrollbar-thumb-join-color+))))))

(defun %scroll-area-render-vertical-thumb (area backend-window)
  (let ((thumb (scroll-area-vertical-thumb-rect area)))
    (when (and (> (rect-width thumb) 0)
               (> (rect-height thumb) 0))
      (let* ((top-surface (scroll-area-top-bar-surface area))
             (bottom-surface (scroll-area-bottom-bar-surface area))
             (top-height (if top-surface (%surface-height top-surface) 0))
             (bottom-height (if bottom-surface (%surface-height bottom-surface) 0))
             (center-y (+ (rect-y thumb) top-height))
             (center-height (max 0 (- (rect-height thumb) top-height bottom-height))))
        (if (and top-surface bottom-surface
                 (>= (rect-height thumb) (+ top-height bottom-height)))
            (progn
              (%scroll-area-draw-surface-fit backend-window
                                             top-surface
                                             (make-rect :x (rect-x thumb)
                                                        :y (rect-y thumb)
                                                        :width (rect-width thumb)
                                                        :height top-height))
              (when (> center-height 0)
                (%call-fill-rect backend-window
                                 (make-rect :x (rect-x thumb)
                                            :y center-y
                                            :width (rect-width thumb)
                                            :height center-height)
                                 +scrollbar-thumb-join-color+))
              (%scroll-area-draw-surface-fit backend-window
                                             bottom-surface
                                             (make-rect :x (rect-x thumb)
                                                        :y (+ (rect-y thumb)
                                                              (max 0 (- (rect-height thumb) bottom-height)))
                                                        :width (rect-width thumb)
                                                        :height bottom-height)))
            (%call-fill-rect backend-window thumb +scrollbar-thumb-join-color+))))))

(defun %scroll-area-scroll-by (area app-state dx dy)
  (let ((old-x (scroll-area-scroll-x area))
        (old-y (scroll-area-scroll-y area)))
    (setf (scroll-area-scroll-x area) (+ old-x dx)
          (scroll-area-scroll-y area) (+ old-y dy))
    (%scroll-area-clamp-scroll area)
    (%scroll-area-update-geometry area)
    (unless (and (= old-x (scroll-area-scroll-x area))
                 (= old-y (scroll-area-scroll-y area)))
      (%scroll-area-mark-redraw app-state))))

(defun %scroll-area-translate-mouse-event (area event)
  (let ((x (getf (rest event) :x))
        (y (getf (rest event) :y)))
    (if (and (numberp x) (numberp y))
        (append (list (first event))
                (copy-list
                 (list* :x (+ x (scroll-area-scroll-x area))
                        :y (+ y (scroll-area-scroll-y area))
                        (loop for (key value) on (rest event) by #'cddr
                              unless (or (eq key :x) (eq key :y))
                              append (list key value)))))
        event)))

(defmethod measure ((area scroll-area))
  (let* ((child (scroll-area-child area))
         (request (if child
                      (measure child)
                      (make-size-request))))
    (%apply-widget-margins-to-size-request
     area
     (%widget-size-request area
                           (size-request-min-width request)
                           (size-request-min-height request)
                           :expand-x :inherit
                           :expand-y :inherit))))

(defmethod layout ((area scroll-area) rect)
  (setf (widget-layout-rect area) (%apply-widget-margins-to-rect area rect))
  (%scroll-area-update-geometry area)
  area)

(defmethod render ((area scroll-area) backend-window)
  (let ((child (scroll-area-child area))
        (viewport (scroll-area-viewport-rect area)))
    (when (and child
               (> (rect-width viewport) 0)
               (> (rect-height viewport) 0))
      (%with-render-clip viewport
        (render child backend-window))))
  (when (scroll-area-horizontal-visible-p area)
    (%call-fill-rect backend-window
                     (scroll-area-horizontal-track-rect area)
                     theme:scrollbar-background-color)
    (%scroll-area-draw-surface-fit backend-window
                                   (scroll-area-left-button-surface area)
                                   (scroll-area-horizontal-left-button-rect area))
    (%scroll-area-draw-surface-fit backend-window
                                   (scroll-area-right-button-surface area)
                                   (scroll-area-horizontal-right-button-rect area))
    (%scroll-area-render-horizontal-thumb area backend-window))
  (when (scroll-area-vertical-visible-p area)
    (%call-fill-rect backend-window
                     (scroll-area-vertical-track-rect area)
                     theme:scrollbar-background-color)
    (%scroll-area-draw-surface-fit backend-window
                                   (scroll-area-top-button-surface area)
                                   (scroll-area-vertical-top-button-rect area))
    (%scroll-area-draw-surface-fit backend-window
                                   (scroll-area-bottom-button-surface area)
                                   (scroll-area-vertical-bottom-button-rect area))
    (%scroll-area-render-vertical-thumb area backend-window))
  (when (and (scroll-area-horizontal-visible-p area)
             (scroll-area-vertical-visible-p area))
    (%call-fill-rect backend-window
             (scroll-area-corner-rect area)
             theme:scrollbar-background-color))
  area)

(defmethod event-children ((area scroll-area))
  nil)

(defmethod handle-event ((area scroll-area) app-state event)
  (let ((child (scroll-area-child area))
        (event-type (first event))
        (x (getf (rest event) :x))
        (y (getf (rest event) :y)))
    (case event-type
      (:mouse-down
       (when (eq (getf (rest event) :button) :left)
         (cond
           ((%scroll-area-point-in-rect-p x y (scroll-area-horizontal-left-button-rect area))
            (%scroll-area-scroll-by area app-state (- (%scrollbar-scroll-step)) 0)
            (return-from handle-event nil))
           ((%scroll-area-point-in-rect-p x y (scroll-area-horizontal-right-button-rect area))
            (%scroll-area-scroll-by area app-state (%scrollbar-scroll-step) 0)
            (return-from handle-event nil))
           ((%scroll-area-point-in-rect-p x y (scroll-area-vertical-top-button-rect area))
            (%scroll-area-scroll-by area app-state 0 (- (%scrollbar-scroll-step)))
            (return-from handle-event nil))
           ((%scroll-area-point-in-rect-p x y (scroll-area-vertical-bottom-button-rect area))
            (%scroll-area-scroll-by area app-state 0 (%scrollbar-scroll-step))
            (return-from handle-event nil))))
       (when (and child (%scroll-area-point-in-rect-p x y (scroll-area-viewport-rect area)))
         (return-from handle-event
           (handle-event child app-state (%scroll-area-translate-mouse-event area event))))
       nil)
      ((:mouse-up :mouse-move)
       (when (and child (%scroll-area-point-in-rect-p x y (scroll-area-viewport-rect area)))
         (return-from handle-event
           (handle-event child app-state (%scroll-area-translate-mouse-event area event))))
       nil)
      (otherwise
       (when child
         (handle-event child app-state event))))))
