(in-package :minerva/tests)

(def-suite container-tests
  :description "Test all container widgets")

(def-suite* test-box :in container-tests)

(test widget-creation
      (is (make-instance 'minerva:Box)))

(test empty-box-no-size
  (let* ((foo (make-instance 'minerva:Box))
	 (widget-size (minerva::min-size foo)))
    (is (and (equal (minerva::width widget-size) 0)
	     (equal (minerva::height widget-size) 0)))))

(test not-empty-size
  (let* ((crect (make-instance 'minerva:ColorRect :size (make-instance 'minerva:Size :width 50 :height 80)))
	 (foo (make-instance 'minerva:Box :widgets '(crect)))
	 (widget-size (minerva::min-size foo)))
    (is (and (equal (minerva::width widget-size) 50)
	     (equal (minerva::height widget-size) 80)))))
