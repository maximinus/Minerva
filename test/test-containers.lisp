(defpackage :minerva-tests
  (:import-from :minerva/containers :horizontal-expandp :vertical-expandp)
  (:use :fiveam))

(in-package :minerva-tests)

(def-suite container-tests
  :description "Tests expand symbols")

(def-suite* test-expand :in container-tests)

(test expand-none-not-horizontal
      (is (not (horizontal-expandp :expand-none))))

(test expand-vertical-not-horizontal
      (is (not (horizontal-expandp :expand-vertical))))

(test expand-horizontal-horizontal
      (is (horizontal-expandp :expand-horizontal)))

(test expand-both-horizontal
      (is (horizontal-expandp :expand-both)))

(test expand-none-not-vertical
      (is (not (vertical-expandp :expand-none))))

(test expand-horizontal-not-vertical
      (is (not (vertical-expandp :expand-horizontal))))

(test expand-vertical-vertical
      (is (vertical-expandp :expand-vertical)))

(test expand-both-vertical
      (is (vertical-expandp :expand-both)))
