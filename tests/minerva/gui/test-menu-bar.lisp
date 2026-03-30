(in-package :minerva.gui)

(defmacro %with-stubbed-menu-bar-gfx (&body body)
  `(let ((old-render (symbol-function 'minerva.gui::%render-label-text-surface))
         (old-load-default (symbol-function 'minerva.gui::%menu-load-default-panel-surface)))
     (unwind-protect
          (progn
            (setf (symbol-function 'minerva.gui::%render-label-text-surface)
                  (lambda (font-name text-size text color)
                    (declare (ignore font-name text-size color))
                    (list :width (max 1 (* 7 (length (or text ""))))
                          :height 14)))
            (setf (symbol-function 'minerva.gui::%menu-load-default-panel-surface)
                  (lambda ()
                    '(:width 32 :height 24)))
            ,@body)
       (setf (symbol-function 'minerva.gui::%render-label-text-surface) old-render)
       (setf (symbol-function 'minerva.gui::%menu-load-default-panel-surface) old-load-default))))

(%deftest test-menu-bar-construction-builds-buttons-and-mapping
  (%with-stubbed-menu-bar-gfx
    (let* ((bar (make-instance 'menu-bar
                               :entries (list '(:text "File" :items ((:text "Open" :command :open)))
                                              '(:text "Edit" :items ((:text "Cut" :command :cut)))
                                              '(:text "Help" :items ((:text "About" :command :about))))))
           (buttons (menu-bar-buttons bar)))
      (%assert-equal (length buttons) 3 "menu bar builds one button per entry")
      (%assert-equal (mapcar #'menu-bar-button-text buttons)
                     '("File" "Edit" "Help")
                     "menu bar button text order matches entry order")
      (%assert-equal (mapcar #'menu-bar-button-entry-index buttons)
                     '(0 1 2)
                     "menu bar button index maps each entry"))))

(%deftest test-menu-bar-uses-nine-patch-containing-hbox
  (%with-stubbed-menu-bar-gfx
    (let ((bar (make-instance 'menu-bar
                              :entries (list '(:text "File" :items ((:text "Open" :command :open)))))))
      (%assert-equal (typep (menu-bar-panel bar) 'nine-patch)
                     t
                     "menu bar renders through nine-patch panel")
      (%assert-equal (typep (menu-bar-button-row bar) 'hbox)
                     t
                     "menu bar stores buttons in hbox row"))))

(%deftest test-open-menubar-button-stays-pressed-on-mouse-leave
  (%with-stubbed-menu-bar-gfx
    (let* ((bar (make-instance 'menu-bar
                               :entries (list '(:text "File" :items ((:text "Open" :command :open)))
                                              '(:text "Edit" :items ((:text "Cut" :command :cut))))))
           (root (make-instance 'window :width 240 :height 40 :child bar))
           (state (minerva.events:make-app-state :root root))
           (file-button (first (menu-bar-buttons bar))))
      (layout root (make-rect :x 0 :y 0 :width 240 :height 40))
      (setf (menu-bar-open-index bar) 0)
      (%menu-bar-set-button-state file-button state :pressed)
      (handle-event file-button state '(:mouse-leave))
      (%assert-equal (menu-bar-button-state file-button)
                     :pressed
                     "open menubar button keeps pressed state on mouse leave"))))
