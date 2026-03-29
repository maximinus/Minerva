(defpackage :minerva.gfx.ffi
  (:use :cl :sb-alien)
  (:export
   :event-none
   :event-quit
   :event-window-resized
   :event-key-down
   :event-key-up
   :event-mouse-button-down
   :event-mouse-button-up
   :event-mouse-move
   :c-window
  :c-surface
  :c-font
   :c-event
   :ensure-native-library-loaded
   :%init
   :%shutdown
   :%last-error
   :%window-create
   :%window-destroy
   :%window-should-close
   :%window-request-close
   :%window-get-size
   :%poll-event
   :%begin-frame
   :%clear
   :%fill-rect
   :%end-frame
  :%surface-create-blank
  :%surface-load-file
  :%surface-destroy
  :%surface-width
  :%surface-height
  :%surface-is-rgba32
  :%surface-fill-rect
  :%surface-fill
  :%surface-read-pixel
  :%surface-blit
  :%surface-blit-rect
  :%surface-blit-rect-scaled
  :%window-draw-surface
  :%window-draw-surface-rect
  :%window-draw-surface-rect-scaled
  :%font-get
  :%font-destroy
  :%font-measure-text
  :%font-render-text
   :%ticks-ms
   :%sleep-ms))

(in-package :minerva.gfx.ffi)

(defconstant event-none 0)
(defconstant event-quit 1)
(defconstant event-window-resized 2)
(defconstant event-key-down 3)
(defconstant event-key-up 4)
(defconstant event-mouse-button-down 5)
(defconstant event-mouse-button-up 6)
(defconstant event-mouse-move 7)

(defvar *native-library-loaded* nil)
(defparameter *ffi-source-file*
  (or *load-truename* *load-pathname*))

(defun %this-file-dir ()
  (let ((source *ffi-source-file*))
    (unless source
      (error "Cannot determine file location while loading minerva/gfx/ffi.lisp"))
    (make-pathname :name nil :type nil :defaults source)))

(defun %repo-root ()
  (truename (merge-pathnames "../../../" (%this-file-dir))))

(defun ensure-native-library-loaded ()
  (unless *native-library-loaded*
    (let* ((root (%repo-root))
           (workspace-root (ignore-errors (truename "./")))
           (sdl-path (merge-pathnames "build/native/_deps/sdl3-build/libSDL3.so" root))
           (native-path (merge-pathnames "build/native/libminerva_native.so" root))
           (fallback-sdl-path (and workspace-root
                                   (merge-pathnames "build/native/_deps/sdl3-build/libSDL3.so" workspace-root)))
           (fallback-native-path (and workspace-root
                                      (merge-pathnames "build/native/libminerva_native.so" workspace-root))))
      (unless (probe-file native-path)
        (when (and fallback-native-path (probe-file fallback-native-path))
          (setf native-path fallback-native-path))
        (when (and fallback-sdl-path (probe-file fallback-sdl-path))
          (setf sdl-path fallback-sdl-path)))
      (when (probe-file sdl-path)
        (load-shared-object (namestring sdl-path)))
      (unless (probe-file native-path)
        (error "Native library not found at ~A. Build native target first." (namestring native-path)))
      (load-shared-object (namestring native-path))
      (setf *native-library-loaded* t))))

(define-alien-type c-window (* t))
(define-alien-type c-surface (* t))
(define-alien-type c-font (* t))

(define-alien-type c-event
  (struct c-event
    (type int)
    (a int)
    (b int)
    (c int)
    (d int)))

(define-alien-routine ("init" %init) int)
(define-alien-routine ("minerva_shutdown" %shutdown) void)
(define-alien-routine ("last_error" %last-error) c-string)

(define-alien-routine ("window_create" %window-create) c-window
  (title c-string)
  (width int)
  (height int))

(define-alien-routine ("window_destroy" %window-destroy) void
  (window c-window))

(define-alien-routine ("window_should_close" %window-should-close) int
  (window c-window))

(define-alien-routine ("window_request_close" %window-request-close) void
  (window c-window))

(define-alien-routine ("window_get_size" %window-get-size) void
  (window c-window)
  (width (* int))
  (height (* int)))

