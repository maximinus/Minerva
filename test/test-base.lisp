(defpackage :minerva-tests
  (:use :cl
	:minerva
        :fiveam))

(in-package :minerva-tests)

(def-suite base-tests
  :description "Tests expand symbols")

(def-suite* test-running :in base-tests)

(test text-example
      (is (equal (minerva:test-example) "Chris")))
