(in-package :minerva.gui)

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

(defun %assert-rect (widget x y width height label)
  (let ((rect (widget-layout-rect widget)))
    (%assert-equal
     (list (rect-x rect) (rect-y rect) (rect-width rect) (rect-height rect))
     (list x y width height)
     label)))

(defun %assert-min-size (widget min-width min-height label)
  (let ((request (measure widget)))
    (%assert-equal (size-request-min-width request) min-width (concatenate 'string label " min-width"))
    (%assert-equal (size-request-min-height request) min-height (concatenate 'string label " min-height"))))

(defun %assert-expand-flags (widget expand-x expand-y label)
  (let ((request (measure widget)))
    (%assert-equal (size-request-expand-x request) expand-x (concatenate 'string label " expand-x"))
    (%assert-equal (size-request-expand-y request) expand-y (concatenate 'string label " expand-y"))))

(defun %all-non-negative-rect-p (&rest widgets)
  (every (lambda (widget)
           (let ((rect (widget-layout-rect widget)))
             (and (>= (rect-x rect) 0)
                  (>= (rect-y rect) 0)
                  (>= (rect-width rect) 0)
                  (>= (rect-height rect) 0))))
         widgets))

(defun %rect-list (widget)
  (let ((r (widget-layout-rect widget)))
    (list (rect-x r) (rect-y r) (rect-width r) (rect-height r))))

(defun %rect-value-list (r)
  (list (rect-x r) (rect-y r) (rect-width r) (rect-height r)))

(defun %project-root ()
  (or (ignore-errors (asdf:system-source-directory "minerva"))
      (truename "./")))

(defun %font-path ()
  (namestring (merge-pathnames "minerva/assets/fonts/inconsolata.ttf" (%project-root))))

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
  (let ((package (find-package :minerva.gui)))
    (sort (loop for symbol being the symbols of package
                when (%test-symbol-p symbol package)
                collect symbol)
          #'string<
          :key #'symbol-name)))