(define-alien-routine ("poll_event" %poll-event) int
  (out-event (* c-event)))

(define-alien-routine ("begin_frame" %begin-frame) void
  (window c-window))

(define-alien-routine ("clear" %clear) void
  (window c-window)
  (r unsigned-char)
  (g unsigned-char)
  (b unsigned-char)
  (a unsigned-char))

(define-alien-routine ("fill_rect" %fill-rect) void
  (window c-window)
  (x int)
  (y int)
  (width int)
  (height int)
  (r unsigned-char)
  (g unsigned-char)
  (b unsigned-char)
  (a unsigned-char))

(define-alien-routine ("end_frame" %end-frame) void
  (window c-window))

(define-alien-routine ("surface_create_blank" %surface-create-blank) c-surface
  (width int)
  (height int))

(define-alien-routine ("surface_load_file" %surface-load-file) c-surface
  (path c-string))

(define-alien-routine ("surface_destroy" %surface-destroy) void
  (surface c-surface))

(define-alien-routine ("surface_width" %surface-width) int
  (surface c-surface))

(define-alien-routine ("surface_height" %surface-height) int
  (surface c-surface))

(define-alien-routine ("surface_is_rgba32" %surface-is-rgba32) int
  (surface c-surface))

(define-alien-routine ("surface_fill_rect" %surface-fill-rect) int
  (surface c-surface)
  (x int)
  (y int)
  (width int)
  (height int)
  (r unsigned-char)
  (g unsigned-char)
  (b unsigned-char)
  (a unsigned-char))

(define-alien-routine ("surface_fill" %surface-fill) int
  (surface c-surface)
  (r unsigned-char)
  (g unsigned-char)
  (b unsigned-char)
  (a unsigned-char))

(define-alien-routine ("surface_read_pixel" %surface-read-pixel) int
  (surface c-surface)
  (x int)
  (y int)
  (r (* unsigned-char))
  (g (* unsigned-char))
  (b (* unsigned-char))
  (a (* unsigned-char)))

(define-alien-routine ("surface_blit" %surface-blit) int
  (src c-surface)
  (dst c-surface)
  (dst-x int)
  (dst-y int))

(define-alien-routine ("surface_blit_rect" %surface-blit-rect) int
  (src c-surface)
  (src-x int)
  (src-y int)
  (src-width int)
  (src-height int)
  (dst c-surface)
  (dst-x int)
  (dst-y int))

(define-alien-routine ("surface_blit_rect_scaled" %surface-blit-rect-scaled) int
  (src c-surface)
  (src-x int)
  (src-y int)
  (src-width int)
  (src-height int)
  (dst c-surface)
  (dst-x int)
  (dst-y int)
  (dst-width int)
  (dst-height int))

(define-alien-routine ("window_draw_surface" %window-draw-surface) int
  (window c-window)
  (surface c-surface)
  (dst-x int)
  (dst-y int))

(define-alien-routine ("window_draw_surface_rect" %window-draw-surface-rect) int
  (window c-window)
  (surface c-surface)
  (src-x int)
  (src-y int)
  (src-width int)
  (src-height int)
  (dst-x int)
  (dst-y int))

(define-alien-routine ("window_draw_surface_rect_scaled" %window-draw-surface-rect-scaled) int
  (window c-window)
  (surface c-surface)
  (src-x int)
  (src-y int)
  (src-width int)
  (src-height int)
  (dst-x int)
  (dst-y int)
  (dst-width int)
  (dst-height int))

(define-alien-routine ("font_get" %font-get) c-font
  (name-or-path c-string)
  (size int))

(define-alien-routine ("font_destroy" %font-destroy) void
  (font c-font))

(define-alien-routine ("font_measure_text" %font-measure-text) int
  (font c-font)
  (text c-string)
  (width (* int))
  (height (* int)))

(define-alien-routine ("font_render_text" %font-render-text) c-surface
  (font c-font)
  (text c-string)
  (r unsigned-char)
  (g unsigned-char)
  (b unsigned-char)
  (a unsigned-char))

(define-alien-routine ("ticks_ms" %ticks-ms) unsigned-long-long)

(define-alien-routine ("sleep_ms" %sleep-ms) void
  (ms int))
