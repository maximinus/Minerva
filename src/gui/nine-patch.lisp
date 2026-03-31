(in-package :minerva.gui)

(defclass nine-patch (widget)
  ((surface :initarg :surface :accessor nine-patch-surface :initform nil)
   (border-left :initarg :border-left :accessor nine-patch-border-left :initform 0)
   (border-right :initarg :border-right :accessor nine-patch-border-right :initform 0)
   (border-top :initarg :border-top :accessor nine-patch-border-top :initform 0)
   (border-bottom :initarg :border-bottom :accessor nine-patch-border-bottom :initform 0)
   (child :initarg :child :accessor nine-patch-child :initform nil)
  (content-rect :accessor nine-patch-content-rect :initform (make-rect))))

(defun %non-negative-border (value)
  (%non-negative-int value))

(defun %patch-segment (total start-size end-size)
  (let* ((start (min (%non-negative-int start-size) (%non-negative-int total)))
         (remaining (max 0 (- (%non-negative-int total) start)))
         (end (min (%non-negative-int end-size) remaining))
         (center (max 0 (- (%non-negative-int total) start end))))
    (values start center end)))

(defmethod measure ((panel nine-patch))
  (let* ((child (nine-patch-child panel))
         (child-request (if child (measure child) (make-size-request)))
         (left (%non-negative-border (nine-patch-border-left panel)))
         (right (%non-negative-border (nine-patch-border-right panel)))
         (top (%non-negative-border (nine-patch-border-top panel)))
         (bottom (%non-negative-border (nine-patch-border-bottom panel))))
    (%apply-widget-margins-to-size-request
     panel
      (%widget-size-request panel
                (+ left right (size-request-min-width child-request))
                (+ top bottom (size-request-min-height child-request))))))

(defmethod layout ((panel nine-patch) rect)
  (setf (widget-layout-rect panel) (%apply-widget-margins-to-rect panel rect))
  (let* ((left (%non-negative-border (nine-patch-border-left panel)))
         (right (%non-negative-border (nine-patch-border-right panel)))
         (top (%non-negative-border (nine-patch-border-top panel)))
         (bottom (%non-negative-border (nine-patch-border-bottom panel)))
         (content (%compute-inner-rect (widget-layout-rect panel) left right top bottom))
         (child (nine-patch-child panel)))
    (setf (nine-patch-content-rect panel) content)
    (when child
      (layout child content)))
  panel)

(defun %render-nine-patch-part (backend-window surface src-position src-size dst-position dst-size)
  (when (and (> (size-width src-size) 0)
             (> (size-height src-size) 0)
             (> (size-width dst-size) 0)
             (> (size-height dst-size) 0))
    (%call-draw-surface-rect-scaled
     backend-window
     surface
     (make-rect :x (position-x src-position)
                :y (position-y src-position)
                :width (size-width src-size)
                :height (size-height src-size))
     (make-rect :x (position-x dst-position)
                :y (position-y dst-position)
                :width (size-width dst-size)
                :height (size-height dst-size)))))

(defmethod render ((panel nine-patch) backend-window)
  (let* ((surface (nine-patch-surface panel))
         (outer (widget-layout-rect panel))
         (child (nine-patch-child panel)))
    (when surface
      (let* ((src-width (%surface-width surface))
             (src-height (%surface-height surface))
             (dst-width (rect-width outer))
             (dst-height (rect-height outer))
             (src-x-segments (multiple-value-list
                              (%patch-segment src-width
                                              (%non-negative-border (nine-patch-border-left panel))
                                              (%non-negative-border (nine-patch-border-right panel)))))
             (src-y-segments (multiple-value-list
                              (%patch-segment src-height
                                              (%non-negative-border (nine-patch-border-top panel))
                                              (%non-negative-border (nine-patch-border-bottom panel)))))
             (dst-x-segments (multiple-value-list
                              (%patch-segment dst-width
                                              (%non-negative-border (nine-patch-border-left panel))
                                              (%non-negative-border (nine-patch-border-right panel)))))
             (dst-y-segments (multiple-value-list
                              (%patch-segment dst-height
                                              (%non-negative-border (nine-patch-border-top panel))
                                              (%non-negative-border (nine-patch-border-bottom panel))))))
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
                                           (make-size :width dst-right :height dst-bottom))))))))
    (when child
      (render child backend-window))
    panel)))

(defmethod event-children ((panel nine-patch))
  (let ((child (nine-patch-child panel)))
    (if child (list child) nil)))
