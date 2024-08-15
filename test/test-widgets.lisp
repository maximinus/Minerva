(in-package :minerva/tests)

(def-suite test-widgets
  :description "Test the ColorRect")


(def-suite* test-colorrect :in test-widgets)

(test size-matches
  (let ((foo (make-instance 'minerva:ColorRect :size (minerva::make-size 10 20))))
    (is (and (equal (minerva::width (minerva::min-size foo)) 10)
	     (equal (minerva::height (minerva::min-size foo)) 20)))))

(test test-no-background-default
  (let ((foo (make-instance 'minerva:ColorRect :size (minerva::make-size 10 10) :color '(0 0 0 0))))
    (is (equal (minerva::background foo) nil))))
