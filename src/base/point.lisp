(in-package :lem-base)

(defclass point ()
  ((buffer
    :reader point-buffer
    :type buffer)
   (linum
    :accessor point-linum
    :type fixnum)
   (line
    :accessor point-line
    :type line)
   (charpos
    :accessor point-charpos
    :type fixnum)
   (kind
    :reader point-kind
    :type (member :temporary :left-inserting :right-inserting)))
  (:documentation
   "`point` is an object that points to the position of the text in the buffer.
It has a `buffer` slot, a `line` number, and `charpos` is an offset from the beginning of the line, starting at zero.
`point` has a `kind` type. The position after inserting and deleting in the buffer depends on the value of `kind`:
- when `kind` is `temporary`, `point` is used for temporary reads.
 The overhead on creation and deletion is low, and there is no need to explicitly delete the point.
 If you edit the buffer before the position, the `point` cannot be used correctly any more.
- when `kind` is `:left-inserting` or `:right-inserting`, and if you insert content before the point, then the point position is adjusted by the length of your edit.
 If you insert content at the point position, with `:right-inserting` the original position is unchanged, and with `:left-inserting` the position is moved.
When using `:left-inserting` or `:right-inserting`, you must explicitly delete the point after use with `delete-point`. For this reason, you should use `with-point`.
"))

(setf (documentation 'point-buffer 'function)
      "Return the `buffer` pointed to by `point`.")

(setf (documentation 'point-kind 'function)
      "Return the type of `point` (`:temporary`, `:left-inserting` or `:right-inserting`).")

(defun current-point ()
  "Return the current`point`."
  (buffer-point (current-buffer)))

(defmethod print-object ((object point) stream)
  (print-unreadable-object (object stream :identity t :type t)
    (format stream "(~D, ~D) ~S"
            (point-linum object)
            (point-charpos object)
            (line-str (point-line object)))))

(defun pointp (x)
  "`x`が`point`ならT、それ以外ならNILを返します。"
  (typep x 'point))

(defun initialize-point-slot-values
    (point &key (buffer (alexandria:required-argument :buffer))
                (linum (alexandria:required-argument :linum))
                (line (alexandria:required-argument :line))
                (charpos (alexandria:required-argument :line))
                (kind (alexandria:required-argument :line)))
  (setf (slot-value point 'buffer) buffer
        (slot-value point 'linum) linum
        (slot-value point 'line) line
        (slot-value point 'charpos) charpos
        (slot-value point 'kind) kind)
  (values))

(defun initialize-point (point kind)
  (unless (eq :temporary kind)
    (push point (line-points (point-line point)))
    (push point (buffer-points (point-buffer point)))))

(defun make-point (buffer linum line charpos &key (kind :right-inserting))
  (check-type kind (member :temporary :left-inserting :right-inserting))
  (let ((point (make-instance 'point)))
    (initialize-point-slot-values point
                                  :buffer buffer
                                  :linum linum
                                  :line line
                                  :charpos charpos
                                  :kind kind)
    (initialize-point point kind)
    point))

(defmethod copy-point-using-class ((point point) from-point kind)
  (check-type kind (member :temporary :left-inserting :right-inserting))
  (initialize-point-slot-values point
                                :buffer (point-buffer from-point)
                                :linum (point-linum from-point)
                                :line (point-line from-point)
                                :charpos (point-charpos from-point)
                                :kind kind)
  (initialize-point point kind)
  point)

(defun copy-point (point &optional kind)
  "`point`のコピーを作って返します。
`kind`は`:temporary`、`:left-inserting`または `right-inserting`です。
省略された場合は`point`と同じ値です。"
  (copy-point-using-class (make-instance 'point)
                          point
                          (or kind (point-kind point))))

(defun delete-point (point)
  "`point`を削除します。
`point-kind`が:temporaryの場合はこの関数を使う必要はありません。"
  (unless (point-temporary-p point)
    (setf (line-points (point-line point))
          (delete point (line-points (point-line point))))
    (let ((buffer (point-buffer point)))
      (setf (buffer-points buffer)
            (delete point (buffer-points buffer))))
    (values)))

(defun alive-point-p (point)
  (alexandria:when-let (line (point-line point))
    (line-alive-p line)))

(defun point-change-line (point new-linum new-line)
  (unless (point-temporary-p point)
    (let ((old-line (point-line point)))
      (if (line-alive-p old-line)
          (do ((scan (line-points old-line) (cdr scan))
               (prev nil scan))
              ((eq (car scan) point)
               (if prev
                   (setf (cdr prev) (cdr scan))
                   (setf (line-points old-line) (cdr scan)))
               (setf (cdr scan) (line-points new-line)
                     (line-points new-line) scan))
            (assert (not (null scan))))
          (push point (line-points new-line)))))
  (setf (point-linum point) new-linum)
  (setf (point-line point) new-line))

(defun point-temporary-p (point)
  (eq (point-kind point) :temporary))

(defun %always-same-buffer (point more-points)
  (loop :with buffer1 := (point-buffer point)
        :for point2 :in more-points
        :for buffer2 := (point-buffer point2)
        :always (eq buffer1 buffer2)))

(defun %point= (point1 point2)
  (and (= (point-linum point1)
          (point-linum point2))
       (= (point-charpos point1)
          (point-charpos point2))))

(defun %point< (point1 point2)
  (or (< (point-linum point1) (point-linum point2))
      (and (= (point-linum point1) (point-linum point2))
           (< (point-charpos point1) (point-charpos point2)))))

(defun point= (point &rest more-points)
  "Return T if all of its argument points have same line and point, NIL otherwise."
  (assert (%always-same-buffer point more-points))
  (loop :for point2 :in more-points
        :always (%point= point point2)))

(defun point/= (point &rest more-points)
  "Return T if no two of its argument points have same line and point, NIL otherwise."
  (assert (%always-same-buffer point more-points))
  (loop :for point1 := point :then (first points)
        :for points :on more-points
        :always (loop :for point2 :in points
                      :never (%point= point1 point2))))

(defun point< (point &rest more-points)
  "Return T if its argument points are in strictly increasing order, NIL otherwise."
  (assert (%always-same-buffer point more-points))
  (loop :for point1 := point :then point2
        :for point2 :in more-points
        :always (%point< point1 point2)))

(defun point<= (point &rest more-points)
  "Return T if argument points are in strictly non-decreasing order, NIL otherwise."
  (assert (%always-same-buffer point more-points))
  (loop :for point1 := point :then point2
        :for point2 :in more-points
        :always (or (%point< point1 point2)
                    (%point= point1 point2))))

(defun point> (point &rest more-points)
  "Return T if its argument points are in strictly decreasing order, NIL otherwise."
  (loop :for point1 := point :then point2
        :for point2 :in more-points
        :always (%point< point2 point1)))

(defun point>= (point &rest more-points)
  "Return T if argument points are in strictly non-increasing order, NIL otherwise."
  (assert (%always-same-buffer point more-points))
  (loop :for point1 := point :then point2
        :for point2 :in more-points
        :always (or (%point< point2 point1)
                    (%point= point2 point1))))

(defun point-closest (point point-list &key (direction :up) (same-line nil))
  "Return the closest point on the POINT-LIST compare to POINT.
DIRECTION can be :up or :down depending on the desired point.
SAME-LINE if T the point in POINT-LIST can be in the same line as POINT."
  (loop :for p :in point-list
        :for flag := t :then nil
        :with closest := nil
        :do (progn
              (when flag (setf closest p))

              (when (or (and (eq direction :up)
                             (and (point> point p closest)
                                  (or same-line
                                      (not (same-line-p p point)))))
                        (and (eq direction :down)
                             (point< closest point p)
                             (or same-line
                                 (not (same-line-p p point)))))

                (setf closest p)))
        :finally (return (and (or (and (eq direction :up)
                                       (point> point closest))
                                  (and (eq direction :down)
                                       (point< point closest)))
                              closest ))))

(defun point-min (point &rest more-points)
  (assert (%always-same-buffer point more-points))
  (loop :with min := point
        :for point :in more-points
        :do (when (point< point min)
              (setf min point))
        :finally (return min)))

(defun point-max (point &rest more-points)
  (assert (%always-same-buffer point more-points))
  (loop :with max := point
        :for point :in more-points
        :do (when (point< max point)
              (setf max point))
        :finally (return max)))
