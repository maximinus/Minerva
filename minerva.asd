;;;; Minerva.asd

(asdf:defsystem :minerva
  :description "Minerva: The modern Lisp IDE"
  :author "Chris Handy <maximinus@gmail.com>"
  :license  "GPL 3.0"
  :version "0.0.1"
  :serial t
  :depends-on ("SLD2" "SDL2-TTF" "SLD2-IMAGE")
  :pathname "src/"
  :components ((:file "base")
               (:file "containers")))

(asdf:defsystem :minerva/tests
  :description "Tests for Minerva IDS"
  :author "Chris Handy"
  :license "GPL 3.0"
  :serial t
  :depends-on (:fiveam :minerva)
  :pathname "tests/"
  :components ((:file "test-containers")))

