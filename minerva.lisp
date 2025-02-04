;;;; minerva.lisp

(ql:quickload :uiop)
(ql:quickload :cffi)
(ql:quickload :cffi-object)
(asdf:load-asd (merge-pathnames "minerva.asd" (uiop:getcwd)))
(ql:quickload "minerva")

;; load the SDL wrapper
(cffi:define-foreign-library sdl-wrapper (t 
    (:default #.(uiop:native-namestring (merge-pathnames "SDL_LIB/libsdlwrapper" (uiop:getcwd))))))
(cffi:use-foreign-library sdl-wrapper)


;; define the structs we need for the engine and the rect
(cffi:defcstruct rect
  (xpos :int)
  (ypos :int)
  (width :int)
  (height :int))

(cffi:defcstruct frame-input
    (mousex :int)
    (mousey :int)
    (mouse_left_down :bool)
    (mouse_right_down :bool)
    (exit :bool))

(cffi:defcstruct engine
    (window (:pointer :void))
    (render (:pointer :void)))



;; create the CLOS objects to handle these
(cobj:define-cobject-class (rect (:struct rect)))
(cobj:define-cobject-class (frame-input (:struct frame-input)))
(cobj:define-cobject-class (engine (:struct engine)))


;; define the functions we want to use
(cffi:defcfun ("init_engine" init_engine) :void (engine :pointer) (title :string) (width :int) (height :int))
(cffi:defcfun ("process_events" process_events) :void (input :pointer))
(cffi:defcfun ("clear_screen" clear_screen) :void (engine :pointer))
(cffi:defcfun ("draw_rectangle" draw_rectangle) :void (render :pointer) (rect :pointer) (html_color :string))
(cffi:defcfun ("update_screen" update_screen) :void (engine :pointer))
(cffi:defcfun ("cleanup" cleanup) :void (engine :pointer))

(defmacro c-ptr (input)
    ;; having cobj:cobject-pointer in front of everything gets old
    `(cobj:cobject-pointer ,input))

(defun minerva-ide ()
    (let* ((engine (make-engine))
           (my-rect (make-rect :xpos 100 :ypos 100 :width 200 :height 200))
           (input (make-frame-input :exit nil)))
        (progn
            (init_engine (c-ptr engine) "Minerva IDE" 640 480)
            (loop while (not (frame-input-exit input)) do
                (progn
                    (process_events (c-ptr input))
                    (clear_screen (c-ptr engine))
                    (draw_rectangle (c-ptr (engine-render engine)) (c-ptr my-rect) "#FF7F00")
                    (update_screen (c-ptr engine))))
                (cleanup (c-ptr (engine-window engine))))))

(minerva-ide)
(exit)

