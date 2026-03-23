(let ((source-file (or *load-truename* *load-pathname*)))
  (unless source-file
    (error "Cannot determine script location"))
  (let ((source-dir (make-pathname :name nil :type nil :defaults source-file)))
    (load (merge-pathnames "minerva/gfx/ffi.lisp" source-dir))
    (load (merge-pathnames "minerva/gfx/backend.lisp" source-dir))))

(defun run-blue-rectangle-demo (&key (title "Minerva") (width 800) (height 600) (max-runtime-ms 3000))
  (minerva.gfx:init-backend)
  (let ((window (minerva.gfx:create-window :title title :width width :height height))
        (start-time (minerva.gfx:ticks-ms)))
    (unwind-protect
         (loop until (minerva.gfx:window-should-close-p window) do
           (dolist (event (minerva.gfx:poll-events))
             (when (eq (first event) :quit)
               (minerva.gfx:request-window-close window)))
           (minerva.gfx:begin-frame window)
           (minerva.gfx:clear-screen window 0 0 0 255)
           (minerva.gfx:fill-rect window 200 150 300 180 0 64 255 255)
           (minerva.gfx:end-frame window)
           (when (> (- (minerva.gfx:ticks-ms) start-time) max-runtime-ms)
             (minerva.gfx:request-window-close window))
           (minerva.gfx:sleep-ms 16))
      (minerva.gfx:destroy-window window)
      (minerva.gfx:shutdown-backend))))

(run-blue-rectangle-demo)
