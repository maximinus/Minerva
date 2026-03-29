(in-package :minerva.gui)

(defparameter +default-menu-nine-patch-image-path+
  "/assets/menu/menu.png")

(defparameter *default-image-paths*
  (list (cons :menu-nine-patch +default-menu-nine-patch-image-path+)))

(defun %gui-project-root ()
  (or (ignore-errors (asdf:system-source-directory "minerva"))
      (truename "./")))

(defun %normalize-default-image-relative-path (path)
  (if (and (stringp path)
           (> (length path) 0)
           (char= (char path 0) #\/))
      (format nil "minerva~A" path)
      path))

(defun default-image-path (name &key (absolute nil))
  (let ((entry (assoc name *default-image-paths*)))
    (unless entry
      (error "Unknown default image name ~S" name))
    (let ((path (cdr entry)))
      (if absolute
          (namestring
           (merge-pathnames (%normalize-default-image-relative-path path)
                            (%gui-project-root)))
          path))))

(defun load-default-image-surface (name)
  (let ((load-fn (%gfx-function "LOAD-SURFACE")))
    (unless load-fn
      (error "minerva.gfx:load-surface is unavailable. Load src/minerva/gfx/ffi.lisp and src/minerva/gfx/backend.lisp first."))
    (funcall load-fn (default-image-path name :absolute t))))
