
Minerva
=======

Minerva is a cross-platform IDE for development of Lisp programs.

It hopes to include:

* Syntax checking
* Auto-completion
* Test runners
* Built in REPL and debugger
* Code tree structure
* Run, compile and build code from the IDE


Current Status
--------------

Current version is v0.01 Alpha. This version has no downloadable binaries.


Linux Setup
-----------

* Install SBCL from your package manager
* Download quicklisp from https://beta.quicklisp.org/quicklisp.lisp
* Open a command prompt and cd to where the quicklisp file was downloaded
* Run "sbcl --load quicklisp.lisp"
* At the REPL, run (quicklisp-quickstart:install)
* Followed by (ql:add-to-init-file)
* Enter (exit) to leave the REPL

* Now grab the source code with "git clone https://github.com/maximinus/Minerva.git"
* Cd into the directory "cd Minerva"
* Run the hello test code with "sbcl --script hello.cl"


Windows Setup
-------------

* Download SBCL from http://www.sbcl.org/platform-table.html
* Install as per normal
* Download quicklisp from https://beta.quicklisp.org/quicklisp.lisp
* Open a command prompt and cd to where the quicklisp file was downloaded
* Run "sbcl --load quicklisp.lisp"
* At the REPL, run (quicklisp-quickstart:install)
* Followed by (ql:add-to-init-file)
* Enter (exit) to leave the REPL

* Now we need to setup the GTK libs
* Download Msys2 from https://www.msys2.org/ and install
* Run msys2 and enter "pacman -Sy"
* Run "pacman -S mingw-w64-x86_64-gtk3", "pacman -S mingw-w64-x86_64-python3-gobject"

* Now grab the source code with "git clone https://github.com/maximinus/Minerva.git"
* Cd into the directory "cd Minerva"
* Run the hello test code with "sbcl --script hello.cl"
