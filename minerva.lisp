;;;; minerva.lisp

(asdf:load-asd #P"/home/sparky/data/code/Minerva/minerva.asd")
(ql:quickload "minerva")
(ql:quickload "minerva/tests")

;; now you can run a test with this syntax
;; (fiveam:run! 'minerva/tests::base-tests)

