(in-package :minerva/tests)

(def-suite base-tests
  :description "Test base helper classes")

(def-suite* test-expand :in base-tests)


(test expand-none-not-horizontal
      (is (not (minerva:horizontal-expandp 'minerva:expand-none))))

(test expand-vertical-not-horizontal
      (is (not (minerva:horizontal-expandp 'minerva:expand-vertical))))

(test expand-horizontal-horizontal
      (is (minerva:horizontal-expandp 'minerva:expand-horizontal)))

(test expand-both-horizontal
      (is (minerva:horizontal-expandp 'minerva:expand-both)))

(test expand-none-not-vertical
      (is (not (minerva:vertical-expandp 'minerva:expand-none))))

(test expand-horizontal-not-vertical
      (is (not (minerva:vertical-expandp 'minerva:expand-horizontal))))

(test expand-vertical-vertical
      (is (minerva:vertical-expandp 'minerva:expand-vertical)))

(test expand-both-vertical
      (is (minerva:vertical-expandp 'minerva:expand-both)))
