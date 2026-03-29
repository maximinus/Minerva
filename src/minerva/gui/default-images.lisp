(in-package :minerva.gui)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (boundp 'menu-nine-patch)
    (defconstant menu-nine-patch "/assets/menu/menu.png")
    (defconstant menu-nine-patch-border-size 4)
    (defconstant menu-nine-patch-border-left menu-nine-patch-border-size)
    (defconstant menu-nine-patch-border-right menu-nine-patch-border-size)
    (defconstant menu-nine-patch-border-top menu-nine-patch-border-size)
    (defconstant menu-nine-patch-border-bottom menu-nine-patch-border-size)
    (defconstant default-image-paths
      '((:menu-nine-patch . "/assets/menu/menu.png")))))
