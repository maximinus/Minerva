# Minerva v0.1


Minerva is an open source IDE for Common Lisp. The goals of the project are:

* The IDE should contain all you need to create, build and debug Lisp programs
* The interface should be graphical and adhere to modern standards
* It should be cross-platform and easily installed
* It should require nothing more than a Lisp executable to be installed

Currently, the most common recommended method for Lisp involves manually setting up Emacs, Slime and Quicklisp, after which a new user then has to learn Emacs before they can being to use Lisp.

In this writer's view, this is a serious impediment for people trying to learn Lisp. Minerva is designed from the ground up to be a lot simpler; exactly the type of IDE that all developers have likely worked with in the past.

This is not to say that the Minerva method is superior in any particular way; it is just built to be different from the Emacs style approach.


## Current Tech Stack


All versions up to 1.0 will use Python and GTK 3.

Version 2.0 will itself be written with Minerva and use Lisp and GTK 3.

The reason for this is that the first version is being used as a testbed by the developer to document and test the the GTK and Swank parts.

