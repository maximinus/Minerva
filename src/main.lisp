(in-package :minerva)

(defclass MinervaApp ()
  ;; the base Minerva class, the start of it all
  ((display :initarg :display :accessor display)
   (frames :initarg :frames :accessor frames))
  (:default-initargs :display nil :frames nil))

(defun start-minerva (new-frames)
  (let ((app (make-instance 'MinervaApp :frames new-frames))
    (render-all app))))

(defmethod render-all ((self MinervaApp))
  (loop for frame in (frames self) do
    (render-frame frame)))

