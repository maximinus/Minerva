(asdf:load-asd #P"/home/sparky/data/code/Minerva/minerva.asd")
(ql:quickload "sdl2")
(ql:quickload "sdl2-image")
(ql:quickload "sdl2-ttf")
(ql:quickload "minerva")

(in-package :minerva)

(defun single-colorrect-example ()
  (let* ((crect (make-instance 'ColorRect :size (make-size 256 256) :color '(255 0 0 0)))
	 (example-frame (make-frame (make-size 256 256) (make-pos 64 64) (list crect))))
    (start-minerva (list example-frame))))

(single-colorrect-example)
