;;;; minerva.lisp

(ql:quickload :uiop)
(asdf:load-asd (merge-pathnames "minerva.asd" (uiop:getcwd)))
(ql:quickload "minerva")

;; now you can run a test with this syntax
;; (fiveam:run! 'minerva/tests::base-tests)

;; load the SDL wrapper
(ql:quickload :cffi)
(cffi:define-foreign-library sdl-wrapper (t 
    (:default #.(uiop:native-namestring (merge-pathnames "SDL_LIB/libsdlwrapper" (uiop:getcwd))))))
(cffi:use-foreign-library sdl-wrapper)

;; define the functions we want to use

(cffi:defcfun ("setup" setup) :pointer (title :string) (width :int) (height :int))
(cffi:defcfun ("cleanup" cleanup) :void (window :pointer))
(cffi:defcfun ("get_window_surface" get_window_surface) :pointer (window :pointer))
(cffi:defcfun ("get_color" get_color) :uint32 (screen :pointer) (red :uint32) (green :uint32) (blue :uint32))
(cffi:defcfun ("get_rect" get_rect) :pointer (xpos :int) (ypos :int) (width :int) (height :int))
(cffi:defcfun ("free_memory" free_memory) :void)
(cffi:defcfun ("draw_rectangle" draw_rectangle) :void (screen :pointer) (area :pointer) (color :uint32))
(cffi:defcfun ("clear_screen" clear_screen) :void (screen :pointer))
(cffi:defcfun ("update_window" update_window) :void (window :pointer))
(cffi:defcfun ("quit_game" quit_game) :int)
(cffi:defcfun ("cleanup" cleanup) :void (window :pointer))


;; instead of this test window, we actually need to do the following:
;; open window and then pump the event queue
;; we need to add a new event, which is the frame rate; set this at 60 FPS


(defun test-window ()
    (let* ((window (setup "Minerva v0.01" 640 480))
           (screen (get_window_surface window))
           (rect (get_rect 100 100 200 200))
           (color (get_color screen 252 102 0)))
        (progn
            (clear_screen screen)
            (draw_rectangle screen rect color)
            (update_window window)
            (loop while (eql (quit_game) 0))
            (cleanup window))))

(test-window)
(exit)

