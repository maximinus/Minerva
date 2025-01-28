(load (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))

(ql:quickload :cffi)

(cffi:define-foreign-library sdl-wrapper (t (:default "/home/sparky/data/code/Minerva/SDL3/libsdlwrapper")))

(cffi:use-foreign-library sdl-wrapper)

;;; Now define the foreign functions
(cffi:defcfun ("setup" setup) :pointer (title :string) (width :int) (height :int))
(cffi:defcfun ("cleanup" cleanup) :void (window :pointer))
(cffi:defcfun ("wait" wait) :void)

;;; run with "sbcl --script example.lisp"
(let ((w (setup "SBCL + SDL Window" 640 480)))
  (unless (cffi:null-pointer-p w)
    (format t "Window created!~%")
    (wait)
    (cleanup w)
    (format t "All done.~%")))
