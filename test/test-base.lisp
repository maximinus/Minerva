(in-package :minerva/tests)

(def-suite base-tests
  :description "Test base helper classes")

(def-suite* test-expand :in base-tests)


(test expand-none-not-horizontal
      (is (not (minerva:horizontal-expandp 'minerva:expand-none))))

(test expand-vertical-not-horizontal
      (is (not (minerva:horizontal-expandp 'minerva:expand-vertical))))

(test expand-horizontal-horizontal
      (is (minerva:horizontal-expandp 'minerva:expand-horizontal)))

(test expand-both-horizontal
      (is (minerva:horizontal-expandp 'minerva:expand-both)))

(test expand-none-not-vertical
      (is (not (minerva:vertical-expandp 'minerva:expand-none))))

(test expand-horizontal-not-vertical
      (is (not (minerva:vertical-expandp 'minerva:expand-horizontal))))

(test expand-vertical-vertical
      (is (minerva:vertical-expandp 'minerva:expand-vertical)))

(test expand-both-vertical
      (is (minerva:vertical-expandp 'minerva:expand-both)))


(def-suite* test-size :in base-tests)

(test size-constructor
  (is (minerva::make-size 10 10)))

(test size-init-zero
  (let ((w (make-instance 'minerva:Size)))
    (is (and (equal (minerva::width w) 0)
	     (equal (minerva::height w) 0)))))

(test size-can-set
  (let ((w (make-instance 'minerva:Size)))
    (setf (minerva::width w) 100)
    (setf (minerva::height w) 150)
    (is (and (equal (minerva::width w) 100)
	     (equal (minerva::height w) 150)))))

(test size-initset
  (let ((w (make-instance 'minerva:Size :width 100 :height 150)))
    (is (and (equal (minerva::width w) 100)
	     (equal (minerva::height w) 150)))))

(test size-equal
  (let ((foo (make-instance 'minerva:Size :width 50))
	(bar (make-instance 'minerva:Size :width 50)))
    (is (minerva:equal-size foo bar))))


(def-suite* test-position :in base-tests)

(test position-constructor
  (is (minerva::make-position 5 7)))

(test create-position
  (let ((w (make-instance 'minerva:Position)))
    (is (and (equal (minerva::x w) 0)
	     (equal (minerva::y w) 0)))))

(test update-position
  (let ((w (make-instance 'minerva:Position)))
    (setf (minerva::x w) 50)
    (is (equal (minerva::x w) 50))))

(test add-position
  (let* ((a (make-instance 'minerva:Position :x 10 :y 20))
	 (b (make-instance 'minerva:Position :x 12 :y 15))
	 (result (minerva::add a b)))
    (is (and (equal (minerva::x result) 22)
	     (equal (minerva::y result) 35)))))

(test sub-position
  (let* ((a (make-instance 'minerva:Position :x 20 :y 30))
	 (b (make-instance 'minerva:Position :x 10 :y 18))
	 (result (minerva::sub a b)))
    (is (and (equal (minerva::x result) 10)
	     (equal (minerva::y result) 12)))))


(def-suite* test-widget :in base-tests)

(test widget-defaults
  (let ((w (make-instance 'minerva:Widget)))
    (is (and (equal (minerva::background w) nil)
	     (equal (minerva::expand w) 'minerva:expand-none)
	     (equal (minerva::parent w) nil)
	     (equal (minerva::texture w) nil)
	     (equal (minerva::container w) nil)))))

(test default-no-parent
  (let ((w (make-instance 'minerva:Widget)))
    (is (equal (minerva::get-parent w) nil))))

(test default-align-size
  (let* ((w (make-instance 'minerva:Widget))
	 (offset (minerva::get-align-offset w
					   (make-instance 'minerva:Size :width 100 :height 100)
					   (make-instance 'minerva:Size :width 200 :height 200))))
    (is (and (equal (minerva::x offset) 0)
	     (equal (minerva::y offset) 0)))))
