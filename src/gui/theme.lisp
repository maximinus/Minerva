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
    :scrollbar-background-color
    :scrollbar-button-size
    :scrollbar-scroll-step
    :scrollbar-min-thumb-size
    :default-menu-background-highlight
    :button-nine-patch-normal
    :button-nine-patch-highlight
    :button-nine-patch-pressed
    :menubar-nine-patch
    :menubar-nine-patch-border-size
    :menubar-nine-patch-border-left
    :menubar-nine-patch-border-right
    :menubar-nine-patch-border-top
    :menubar-nine-patch-border-bottom
    :menubar-button-bg-normal
    :menubar-button-bg-hovered
    :menubar-button-bg-pressed
    :menubar-button-text-normal
    :menubar-button-text-pressed
    :menubar-menu-overlay-offset-y
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
(defvar scrollbar-background-color (make-color :r 180 :g 180 :b 180 :a 255))
(defvar scrollbar-button-size 20)
(defvar scrollbar-scroll-step 20)
(defvar scrollbar-min-thumb-size 20)
(defvar default-menu-background-highlight (make-color :r 200 :g 200 :b 200 :a 255))

(defvar button-nine-patch-normal "/assets/button/button_normal.png")
(defvar button-nine-patch-highlight "/assets/button/button_highlight.png")
(defvar button-nine-patch-pressed "/assets/button/button_pressed.png")

(defvar menubar-nine-patch "/assets/menu/menu.png")
(defvar menubar-nine-patch-border-size 4)
(defvar menubar-nine-patch-border-left menubar-nine-patch-border-size)
(defvar menubar-nine-patch-border-right menubar-nine-patch-border-size)
(defvar menubar-nine-patch-border-top menubar-nine-patch-border-size)
(defvar menubar-nine-patch-border-bottom menubar-nine-patch-border-size)

(defvar menubar-button-bg-normal (make-color :r 0 :g 0 :b 0 :a 0))
(defvar menubar-button-bg-hovered (make-color :r 200 :g 200 :b 200 :a 255))
(defvar menubar-button-bg-pressed (make-color :r 120 :g 120 :b 120 :a 255))
(defvar menubar-button-text-normal default-font-color)
(defvar menubar-button-text-pressed (make-color :r 255 :g 255 :b 255 :a 255))
(defvar menubar-menu-overlay-offset-y 2)

(defvar menu-nine-patch "/assets/menu/menu.png")
(defvar menu-nine-patch-border-size 4)
(defvar menu-nine-patch-border-left menu-nine-patch-border-size)
(defvar menu-nine-patch-border-right menu-nine-patch-border-size)
(defvar menu-nine-patch-border-top menu-nine-patch-border-size)
(defvar menu-nine-patch-border-bottom menu-nine-patch-border-size)
