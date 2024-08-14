(in-package :minerva/tests)

(def-suite container-tests
  :description "Test all container widgets")

(def-suite* test-box :in container-tests)

(test widget-creation
      (is (make-instance 'minerva/containers:Box)))
