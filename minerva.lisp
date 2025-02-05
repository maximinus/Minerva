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
(cffi:defcfun ("init_engine" c_init_engine) :void (engine :pointer) (title :string) (width :int) (height :int))
(cffi:defcfun ("process_events" c_process_events) :void (input :pointer))
(cffi:defcfun ("clear_screen" c_clear_screen) :void (engine :pointer))
(cffi:defcfun ("draw_rectangle" c_draw_rectangle) :void (engine :pointer) (rect :pointer) (html_color :string))
(cffi:defcfun ("update_screen" c_update_screen) :void (engine :pointer))
(cffi:defcfun ("cleanup" c_cleanup) :void (engine :pointer))


;; so what we want to define is just the functions for the drawing / updating and so on
;; this way, none of the Lisp code will see a raw pointer. To do this, we define some functions

(defmacro c-ptr (input)
    ;; having cobj:cobject-pointer in front of everything gets old
    `(cobj:cobject-pointer ,input))


;; define a global sdl-interface with all sdl functions
(defclass sdl-interface ()
    ((engine :accessor engine)
     (input :accessor input)))

(defmethod initialize-instance :after ((self sdl-interface) &key)
    (setf (engine self) (make-engine))
    (setf (input self) (make-frame-input :exit nil)))


(defmethod init ((self sdl-interface) title width height)
    (c_init_engine (c-ptr (engine self)) title width height))

(defmethod clear-screen ((self sdl-interface))
    (c_clear_screen (c-ptr (engine self))))

(defmethod update-screen ((self sdl-interface))
    (c_update_screen (c-ptr (engine self))))

(defmethod cleanup-sdl ((self sdl-interface))
    (c_cleanup (c-ptr (engine self))))

(defmethod draw-rectangle ((self sdl-interface) area color)
    (c_draw_rectangle (c-ptr (engine self)) (c-ptr area) color))

(defmethod process-events ((self sdl-interface))
    (c_process_events (c-ptr (input self))))


;; create an instance of this sdl interface
(defparameter sdl
  (make-instance 'sdl-interface))


;; now the code is much simpler, and no c-pointers!
(defun minerva-ide ()
    (let ((my-rect (make-rect :xpos 100 :ypos 100 :width 200 :height 200)))
        (progn
            (init sdl "Minerva IDE" 640 480)
            (loop while  (not (frame-input-exit (input sdl))) do
                (progn
                    (process-events sdl)
                    (clear-screen sdl)
                    (draw-rectangle sdl my-rect "#FF7F00")
                    (update-screen sdl)))
                (cleanup-sdl sdl))))

(minerva-ide)
(exit)

