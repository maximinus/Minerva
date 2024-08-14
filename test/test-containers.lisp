(in-package :minerva/tests)

(def-suite container-tests
  :description "Test all container widgets")

(def-suite* test-widget :in container-tests)

(test widget-creation
      (is (make-instance Widget)))
