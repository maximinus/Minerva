(defpackage :minerva.gui.theme
  (:nicknames :theme)
  (:use :cl)
  (:import-from :minerva.common
                :make-color)
  (:export
    :default-font
    :default-font-size
    :default-font-color
    :window-background-color
    :default-menu-background-highlight
    :button-nine-patch-normal
    :button-nine-patch-highlight
    :button-nine-patch-pressed
   :menu-nine-patch
   :menu-nine-patch-border-size
   :menu-nine-patch-border-left
   :menu-nine-patch-border-right
   :menu-nine-patch-border-top
  :menu-nine-patch-border-bottom))

(in-package :minerva.gui.theme)

(defvar default-font "inconsolata")
(defvar default-font-size 14)
(defvar default-font-color (make-color :r 0 :g 0 :b 0 :a 255))
(defvar window-background-color (make-color :r 180 :g 180 :b 180 :a 255))
(defvar default-menu-background-highlight (make-color :r 200 :g 200 :b 200 :a 255))

(defvar button-nine-patch-normal "/assets/button/button_normal.png")
(defvar button-nine-patch-highlight "/assets/button/button_highlight.png")
(defvar button-nine-patch-pressed "/assets/button/button_pressed.png")

(defvar menu-nine-patch "/assets/menu/menu.png")
(defvar menu-nine-patch-border-size 4)
(defvar menu-nine-patch-border-left menu-nine-patch-border-size)
(defvar menu-nine-patch-border-right menu-nine-patch-border-size)
(defvar menu-nine-patch-border-top menu-nine-patch-border-size)
(defvar menu-nine-patch-border-bottom menu-nine-patch-border-size)
