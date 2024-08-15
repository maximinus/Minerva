(in-package :minerva/tests)

(def-suite test-containers
  :description "Test all container widgets")

(def-suite* test-box :in test-containers)

(test widget-creation
      (is (make-instance 'minerva:Box)))

(test empty-box-no-size
  (let* ((foo (make-instance 'minerva:Box))
	 (widget-size (minerva::min-size foo)))
    (is (and (equal (minerva::width widget-size) 0)
	     (equal (minerva::height widget-size) 0)))))

(test not-empty-size
  (let* ((crect (make-instance 'minerva:ColorRect :size (minerva::make-size 50 80)))
	 (foo (make-instance 'minerva:Box :widgets (list crect)))
	 (widget-size (minerva::min-size foo)))
    (is (and (equal (minerva::width widget-size) 50)
	     (equal (minerva::height widget-size) 80)))))


(def-suite* test-hbox-vbox :in test-containers)

(test empty-hbox-no-size
  (let* ((foo (make-instance 'minerva:HBox))
	 (widget-size (minerva::min-size foo)))
    (is (and (equal (minerva::width widget-size) 0)
	     (equal (minerva::height widget-size) 0)))))

(test size-with-color-rect
  (let* ((crect (make-instance 'minerva:ColorRect :size (minerva::make-size 20 30)))
	 (foo (make-instance 'minerva:HBox :widgets (list crect)))
	 (widget-size (minerva::min-size foo)))
    (is (and (equal (minerva::width widget-size) 20)
	     (equal (minerva::height widget-size) 30)))))

(test size-with-two-colorrects
  (let* ((crect1 (make-instance 'minerva:ColorRect :size (minerva::make-size 20 30)))
	 (crect2 (make-instance 'minerva:ColorRect :size (minerva::make-size 30 40)))
	 (foo (make-instance 'minerva:HBox :widgets (list crect1 crect2)))
	 (widget-size (minerva::min-size foo)))
    (is (and (equal (minerva::width widget-size) 50)
	     (equal (minerva::height widget-size) 40)))))
