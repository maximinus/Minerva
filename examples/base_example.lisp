(asdf:load-asd #P"/home/sparky/data/code/Minerva/minerva.asd")
(ql:quickload "sdl2")
(ql:quickload "sdl2-image")
(ql:quickload "sdl2-ttf")
(ql:quickload "minerva")

(in-package "minerva")

(defun single-colorrect-example ()
  (let* ((example-frame (make-frame (make-size 256 256) (make-position 64 64)))
	 (crect (make-instance 'ColorRect :size (make-size 256 256) :color '(255 0 0 0))))
    (add-widget example-frame crect)
    (start-minerva (list crect))))

(single-colorrect-example)
