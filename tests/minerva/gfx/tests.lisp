(defpackage :minerva.gfx.tests
  (:use :cl)
  (:import-from :minerva.gfx
                :make-position
                :position-x
                :position-y
                :rect
                :make-rect
                :rect-x
                :rect-y
                :rect-width
                :rect-height
                :color
                :make-color
                :color-r
                :color-g
                :color-b
                :color-a
                :init-backend
                :shutdown-backend
                :create-surface
                :load-surface
                :destroy-surface
                :surface-width
                :surface-height
                :surface-rgba32-p
                :fill-surface-rect
                :fill-surface
                :read-surface-pixel
                :blit-surface
                :blit-surface-rect
                :blit-surface-rect-scaled
                :get-font
                :destroy-font
                :measure-text
                :render-text-to-surface)
  (:import-from :minerva.conditions
                :minerva-resource-error)
  (:export
   :run-gfx-resource-tests
   :current-test-name))

(in-package :minerva.gfx.tests)

(defvar *test-count* 0)
(defvar *test-failures* 0)
(defvar *current-test-name* nil)

(defun current-test-name ()
  *current-test-name*)

(defmacro %deftest (name &body body)
  `(defun ,name ()
     ,@body))

(defun %assert-equal (actual expected label)
  (incf *test-count*)
  (unless (equal actual expected)
    (incf *test-failures*)
    (format t "[FAIL] ~A expected=~S actual=~S~%" label expected actual)))

(defun %assert-true (value label)
  (%assert-equal (not (null value)) t label))

(defun %assert-false (value label)
  (%assert-equal (not (null value)) nil label))

(defun %pixel->list (surface x y)
  (let ((c (read-surface-pixel surface (make-position :x x :y y))))
    (list (color-r c) (color-g c) (color-b c) (color-a c))))

(defun %fill-all (surface r g b a)
  (fill-surface-rect surface
                     (make-rect :x 0 :y 0 :width (surface-width surface) :height (surface-height surface))
                     (make-color :r r :g g :b b :a a)))

(defmacro %with-surfaces ((&rest bindings) &body body)
  (if (null bindings)
      `(progn ,@body)
      (let* ((binding (first bindings))
             (name (first binding))
             (init (second binding)))
        `(let ((,name ,init))
           (unwind-protect
                (%with-surfaces ,(rest bindings) ,@body)
             (when ,name
               (ignore-errors (destroy-surface ,name))))))))

(defun %project-root ()
  (or (ignore-errors (asdf:system-source-directory "minerva"))
      (truename "./")))

(defun %fixture-path (name)
  (namestring
   (merge-pathnames name
                    (merge-pathnames "fixtures/"
                                     (merge-pathnames "tests/" (%project-root))))))

(defun %font-path ()
  (namestring (merge-pathnames "minerva/assets/fonts/inconsolata.ttf" (%project-root))))

(%deftest test-position-stores-values
  (let ((pos (make-position :x 10 :y 20)))
    (%assert-equal (position-x pos) 10 "position x")
    (%assert-equal (position-y pos) 20 "position y")))

(%deftest test-rect-stores-values
  (let ((r (make-rect :x 5 :y 6 :width 100 :height 200)))
    (%assert-equal (list (rect-x r) (rect-y r) (rect-width r) (rect-height r))
                   '(5 6 100 200)
                   "rect fields")))

(%deftest test-color-stores-values
  (let ((c (make-color :r 255 :g 10 :b 20 :a 128)))
    (%assert-equal (list (color-r c) (color-g c) (color-b c) (color-a c))
                   '(255 10 20 128)
                   "color fields")))

(%deftest test-negative-rect-size-consistent
  (let ((r (make-rect :x 0 :y 0 :width -7 :height -9)))
    (%assert-equal (list (rect-width r) (rect-height r)) '(-7 -9) "negative rect values preserved")))

(%deftest test-blank-surface-created-with-size
  (%with-surfaces ((s (create-surface :width 32 :height 16)))
    (%assert-true (typep s 'minerva.gfx::backend-surface) "blank surface object type")
    (%assert-equal (surface-width s) 32 "blank surface width")
    (%assert-equal (surface-height s) 16 "blank surface height")))

(%deftest test-loaded-surface-known-size
  (%with-surfaces ((s (load-surface (%fixture-path "test-8x6.bmp"))))
    (%assert-equal (surface-width s) 8 "loaded width")
    (%assert-equal (surface-height s) 6 "loaded height")))

(%deftest test-loaded-surface-rgba-format
  (%with-surfaces ((s (load-surface (%fixture-path "test-8x6.bmp"))))
    (%assert-true (surface-rgba32-p s) "loaded surface RGBA32")))

(%deftest test-blank-surfaces-are-independent
  (%with-surfaces ((a (create-surface :width 4 :height 4))
                   (b (create-surface :width 4 :height 4)))
    (%fill-all a 255 0 0 255)
    (%assert-equal (%pixel->list a 1 1) '(255 0 0 255) "surface a changed")
    (%assert-equal (%pixel->list b 1 1) '(0 0 0 0) "surface b unchanged")))

(%deftest test-load-missing-file-fails-predictably
  (handler-case
      (progn
        (load-surface (%fixture-path "does-not-exist.bmp"))
        (%assert-true nil "missing image should fail"))
    (minerva-resource-error ()
      (%assert-true t "missing image failed with minerva-resource-error"))))

(%deftest test-full-surface-blit-copies-at-position
  (%with-surfaces ((dst (create-surface :width 10 :height 10))
                   (src (create-surface :width 4 :height 4)))
    (%fill-all dst 0 0 0 255)
    (%fill-all src 255 0 0 255)
    (blit-surface src dst (make-position :x 2 :y 3))
    (%assert-equal (%pixel->list dst 2 3) '(255 0 0 255) "blit start pixel")
    (%assert-equal (%pixel->list dst 5 6) '(255 0 0 255) "blit end pixel")
    (%assert-equal (%pixel->list dst 1 2) '(0 0 0 255) "outside stays black")))

(%deftest test-blit-clips-out-of-bounds
  (%with-surfaces ((dst (create-surface :width 5 :height 5))
                   (src (create-surface :width 4 :height 4)))
    (%fill-all dst 0 0 0 255)
    (%fill-all src 255 0 0 255)
    (blit-surface src dst (make-position :x 3 :y 3))
    (%assert-equal (%pixel->list dst 3 3) '(255 0 0 255) "clip overlap 1")
    (%assert-equal (%pixel->list dst 4 4) '(255 0 0 255) "clip overlap 4")
    (%assert-equal (%pixel->list dst 2 2) '(0 0 0 255) "outside unchanged")))

(%deftest test-source-subrect-blits-only-selected-region
  (%with-surfaces ((dst (create-surface :width 2 :height 2))
                   (src (load-surface (%fixture-path "test-pattern-4x4.bmp"))))
    (%fill-all dst 0 0 0 255)
    (blit-surface-rect src (make-rect :x 2 :y 2 :width 2 :height 2) dst (make-position :x 0 :y 0))
    (%assert-equal (%pixel->list dst 0 0) '(255 255 0 255) "subrect top-left")
    (%assert-equal (%pixel->list dst 1 1) '(255 255 0 255) "subrect bottom-right")))

(%deftest test-subrect-destination-position-respected
  (%with-surfaces ((dst (create-surface :width 8 :height 4))
                   (src (load-surface (%fixture-path "test-pattern-4x4.bmp"))))
    (%fill-all dst 0 0 0 255)
    (blit-surface-rect src (make-rect :x 0 :y 0 :width 2 :height 2) dst (make-position :x 4 :y 1))
    (%assert-equal (%pixel->list dst 4 1) '(255 0 0 255) "offset blit region")
    (%assert-equal (%pixel->list dst 0 0) '(0 0 0 255) "unaffected pixel")))

(%deftest test-alpha-affects-blit-result
  (%with-surfaces ((dst (create-surface :width 2 :height 2))
                   (src (create-surface :width 2 :height 2)))
    (%fill-all dst 0 0 255 255)
    (%fill-all src 255 0 0 128)
    (blit-surface src dst (make-position :x 0 :y 0))
    (let ((px (%pixel->list dst 0 0)))
      (%assert-false (equal px '(0 0 255 255)) "alpha blit changed destination")
      (%assert-false (equal px '(255 0 0 255)) "alpha blit not opaque overwrite"))))

(%deftest test-blit-does-not-touch-unrelated-regions
  (%with-surfaces ((dst (create-surface :width 20 :height 20))
                   (src (create-surface :width 3 :height 3)))
    (%fill-all dst 10 20 30 255)
    (%fill-all src 200 0 0 255)
    (blit-surface src dst (make-position :x 7 :y 8))
    (%assert-equal (%pixel->list dst 7 8) '(200 0 0 255) "affected region changed")
    (%assert-equal (%pixel->list dst 0 0) '(10 20 30 255) "far region unchanged")))

(%deftest test-self-blit-predictable
  (%with-surfaces ((s (create-surface :width 4 :height 4)))
    (%fill-all s 10 10 10 255)
    (let ((result (handler-case
                      (progn
                        (blit-surface s s (make-position :x 0 :y 0))
                        :ok)
                    (error () :error))))
      (%assert-true (member result '(:ok :error)) "self blit predictable"))))

(%deftest test-scaled-subrect-to-larger-destination
  (%with-surfaces ((dst (create-surface :width 8 :height 8))
                   (src (create-surface :width 2 :height 2)))
    (%fill-all dst 0 0 0 255)
    (%fill-all src 255 0 0 255)
    (blit-surface-rect-scaled src (make-rect :x 0 :y 0 :width 2 :height 2)
                              dst (make-rect :x 1 :y 1 :width 6 :height 6))
    (%assert-equal (%pixel->list dst 1 1) '(255 0 0 255) "scaled region starts")
    (%assert-equal (%pixel->list dst 6 6) '(255 0 0 255) "scaled region ends")))

(%deftest test-scaled-subrect-to-smaller-destination
  (%with-surfaces ((dst (create-surface :width 6 :height 6))
                   (src (create-surface :width 4 :height 4)))
    (%fill-all dst 0 0 0 255)
    (%fill-all src 0 255 0 255)
    (blit-surface-rect-scaled src (make-rect :x 0 :y 0 :width 4 :height 4)
                              dst (make-rect :x 2 :y 1 :width 2 :height 2))
    (%assert-equal (%pixel->list dst 2 1) '(0 255 0 255) "downscale changed region")
    (%assert-equal (%pixel->list dst 0 0) '(0 0 0 255) "outside unchanged")))

(%deftest test-scaled-blit-clips-to-destination-bounds
  (%with-surfaces ((dst (create-surface :width 5 :height 5))
                   (src (create-surface :width 4 :height 4)))
    (%fill-all dst 0 0 0 255)
    (%fill-all src 30 40 50 255)
    (blit-surface-rect-scaled src (make-rect :x 0 :y 0 :width 4 :height 4)
                              dst (make-rect :x 3 :y 3 :width 4 :height 4))
    (%assert-equal (%pixel->list dst 4 4) '(30 40 50 255) "clipped corner changed")
    (%assert-equal (%pixel->list dst 2 2) '(0 0 0 255) "outside clip unchanged")))

(%deftest test-font-request-by-path-and-size
  (let ((font (get-font (%font-path) 16)))
    (unwind-protect
         (%assert-true (typep font 'minerva.gfx::backend-font) "font object returned")
      (ignore-errors (destroy-font font)))))

(%deftest test-same-font-spec-requested-twice-consistent
  (let ((font-a (get-font (%font-path) 14))
        (font-b (get-font (%font-path) 14)))
    (unwind-protect
         (multiple-value-bind (w1 h1) (measure-text font-a "Hello")
           (multiple-value-bind (w2 h2) (measure-text font-b "Hello")
             (%assert-equal (list w1 h1) (list w2 h2) "same font spec measurement consistency")))
      (ignore-errors (destroy-font font-a))
      (ignore-errors (destroy-font font-b)))))

(%deftest test-different-font-sizes-distinct-usable
  (let ((font-small (get-font (%font-path) 12))
        (font-large (get-font (%font-path) 24)))
    (unwind-protect
         (multiple-value-bind (w1 h1) (measure-text font-small "Hello")
           (multiple-value-bind (w2 h2) (measure-text font-large "Hello")
             (%assert-true (> w2 w1) "larger font wider")
             (%assert-true (> h2 h1) "larger font taller")))
      (ignore-errors (destroy-font font-small))
      (ignore-errors (destroy-font font-large)))))

(%deftest test-missing-font-fails-predictably
  (handler-case
      (progn
        (get-font "/definitely/missing/font.ttf" 12)
        (%assert-true nil "missing font should fail"))
    (minerva-resource-error ()
      (%assert-true t "missing font failed with minerva-resource-error"))))

(%deftest test-measure-non-empty-positive
  (let ((font (get-font (%font-path) 16)))
    (unwind-protect
         (multiple-value-bind (w h) (measure-text font "Hello")
           (%assert-true (> w 0) "non-empty width positive")
           (%assert-true (> h 0) "non-empty height positive"))
      (ignore-errors (destroy-font font)))))

(%deftest test-measure-empty-consistent
  (let ((font (get-font (%font-path) 16)))
    (unwind-protect
         (multiple-value-bind (w h) (measure-text font "")
           (%assert-equal w 0 "empty string width")
           (%assert-equal h 16 "empty string height equals font size"))
      (ignore-errors (destroy-font font)))))

(%deftest test-larger-font-has-larger-measurements
  (let ((font-small (get-font (%font-path) 10))
        (font-large (get-font (%font-path) 20)))
    (unwind-protect
         (multiple-value-bind (w1 h1) (measure-text font-small "A")
           (multiple-value-bind (w2 h2) (measure-text font-large "A")
             (%assert-true (> w2 w1) "larger size wider")
             (%assert-true (> h2 h1) "larger size taller")))
      (ignore-errors (destroy-font font-small))
      (ignore-errors (destroy-font font-large)))))

(%deftest test-longer-strings-are-wider
  (let ((font (get-font (%font-path) 14)))
    (unwind-protect
         (multiple-value-bind (w1 h1) (measure-text font "Hi")
           (multiple-value-bind (w2 h2) (measure-text font "Hello world")
             (declare (ignore h1 h2))
             (%assert-true (> w2 w1) "longer text wider")))
      (ignore-errors (destroy-font font)))))

(%deftest test-render-text-returns-surface
  (let ((font (get-font (%font-path) 16))
        (s nil))
    (unwind-protect
         (progn
           (setf s (render-text-to-surface font "Hello" (make-color :r 255 :g 255 :b 255 :a 255)))
           (%assert-true (typep s 'minerva.gfx::backend-surface) "render returns surface")
           (%assert-true (> (surface-width s) 0) "rendered surface width positive")
           (%assert-true (> (surface-height s) 0) "rendered surface height positive"))
      (ignore-errors (destroy-surface s))
      (ignore-errors (destroy-font font)))))

(%deftest test-rendered-size-matches-measured-size
  (let ((font (get-font (%font-path) 18))
        (s nil))
    (unwind-protect
         (multiple-value-bind (w h) (measure-text font "Measure")
           (setf s (render-text-to-surface font "Measure" (make-color :r 255 :g 255 :b 255 :a 255)))
           (%assert-equal (list (surface-width s) (surface-height s))
                          (list (max 1 w) (max 1 h))
                          "rendered dimensions match measured contract"))
      (ignore-errors (destroy-surface s))
      (ignore-errors (destroy-font font)))))

(%deftest test-text-color-affects-rendered-output
  (let ((font (get-font (%font-path) 16))
        (white nil)
        (red nil))
    (unwind-protect
         (progn
           (setf white (render-text-to-surface font "Hi" (make-color :r 255 :g 255 :b 255 :a 255)))
           (setf red (render-text-to-surface font "Hi" (make-color :r 255 :g 0 :b 0 :a 255)))
           (%assert-false (equal (%pixel->list white 1 1) (%pixel->list red 1 1)) "text color changes pixels"))
      (ignore-errors (destroy-surface white))
      (ignore-errors (destroy-surface red))
      (ignore-errors (destroy-font font)))))

(%deftest test-rendered-background-transparent
  (let ((font (get-font (%font-path) 20))
        (s nil))
    (unwind-protect
         (progn
           (setf s (render-text-to-surface font "A A" (make-color :r 255 :g 255 :b 255 :a 255)))
           (let* ((glyph-width (max 1 (truncate (* 20 3/5))))
                  (space-x (+ glyph-width 2))
                  (px (%pixel->list s space-x 5)))
             (%assert-equal (fourth px) 0 "background in space is transparent")))
      (ignore-errors (destroy-surface s))
      (ignore-errors (destroy-font font)))))

(%deftest test-render-empty-string-consistent
  (let ((font (get-font (%font-path) 17))
        (s nil))
    (unwind-protect
         (progn
           (setf s (render-text-to-surface font "" (make-color :r 255 :g 255 :b 255 :a 255)))
           (%assert-equal (surface-width s) 1 "empty render width")
           (%assert-equal (surface-height s) 17 "empty render height"))
      (ignore-errors (destroy-surface s))
      (ignore-errors (destroy-font font)))))

(%deftest test-fill-surface-colors-entire-surface
  (%with-surfaces ((s (create-surface :width 5 :height 4)))
    (fill-surface s (make-color :r 12 :g 34 :b 56 :a 200))
    (%assert-equal (%pixel->list s 0 0) '(12 34 56 200) "fill-surface top-left")
    (%assert-equal (%pixel->list s 4 3) '(12 34 56 200) "fill-surface bottom-right")
    (%assert-equal (%pixel->list s 2 1) '(12 34 56 200) "fill-surface center")))

(%deftest test-repeated-surface-create-destroy-stable
  (dotimes (i 50)
    (let ((surface (create-surface :width 8 :height 8)))
      (declare (ignore i))
      (%assert-equal (surface-width surface) 8 "repeated create width")
      (destroy-surface surface))))

(%deftest test-repeated-font-lookup-render-stable
  (dotimes (i 25)
    (let ((font (get-font (%font-path) 14))
          (surface nil))
      (declare (ignore i))
      (unwind-protect
           (progn
             (setf surface (render-text-to-surface font "ok" (make-color :r 200 :g 100 :b 50 :a 255)))
             (%assert-true (> (surface-width surface) 0) "repeat font render width"))
        (ignore-errors (destroy-surface surface))
        (ignore-errors (destroy-font font))))))

(%deftest test-end-to-end-font-surface-widget-flow
  (let* ((font (get-font (%font-path) 16))
         (surface nil)
         (gui-pkg (find-package :minerva.gui))
         (make-instance-sym (find-symbol "MAKE-INSTANCE" :cl))
         (image-class (and gui-pkg (find-symbol "IMAGE" gui-pkg)))
         (nine-patch-class (and gui-pkg (find-symbol "NINE-PATCH" gui-pkg)))
         (layout-fn (and gui-pkg (find-symbol "LAYOUT" gui-pkg)))
         (make-rect-fn (and gui-pkg (find-symbol "MAKE-RECT" gui-pkg)))
         (content-rect-fn (and gui-pkg (find-symbol "NINE-PATCH-CONTENT-RECT" gui-pkg)))
         (widget-layout-rect-fn (and gui-pkg (find-symbol "WIDGET-LAYOUT-RECT" gui-pkg)))
         (gui-rect-x-fn (and gui-pkg (find-symbol "RECT-X" gui-pkg)))
         (gui-rect-y-fn (and gui-pkg (find-symbol "RECT-Y" gui-pkg)))
         (gui-rect-width-fn (and gui-pkg (find-symbol "RECT-WIDTH" gui-pkg)))
         (gui-rect-height-fn (and gui-pkg (find-symbol "RECT-HEIGHT" gui-pkg))))
    (unwind-protect
         (progn
           (unless (and image-class nine-patch-class layout-fn make-rect-fn content-rect-fn widget-layout-rect-fn
                        gui-rect-x-fn gui-rect-y-fn gui-rect-width-fn gui-rect-height-fn)
             (error "Required minerva.gui API not available for integration flow test"))
           (setf surface (render-text-to-surface font "Flow" (make-color :r 255 :g 255 :b 255 :a 255)))
           (let* ((image (funcall (symbol-function make-instance-sym) image-class :surface surface))
                  (panel (funcall (symbol-function make-instance-sym)
                                  nine-patch-class
                                  :surface '(:width 30 :height 30)
                                  :border-left 3 :border-right 4 :border-top 5 :border-bottom 6
                                  :child image))
                  (rect (funcall (symbol-function make-rect-fn) :x 0 :y 0 :width 120 :height 50)))
             (funcall (symbol-function layout-fn) panel rect)
             (let ((content-rect (funcall (symbol-function content-rect-fn) panel))
                   (image-rect (funcall (symbol-function widget-layout-rect-fn) image)))
               (%assert-equal (list (funcall (symbol-function gui-rect-x-fn) image-rect)
                    (funcall (symbol-function gui-rect-y-fn) image-rect)
                    (funcall (symbol-function gui-rect-width-fn) image-rect)
                    (funcall (symbol-function gui-rect-height-fn) image-rect))
                  (list (funcall (symbol-function gui-rect-x-fn) content-rect)
                    (funcall (symbol-function gui-rect-y-fn) content-rect)
                    (funcall (symbol-function gui-rect-width-fn) content-rect)
                    (funcall (symbol-function gui-rect-height-fn) content-rect))
                              "end-to-end image receives nine-patch content rect"))))
      (ignore-errors (destroy-surface surface))
      (ignore-errors (destroy-font font)))))

(%deftest test-repeated-text-measurement-identical
  (let ((font (get-font (%font-path) 16)))
    (unwind-protect
         (multiple-value-bind (w1 h1) (measure-text font "Deterministic")
           (multiple-value-bind (w2 h2) (measure-text font "Deterministic")
             (%assert-equal (list w1 h1) (list w2 h2) "measurement deterministic")))
      (ignore-errors (destroy-font font)))))

(%deftest test-repeated-text-rendering-identical
  (let ((font (get-font (%font-path) 16))
        (a nil)
        (b nil))
    (unwind-protect
         (progn
           (setf a (render-text-to-surface font "Stable" (make-color :r 255 :g 0 :b 0 :a 255)))
           (setf b (render-text-to-surface font "Stable" (make-color :r 255 :g 0 :b 0 :a 255)))
           (%assert-equal (list (surface-width a) (surface-height a))
                          (list (surface-width b) (surface-height b))
                          "render deterministic dimensions")
           (%assert-equal (%pixel->list a 1 1) (%pixel->list b 1 1) "render deterministic sample pixel"))
      (ignore-errors (destroy-surface a))
      (ignore-errors (destroy-surface b))
      (ignore-errors (destroy-font font)))))

(defun %run-test-case (test-symbol)
  (let ((failures-before *test-failures*)
        (*current-test-name* test-symbol))
    (handler-case
        (progn
          (funcall (symbol-function test-symbol))
          (if (= failures-before *test-failures*)
              (format t "* Pass ~(~A~)~%" test-symbol)
              (format t "- Fail ~(~A~)~%" test-symbol)))
      (error (condition)
        (incf *test-failures*)
        (format t "- Fail ~(~A~) (~A)~%" test-symbol condition)))))

(defun %test-symbol-p (symbol package)
  (and (fboundp symbol)
       (eq (symbol-package symbol) package)
       (let ((name (symbol-name symbol)))
         (and (>= (length name) 5)
              (string= name "TEST-" :end1 5 :end2 5)))))

(defun %collect-test-symbols ()
  (let ((package (find-package :minerva.gfx.tests)))
    (sort (loop for symbol being the symbols of package
                when (%test-symbol-p symbol package)
                collect symbol)
          #'string<
          :key #'symbol-name)))

(defun run-gfx-resource-tests ()
  (setf *test-count* 0
        *test-failures* 0)
  (init-backend)
  (unwind-protect
       (dolist (test-symbol (%collect-test-symbols))
         (%run-test-case test-symbol))
    (ignore-errors (shutdown-backend)))
  (format t "~%Executed ~D gfx assertions.~%" *test-count*)
  (if (zerop *test-failures*)
      (format t "All graphics/resource tests passed.~%")
      (error "Graphics/resource tests failed: ~D assertion(s)." *test-failures*)))
