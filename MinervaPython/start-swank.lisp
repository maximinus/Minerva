(ql:quickload :swank)
(in-package :swank)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (swank-require :swank-repl))
(swank:create-server :port 4005 :dont-close t)
