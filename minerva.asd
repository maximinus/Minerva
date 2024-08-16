;;;; minerva.asd - define all systems here

(asdf:defsystem "minerva"
  :description "Minerva: The modern Lisp IDE"
  :author "Chris Handy <maximinus@gmail.com>"
  :license "GPL 3.0"
  :version "0.0.1"
  :serial t
  :depends-on (:sdl2 :sdl2-ttf :sdl2-image)
  :pathname "src/"
  :components ((:file "package")
	       (:file "base")
	       (:file "widgets")
	       (:file "containers")))

(asdf:defsystem :minerva/tests
  :description "Tests for Minerva IDE"
  :author "Chris Handy <maximinus@gmail.com>"
  :license "GPL 3.0"
  :serial t
  :depends-on (:fiveam :minerva)
  :pathname "test/"
  :components ((:file "package")
	       (:file "test-base")
	       (:file "test-widgets")
	       (:file "test-containers")))

