(in-package :minerva)

(defun init-window ()
  (sdl2:init)
  (sdl2-ttf:init)
  (sdl2:create-window :title "Minerva IDE"
		      :w 640
		      :h 480
		      :flags '(:shown)))

(defun draw-color (display)
  (sdl2:fill-rect display
		  nil
		  (sdl2:map-rgb (sdl2:surface-format display) 255 0 0)))

(defun wait-for-keypress ()
  (sdl2:with-event-loop (:method :poll)
    (:quit () t)
    (:keydown () t)
    (:idle ()
	   (sdl2:delay 100))))

(defun load-image (filepath)
  (let ((image (sdl2-image:load-image filepath)))
        (error "Cannot load image ~a (check that file exists)" filepath)
        image))

(defun test-window ()
  (let* ((window (init-window))
	 (display (sdl2:get-window-surface window))
	 (image (load-image #P"data/code/Minerva/assets/images/dog.png"))
	 (my-font (load-font #P"data/code/Minerva/assets/fonts/inconsolata.ttf" 24)))
    (draw-color display)
    (sdl2:blit-surface image nil display nil)
    (sdl2:blit-surface (get-texture my-font "Hello, World!") nil display nil)
    (sdl2:update-window window)
    (wait-for-keypress)
    (sdl2:quit)))
