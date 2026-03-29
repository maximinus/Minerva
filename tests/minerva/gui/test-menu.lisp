(in-package :minerva.gui)

(defmacro %with-stubbed-menu-text-render (&body body)
  `(let ((old-render (symbol-function 'minerva.gui::%render-label-text-surface)))
     (unwind-protect
          (progn
            (setf (symbol-function 'minerva.gui::%render-label-text-surface)
                  (lambda (font-name text-size text color)
                    (declare (ignore font-name text-size))
                    (list :width (max 1 (* 7 (length (or text ""))))
                          :height 14
                          :text text
                          :color color)))
            ,@body)
       (setf (symbol-function 'minerva.gui::%render-label-text-surface) old-render))))

(defun %menu-item-children-only (menu)
  (remove-if-not (lambda (child)
                   (typep child 'menu-item))
                 (menu-children menu)))

(%deftest test-menu-item-stores-basic-properties
  (%with-stubbed-menu-text-render
    (let ((item (make-instance 'menu-item
                               :id :open-item
                               :text "Open"
                               :command :open
                               :icon '(:width 16 :height 16)
                               :key-text "Ctrl-O")))
      (%assert-equal (menu-item-id item) :open-item "menu-item stores id")
      (%assert-equal (menu-item-text item) "Open" "menu-item stores text")
      (%assert-equal (menu-item-command item) :open "menu-item stores command")
      (%assert-equal (menu-item-key-text item) "Ctrl-O" "menu-item stores key-text")
      (%assert-equal (%surface-width (menu-item-icon-surface item)) 16 "menu-item stores icon surface"))))

(%deftest test-default-image-path-registry-has-menu-nine-patch
  (%assert-equal menu-nine-patch
                 "/assets/menu/menu.png"
                 "menu nine-patch constant path")
  (%assert-equal (cdr (assoc :menu-nine-patch default-image-paths))
                 "/assets/menu/menu.png"
                 "default image list includes menu nine-patch"))

(%deftest test-menu-loads-default-panel-surface-when-not-provided
  (%with-stubbed-menu-text-render
    (let ((old-load-default (symbol-function 'minerva.gui::%menu-load-default-panel-surface)))
      (unwind-protect
           (progn
             (setf (symbol-function 'minerva.gui::%menu-load-default-panel-surface)
                   (lambda ()
                     '(:width 24 :height 24)))
             (let ((menu (make-instance 'menu
                                        :entries (list '(:text "Open" :command :open)))))
               (%assert-equal (menu-panel-surface menu)
                              '(:width 24 :height 24)
                              "menu uses default panel surface when none provided")))
        (setf (symbol-function 'minerva.gui::%menu-load-default-panel-surface) old-load-default)))))

(%deftest test-menu-item-hover-and-click-behavior
  (%with-stubbed-menu-text-render
    (let ((item (make-instance 'menu-item :text "Save" :command :save)))
      (layout item (make-rect :x 10 :y 10 :width 160 :height 30))
      (handle-event item nil '(:mouse-move :x 20 :y 20))
      (%assert-equal (menu-item-state item) :hovered "menu-item hover enters hovered state")
      (handle-event item nil '(:mouse-move :x 1000 :y 1000))
      (%assert-equal (menu-item-state item) :normal "menu-item hover exits to normal state")
      (handle-event item nil '(:mouse-down :button :left :x 20 :y 20))
      (let ((actions (handle-event item nil '(:mouse-up :button :left :x 20 :y 20))))
        (%assert-equal actions '((:command :save)) "menu-item click emits command")))))

(%deftest test-menu-item-without-icon-or-key-is-measurable
  (%with-stubbed-menu-text-render
    (let ((item (make-instance 'menu-item :text "Exit" :command :quit)))
      (layout item (make-rect :x 0 :y 0 :width 120 :height 26))
      (let ((request (measure item)))
        (%assert-equal (> (size-request-min-width request) 0) t "menu-item without icon/key has min-width")
        (%assert-equal (> (size-request-min-height request) 0) t "menu-item without icon/key has min-height")))))

(%deftest test-menu-spacer-min-height-and-event-ignore
  (let ((spacer (make-instance 'menu-spacer
                               :top-spacing 3
                               :line-thickness 2
                               :bottom-spacing 5)))
    (%assert-min-size spacer 0 10 "menu-spacer min-height sums spacing and line")
    (layout spacer (make-rect :x 0 :y 0 :width 200 :height 10))
    (%assert-equal (handle-event spacer nil '(:mouse-down :button :left :x 2 :y 2))
                   nil
                   "menu-spacer ignores events")))

(%deftest test-menu-aligns-icon-label-and-key-columns
  (%with-stubbed-menu-text-render
    (let* ((menu (make-instance 'menu
                                :entries (list '(:text "Open" :command :open :icon (:width 16 :height 16) :key "Ctrl-O")
                                               '(:text "Save As" :command :save-as :icon (:width 24 :height 24) :key "Ctrl-Shift-S")
                                               '(:text "Exit" :command :quit))))
           (items nil))
      (layout menu (make-rect :x 0 :y 0 :width 320 :height 200))
      (setf items (%menu-item-children-only menu))
      (%assert-equal (menu-icon-column-width menu) 24 "menu icon column width uses widest icon")
      (%assert-equal (menu-label-column-width menu)
                     (reduce #'max items :key #'%menu-item-label-width :initial-value 0)
                     "menu label column width uses widest label")
      (%assert-equal (menu-key-column-width menu)
                     (reduce #'max items :key #'%menu-item-key-width :initial-value 0)
                     "menu key column width uses widest key")
      (let ((label-xs (mapcar (lambda (item)
                                (rect-x (menu-item-label-draw-rect item)))
                              items))
            (key-right-edges (loop for item in items
                                   for key-rect = (menu-item-key-draw-rect item)
                                   when (> (rect-width key-rect) 0)
                                   collect (+ (rect-x key-rect)
                                              (rect-width key-rect)))))
        (%assert-equal (every (lambda (x) (= x (first label-xs))) label-xs)
                       t
                       "menu label x positions align across rows")
        (%assert-equal (every (lambda (x) (= x (first key-right-edges))) key-right-edges)
                       t
                       "menu key right edges align across keyed rows")))))

(%deftest test-menu-min-width-covers-aligned-columns
  (%with-stubbed-menu-text-render
    (let* ((menu (make-instance 'menu
                                :entries (list '(:text "A" :command :a :icon (:width 12 :height 12) :key "Ctrl-A")
                                               '(:text "Longer Label" :command :b :key "Ctrl-Shift-Alt-B"))))
           (request (measure menu)))
      (%assert-equal (> (size-request-min-width request) 60)
                     t
                     "menu min-width reflects combined aligned columns"))))

(%deftest test-menu-does-not-force-window-width
  (%with-stubbed-menu-text-render
    (let* ((menu (make-instance 'menu
                                :entries (list '(:text "Open" :command :open)
                                               '(:text "Save" :command :save)
                                               '(:text "Exit" :command :quit))))
           (request (measure menu))
           (root (make-instance 'window :width 260 :height 180 :child menu)))
      (%assert-equal (size-request-expand-x request)
                     nil
                     "menu does not request horizontal expansion")
      (layout root (make-rect :x 0 :y 0 :width 260 :height 180))
      (%assert-equal (rect-width (widget-layout-rect menu))
                     (size-request-min-width request)
                     "window uses menu intrinsic width when menu does not expand"))))

(%deftest test-menu-spacer-occupies-row-between-items
  (%with-stubbed-menu-text-render
    (let* ((menu (make-instance 'menu
                                :entries (list '(:text "Open" :command :open)
                                               :spacer
                                               '(:text "Exit" :command :quit))))
           (children (menu-children menu))
           (first-item (first children))
           (spacer (second children))
           (third-item (third children)))
      (layout menu (make-rect :x 0 :y 0 :width 200 :height 120))
      (%assert-equal (typep spacer 'menu-spacer) t "second row is a menu-spacer")
      (%assert-equal (> (rect-y (widget-layout-rect spacer))
                        (rect-y (widget-layout-rect first-item)))
                     t
                     "spacer appears below first item")
      (%assert-equal (> (rect-y (widget-layout-rect third-item))
                        (rect-y (widget-layout-rect spacer)))
                     t
                     "third item appears below spacer")
      (%assert-equal (rect-width (widget-layout-rect spacer))
                     (rect-width (widget-layout-rect first-item))
                     "spacer fills menu content width"))))

(%deftest test-menu-item-hover-render-uses-highlighted-background
  (%with-stubbed-menu-text-render
    (let* ((item (make-instance 'menu-item
                                :text "Save"
                                :command :save
                                :highlighted-color '(1 2 3 255)
                                :state :hovered))
           (calls '())
           (old-fill (symbol-function 'minerva.gui::%call-fill-rect))
           (old-draw (symbol-function 'minerva.gui::%call-draw-surface-rect)))
      (unwind-protect
           (progn
             (setf (symbol-function 'minerva.gui::%call-fill-rect)
                   (lambda (backend-window rect color)
                     (declare (ignore backend-window rect))
                     (push color calls)))
             (setf (symbol-function 'minerva.gui::%call-draw-surface-rect)
                   (lambda (&rest args)
                     (declare (ignore args))
                     nil))
             (layout item (make-rect :x 0 :y 0 :width 180 :height 30))
             (render item nil))
        (setf (symbol-function 'minerva.gui::%call-fill-rect) old-fill)
        (setf (symbol-function 'minerva.gui::%call-draw-surface-rect) old-draw))
      (%assert-equal (first calls) '(1 2 3 255) "hovered menu-item renders highlighted background"))))

(%deftest test-menu-item-key-text-uses-theme-default-color
  (%with-stubbed-menu-text-render
    (let ((item (make-instance 'menu-item :text "Exit" :command :quit :key-text "Ctrl-X")))
      (%assert-equal (getf (menu-item-label-surface item) :color)
                     '(0 0 0 255)
                     "menu-item label uses primary text color")
      (%assert-equal (getf (menu-item-key-surface item) :color)
                     '(0 0 0 255)
                     "menu-item key-text uses theme default color"))))

(%deftest test-menu-renders-panel-before-row-content
  (%with-stubbed-menu-text-render
    (let* ((menu (make-instance 'menu
                                :panel-surface '(:width 48 :height 48)
                                :entries (list '(:text "Open" :command :open))))
           (events '())
           (old-scaled (symbol-function 'minerva.gui::%call-draw-surface-rect-scaled))
           (old-draw (symbol-function 'minerva.gui::%call-draw-surface-rect)))
      (unwind-protect
           (progn
             (setf (symbol-function 'minerva.gui::%call-draw-surface-rect-scaled)
                   (lambda (&rest args)
                     (declare (ignore args))
                     (push :panel events)))
             (setf (symbol-function 'minerva.gui::%call-draw-surface-rect)
                   (lambda (&rest args)
                     (declare (ignore args))
                     (push :item events)))
             (layout menu (make-rect :x 0 :y 0 :width 220 :height 80))
             (render menu nil))
        (setf (symbol-function 'minerva.gui::%call-draw-surface-rect-scaled) old-scaled)
        (setf (symbol-function 'minerva.gui::%call-draw-surface-rect) old-draw))
      (%assert-equal (car (last events)) :panel "menu panel draws before menu-item content"))))

(%deftest test-menu-event-routing-and-row-specific-click
  (%with-stubbed-menu-text-render
    (let* ((menu (make-instance 'menu
                                :entries (list '(:text "Open" :command :open)
                                               '(:text "Save" :command :save)
                                               '(:text "Exit" :command :quit))))
           (root (make-instance 'window :width 260 :height 180 :child menu))
           (state (minerva.events:make-app-state :root root)))
      (layout root (make-rect :x 0 :y 0 :width 260 :height 180))
      (let* ((children (%menu-item-children-only menu))
             (first-item (first children))
             (second-item (second children))
             (first-rect (widget-layout-rect first-item))
             (second-rect (widget-layout-rect second-item))
             (first-point (list (+ (rect-x first-rect) 2) (+ (rect-y first-rect) 2)))
             (second-point (list (+ (rect-x second-rect) 2) (+ (rect-y second-rect) 2))))
        (%assert-equal (minerva.events:route-minerva-event
                        state
                        (list :mouse-down :button :left :x (first first-point) :y (second first-point)))
                       first-item
                       "mouse routes to first menu item by hit test")
        (setf (minerva.events:app-state-last-command state) nil)
        (minerva.events:process-minerva-event
         state
         (list :mouse-down :button :left :x (first second-point) :y (second second-point)))
        (minerva.events:process-minerva-event
         state
         (list :mouse-up :button :left :x (first second-point) :y (second second-point)))
        (%assert-equal (minerva.events:app-state-last-command state)
                       :save
                       "clicking one row activates only that row command")))))