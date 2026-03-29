(defpackage :minerva.conditions
  (:nicknames :minerva-cond)
  (:use :cl)
  (:export
   :minerva-error
   :minerva-ffi-error
   :minerva-resource-error
   :minerva-layout-error
   :minerva-widget-error
   :minerva-test-error
   :minerva-error-phase
   :minerva-error-message
   :minerva-error-operation
   :minerva-error-native-error
   :minerva-error-details))

(in-package :minerva.conditions)

(define-condition minerva-error (error)
  ((phase :initarg :phase :reader minerva-error-phase :initform :unknown)
   (message :initarg :message :reader minerva-error-message :initform "Minerva error")
   (operation :initarg :operation :reader minerva-error-operation :initform nil)
   (native-error :initarg :native-error :reader minerva-error-native-error :initform nil)
   (details :initarg :details :reader minerva-error-details :initform nil))
  (:report
   (lambda (condition stream)
     (format stream "~A" (minerva-error-message condition))
     (when (minerva-error-operation condition)
       (format stream " [operation=~A]" (minerva-error-operation condition)))
     (when (minerva-error-native-error condition)
       (format stream " [native=~A]" (minerva-error-native-error condition)))
     (when (minerva-error-details condition)
       (format stream " [details=~A]" (minerva-error-details condition))))))

(define-condition minerva-ffi-error (minerva-error) ())
(define-condition minerva-resource-error (minerva-error) ())
(define-condition minerva-layout-error (minerva-error) ())
(define-condition minerva-widget-error (minerva-error) ())
(define-condition minerva-test-error (minerva-error) ())
