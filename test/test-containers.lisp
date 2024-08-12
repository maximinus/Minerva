(defpackage :minerva-tests
  (:use :cl
	:minerva
        :fiveam))

(in-package :minerva-tests)


(def-suite container-tests
  :description "Tests expand symbols")

(def-suite* test-expand :in container-tests)

(test test-example
      (is (minerva:test-example)))

(test expand-none-not-horizontal
      (is (not (expand-horizontal 'expand-none))))

(test expand-vertical-not-horizontal
      (is (not (expand-horizontal 'expand-vertical))))

(test expand-horizontal-horizontal
      (is (expand-horizontal 'expand-horizontal)))

(test expand-both-horizontal
      (is (expand-horizonatal 'expand-both)))

(test expand-none-not-vertical
      (is (not (expand-horizontal 'expand-none))))

(test expand-horizontal-not-vertical
      (is (not (expand-vertical 'expand-horizontal))))

(test expand-vertical-vertical
      (is (expand-vertical 'expand-vertical)))

(test expand-both-vertical
      (is (expand-vertical 'expand-both)))
