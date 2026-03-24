(require :asdf)
(setf *compile-verbose* nil
      *compile-print* nil
      *load-verbose* nil
      asdf:*asdf-verbose* nil)

(asdf:load-asd
 (merge-pathnames #P"minerva.asd"
                  (truename (merge-pathnames "../"
                                             (make-pathname :name nil :type nil :defaults *load-truename*)))))

(asdf:test-system "minerva/tests")
