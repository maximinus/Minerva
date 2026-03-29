(defpackage :minerva.gui.theme
  (:nicknames :theme)
  (:use :cl)
  (:export
    :default-font
    :default-font-size
    :default-color
   :menu-nine-patch
   :menu-nine-patch-border-size
   :menu-nine-patch-border-left
   :menu-nine-patch-border-right
   :menu-nine-patch-border-top
   :menu-nine-patch-border-bottom
   :default-image-paths))

(in-package :minerva.gui.theme)

(defvar default-font "inconsolata")
(defvar default-font-size 14)
(defvar default-color '(0 0 0 255))

(defvar menu-nine-patch "/assets/menu/menu.png")
(defvar menu-nine-patch-border-size 4)
(defvar menu-nine-patch-border-left menu-nine-patch-border-size)
(defvar menu-nine-patch-border-right menu-nine-patch-border-size)
(defvar menu-nine-patch-border-top menu-nine-patch-border-size)
(defvar menu-nine-patch-border-bottom menu-nine-patch-border-size)
(defvar default-image-paths
  '((:menu-nine-patch . "/assets/menu/menu.png")))
