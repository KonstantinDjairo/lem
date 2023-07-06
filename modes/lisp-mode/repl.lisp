(in-package :lem-lisp-mode/internal)

(define-attribute printed-object-attribute
  (t :foreground :base0A :bold t))

(define-attribute repl-result-attribute
  (t :foreground :base06 :bold t))

(define-major-mode lisp-repl-mode lisp-mode
    (:name "REPL"
     :keymap *lisp-repl-mode-keymap*
     :syntax-table lem-lisp-syntax:*syntax-table*)
  (cond
    ((eq (repl-buffer) (current-buffer))
     (repl-reset-input)
     (lem/listener-mode:start-listener-mode (merge-pathnames "history/lisp-repl" (lem-home)))
     (setf (variable-value 'completion-spec) 'repl-completion)
     (setf (buffer-context-menu (current-buffer))
           (make-instance 'lem/context-menu:context-menu
                          :compute-items-function 'repl-compute-context-menu-items)))
    (t
     (editor-error "No connection for repl. Did you mean 'start-lisp-repl' command?"))))

(define-key *lisp-repl-mode-keymap* "C-c C-c" 'lisp-repl-interrupt)
(define-key *lisp-repl-mode-keymap* "," 'lisp-repl-shortcut)
(define-key *lisp-repl-mode-keymap* "M-Return" 'lisp-repl-copy-down)
(define-key *lisp-repl-mode-keymap* "C-c p" 'backward-prompt)
(define-key *lisp-repl-mode-keymap* "C-c n" 'forward-prompt)

(defgeneric open-inspector-by-repl (inspected-parts))

(defun inspect-printed-object (id)
  (lisp-eval-async `(micros:inspect-printed-object ,id)
                   #'open-inspector-by-repl))

(defun context-menu-inspect-printed-object ()
  (let* ((point (get-point-on-context-menu-open))
         (id (object-id-at point)))
    (when id
      (lem/context-menu:make-item
       :label "Inspect"
       :callback (lambda (&rest args)
                   (declare (ignore args))
                   (inspect-printed-object id))))))

(defun context-menu-copy-down-printed-object ()
  (let* ((point (get-point-on-context-menu-open))
         (id (object-id-at point)))
    (when id
      (lem/context-menu:make-item
       :label "Copy Down"
       :callback (lambda (&rest args)
                   (declare (ignore args))
                   (copy-down-to-repl 'micros:get-printed-object-by-id id))))))

(defun context-menu-describe-object ()
  (let* ((point (get-point-on-context-menu-open))
         (id (object-id-at point)))
    (when id
      (lem/context-menu:make-item
       :label "Describe"
       :callback (lambda (&rest args)
                   (declare (ignore args))
                   (listener-eval (format nil
                                          "(cl:describe (micros:get-printed-object-by-id ~A))"
                                          id)))))))

(defun context-menu-pretty-print ()
  (let* ((point (get-point-on-context-menu-open))
         (id (object-id-at point)))
    (when id
      (lem/context-menu:make-item
       :label "Pretty Print"
       :callback (lambda (&rest args)
                   (declare (ignore args))
                   (listener-eval (format nil
                                          "(cl:pprint (micros:get-printed-object-by-id ~A))"
                                          id)))))))

(defun repl-compute-context-menu-items ()
  (remove
   nil
   (list (context-menu-describe-symbol)
         (context-menu-find-definition)
         (context-menu-find-references)
         (context-menu-hyperspec)
         (context-menu-inspect-printed-object)
         (context-menu-copy-down-printed-object)
         (context-menu-describe-object)
         (context-menu-pretty-print))))

(defun read-string-thread-stack ()
  (buffer-value (repl-buffer) 'read-string-thread-stack))

(defun (setf read-string-thread-stack) (val)
  (setf (buffer-value (repl-buffer) 'read-string-thread-stack) val))

(defun read-string-tag-stack ()
  (buffer-value (repl-buffer) 'read-string-tag-stack))

(defun (setf read-string-tag-stack) (val)
  (setf (buffer-value (repl-buffer) 'read-string-tag-stack) val))

(define-command lisp-repl-interrupt () ()
  (send-message-string *connection*
                       (format nil "(:emacs-interrupt ~(~S~))"
                               (or (car (read-string-thread-stack))
                                   :repl-thread))))

(defmethod execute ((mode lisp-repl-mode) (command lem/listener-mode:listener-return) argument)
  (let (button)
    (cond ((setf button (button-at (current-point)))
           (button-action button))
          ((repl-paren-correspond-p (buffer-end-point (current-buffer)))
           (call-next-method))
          (t
           (insert-character (current-point) #\newline)
           (indent-line (current-point))))))

(defmethod execute :before
    ((mode lisp-repl-mode)
     (command lem/listener-mode:listener-clear-buffer)
     argument)
  (lisp-eval-async '(micros:clear-printed-objects)))

(defvar *lisp-repl-shortcuts* '())

(defmacro with-repl-prompt (() &body body)
  `(let ((lem/prompt-window:*prompt-completion-window-shape* nil))
     ,@body))

(defun repl-prompt-for-string (prompt &rest args)
  (with-repl-prompt ()
    (apply #'prompt-for-string
           prompt
           :gravity :cursor
           :use-border nil
           args)))

(defun prompt-for-shortcuts ()
  (let* ((*lisp-repl-shortcuts* *lisp-repl-shortcuts*)
         (names (mapcar #'car *lisp-repl-shortcuts*)))
    (cdr (assoc (repl-prompt-for-string
                 "Command: "
                 :completion-function (lambda (x) (completion-strings x names))
                 :test-function (lambda (name) (member name names :test #'string=))
                 :history-symbol 'mh-lisp-repl-shortcuts)
                *lisp-repl-shortcuts* :test #'equal))))

(define-command lisp-repl-shortcut (n) ("p")
  (with-point ((point (current-point)))
    (if (point>= (lem/listener-mode:input-start-point (current-buffer)) point)
        (let ((fun (prompt-for-shortcuts)))
          (when fun
            (funcall fun n)))
        (let ((c (insertion-key-p (last-read-key-sequence))))
          (insert-character point c n)))))

(defmacro define-repl-shortcut (name lambda-list &body body)
  (if (symbolp lambda-list)
      `(progn
         (setf *lisp-repl-shortcuts*
               (remove ,(string-downcase name) *lisp-repl-shortcuts* :key 'first :test 'equal))
         (push (cons ,(string-downcase name) ',lambda-list) *lisp-repl-shortcuts*)
         ',name)
      `(progn
         (setf *lisp-repl-shortcuts*
               (remove ,(string-downcase name) *lisp-repl-shortcuts* :key 'first :test 'equal))
         (push (cons ,(string-downcase name) ',name) *lisp-repl-shortcuts*)
         (defun ,name ,lambda-list ,@body))))

(defun repl-buffer ()
  (get-buffer "*lisp-repl*"))

(defun ensure-repl-buffer-exist ()
  (let ((buffer (repl-buffer)))
    (unless buffer
      (with-current-window (current-window)
        (start-lisp-repl))
      (setf buffer (repl-buffer)))
    buffer))

(defun repl-set-prompt (point)
  (insert-string point
                 (format nil "~A> " (connection-prompt-string *connection*)))
  point)

(defun repl-paren-correspond-p (point)
  (unless (eq (repl-buffer) (point-buffer point))
    (return-from repl-paren-correspond-p))
  (with-point ((start (lem/listener-mode:input-start-point (repl-buffer))))
    (when (point<= start point)
      (let ((state (parse-partial-sexp start point)))
        (and (not (pps-state-string-or-comment-p state))
             (>= 0 (pps-state-paren-depth state)))))))

(defun repl-reset-input ()
  (let ((buffer (repl-buffer)))
    (when buffer
      (setf (variable-value 'lem/listener-mode:listener-set-prompt-function :buffer buffer)
            'repl-set-prompt
            (variable-value 'lem/listener-mode:listener-check-input-function :buffer buffer)
            'repl-paren-correspond-p
            (variable-value 'lem/listener-mode:listener-execute-function :buffer buffer)
            'repl-eval))))

(defun repl-change-read-line-input ()
  (setf (variable-value 'lem/listener-mode:listener-set-prompt-function)
        #'identity
        (variable-value 'lem/listener-mode:listener-check-input-function)
        (constantly t)
        (variable-value 'lem/listener-mode:listener-execute-function)
        'repl-read-line))

(defun clear-repl ()
  (when (repl-buffer)
    (lem/listener-mode:clear-listener (repl-buffer))))

(defun get-repl-window ()
  (let ((buffer (repl-buffer)))
    (when buffer
      (if (eq buffer (window-buffer (current-window)))
          (current-window)
          (first (get-buffer-windows buffer))))))

(defun repl-buffer-width ()
  (alexandria:when-let* ((window (get-repl-window))
                         (width (- (window-width window) 2)))
    width))

(defun repl-completion (point)
  (with-point ((p point))
    (cond ((maybe-beginning-of-string p)
           (character-offset p 1)
           (let ((str (points-to-string p point)))
             (mapcar (lambda (filename)
                       (make-completion-item :label filename
                                             :start p
                                             :end point))
                     (completion-file str (lem:buffer-directory (point-buffer p))))))
          (t
           (completion-symbol p)))))

(defun repl-eval (point string)
  (declare (ignore point))
  (check-connection)
  (listener-eval string))

(defvar *repl-evaluating* nil)

(defun listener-eval (string)
  (ensure-repl-buffer-exist)
  (setf *repl-evaluating* t)
  (let ((spinner (start-loading-spinner :modeline
                                        :buffer (repl-buffer)
                                        :loading-message "Evaluating...")))
    (request-listener-eval
     *connection*
     string
     (lambda (value)
       (declare (ignore value))
       (setf *repl-evaluating* nil)
       (stop-loading-spinner spinner)
       (lem/listener-mode:refresh-prompt (ensure-repl-buffer-exist)))
     (repl-buffer-width))))

(defun repl-read-string (thread tag)
  (let ((buffer (ensure-repl-buffer-exist)))
    (push thread (read-string-thread-stack))
    (push tag (read-string-tag-stack))
    (setf (current-window) (pop-to-buffer buffer))
    (buffer-end (current-point))
    (lem/listener-mode:change-input-start-point (current-point))
    (repl-change-read-line-input)))

(defun repl-pop-stack ()
  (let ((thread (pop (read-string-thread-stack)))
        (tag (pop (read-string-tag-stack))))
    (when (null (read-string-thread-stack))
      (repl-reset-input))
    (values thread tag)))

(defun repl-abort-read (thread tag)
  (declare (ignore thread tag))
  (repl-pop-stack)
  (message "Read aborted"))

(defun repl-read-line (point string)
  (declare (ignore point))
  (multiple-value-bind (thread tag) (repl-pop-stack)
    (dispatch-message (list :emacs-return-string
                            thread
                            tag
                            (concatenate 'string
                                         string
                                         (string #\newline))))))

(define-command start-lisp-repl (&optional (use-this-window nil)) ("P")
  (check-connection)
  (flet ((switch (buffer split-window-p)
           (if split-window-p
               (setf (current-window) (pop-to-buffer buffer))
               (switch-to-buffer buffer))))
    (lem/listener-mode:listener-start
     "*lisp-repl*"
     'lisp-repl-mode
     :switch-to-buffer-function (alexandria:rcurry #'switch (not use-this-window)))))

(define-command lisp-switch-to-repl-buffer () ()
  (let ((buffer (repl-buffer)))
    (if buffer
        (setf (current-window) (pop-to-buffer buffer))
        (start-lisp-repl))))

(defun copy-down-to-repl (slimefun &rest args)
  (unless (find-package :micros/repl)
    (make-package :micros/repl))
  (lisp-eval-async
   `(,(read-from-string "micros/repl::listener-save-value") ',slimefun ,@args)
   (lambda (result)
     (declare (ignore result))
     (lisp-eval-async
      `(,(read-from-string "micros/repl::listener-get-value"))))))

(define-command lisp-repl-copy-down () ()
  (alexandria:when-let ((id (object-id-at (current-point))))
    (copy-down-to-repl 'micros:get-printed-object-by-id id)))

(defun repl-buffer-write-point (buffer)
  (or (buffer-value buffer 'repl-write-point)
      (setf (buffer-value buffer 'repl-write-point)
            (let ((point (copy-point (buffer-point buffer) :left-inserting)))
              (buffer-start point)))))

(defun call-with-repl-point (function)
  (let* ((buffer (ensure-repl-buffer-exist))
         (point (repl-buffer-write-point buffer)))
    (cond (*repl-evaluating*
           (buffer-end point))
          (t
           (when (point<= (lem/listener-mode:input-start-point buffer) point)
             (move-point point (lem/listener-mode:input-start-point buffer))
             (previous-single-property-change point :field))))
    (with-buffer-read-only buffer nil
      (let ((*inhibit-read-only* t))
        (funcall function point)))))

(defmacro with-repl-point ((point) &body body)
  `(call-with-repl-point (lambda (,point) ,@body)))

(defun write-string-to-repl (string)
  (with-repl-point (point)
    (insert-escape-sequence-string point string)
    (when (text-property-at point :field)
      (insert-character point #\newline)
      (character-offset point -1))))

(defun object-id-at (point)
  (text-property-at point 'object-id))

(defun write-object-to-repl (string id type)
  (assert (member type '(:standard-output :repl-result)))
  (with-repl-point (point)
    (with-point ((start point))
      (insert-string point
                     string
                     'object-id id
                     :attribute (if (eq type :repl-result)
                                    'repl-result-attribute
                                    'printed-object-attribute))
      (lem/button:apply-button-between-points
       start
       point
       (lambda (&rest args)
         (declare (ignore args))
         (inspect-printed-object id))))))

(defvar *escape-sequence-argument-specs*
  '(("0" :bold nil :reverse nil :underline nil)
    ("1" :bold t)
    ("2")
    ("4" :underline t)
    ("5")
    ("7" :reverse t)
    ("8")
    ("22" :bold nil)
    ("24" :underline nil)
    ("25")
    ("27" :reverse nil)
    ("28")

    ("30" :foreground "black")
    ("31" :foreground "red")
    ("32" :foreground "green")
    ("33" :foreground "yellow")
    ("34" :foreground "blue")
    ("35" :foreground "magenta")
    ("36" :foreground "cyan")
    ("37" :foreground "white")

    ("40" :background "black")
    ("41" :background "red")
    ("42" :background "green")
    ("43" :background "yellow")
    ("44" :background "blue")
    ("45" :background "magenta")
    ("46" :background "cyan")
    ("47" :background "white")

    ("90" :foreground "dim gray")
    ("91" :foreground "red")
    ("92" :foreground "green")
    ("93" :foreground "yello")
    ("94" :foreground "royalblue")
    ("95" :foreground "darkorchid1")
    ("96" :foreground "cyan1")
    ("97" :foreground "white")

    ("100" :background "dim gray")
    ("101" :background "red")
    ("102" :background "green")
    ("103" :background "yello")
    ("104" :background "royalblue")
    ("105" :background "darkorchid1")
    ("106" :background "cyan1")
    ("107" :background "white")))

(defun raw-seq-to-attribute (string)
  (let ((arguments (uiop:split-string string :separator '(#\;)))
        (attribute-parameters '()))
    (dolist (argument arguments)
      (alexandria:when-let (spec (assoc argument *escape-sequence-argument-specs*
                                        :test #'string=))
        (loop :for (key value) :on (rest spec) :by #'cddr
              :do (setf (getf attribute-parameters key) value))))
    (apply #'make-attribute attribute-parameters)))

(defun split-escape-sequence-string (string)
  (let ((acc '())
        (pos 0))
    (loop
      (multiple-value-bind (start end reg-starts reg-ends)
          (ppcre:scan "\\e\\[([^m]*)m" string :start pos)
        (unless (and start end reg-starts reg-ends) (return))
        (unless (= pos start)
          (push (subseq string pos start) acc))
        (push (raw-seq-to-attribute
               (subseq string
                       (aref reg-starts 0)
                       (aref reg-ends 0)))
              acc)
        (setf pos end)))
    (push (subseq string pos) acc)
    (nreverse acc)))

(defun parse-escape-sequence (string)
  (split-escape-sequence-string string))

(defun insert-escape-sequence-string (point string)
  (let ((tokens (parse-escape-sequence string))
        (current-attribute nil))
    (dolist (token tokens)
      (etypecase token
        (null
         (setf current-attribute nil))
        (attribute
         (setf current-attribute token))
        (string
         (insert-string point token :attribute current-attribute))))))

(define-repl-shortcut sayonara (n)
  (declare (ignorable n))
  (if (self-connection-p *connection*)
      (message "Can't say sayonara because it's self connection.")
      (interactive-eval "(micros:quit-lisp)")))

(define-repl-shortcut change-package (n)
  (declare (ignore n))
  (let* ((packages (mapcar (lambda (p)
                             (string-downcase (package-name p)))
                           (list-all-packages)))
         (package
           (repl-prompt-for-string
            "Package: "
            :completion-function (lambda (str)
                                   (sort (completion str packages)
                                         #'string-lessp))
            :test-function (lambda (package)
                             (find package packages :test #'string-equal)))))
    (lisp-set-package package)))

(define-repl-shortcut cd (n)
  (declare (ignore n))
  (let* ((directory
           (with-repl-prompt ()
             (prompt-for-directory "New directory: "
                                   :directory (buffer-directory)
                                   :gravity :cursor
                                   :use-border nil))))
    (lisp-set-directory :directory directory)))

(defun prompt-for-system (prompt)
  (let ((systems (lisp-eval '(micros:list-systems))))
    (repl-prompt-for-string prompt
                            :completion-function (lambda (string)
                                                   (completion string systems))
                            :test-function (lambda (string)
                                             (find string systems :test #'equal)))))

(define-repl-shortcut quickload (n)
  (declare (ignore n))
  (let ((system (prompt-for-system "Quickload System: ")))
    (listener-eval (prin1-to-string `(ql:quickload ,system)))))

(define-command backward-prompt () ()
  (when (equal (current-buffer) (repl-buffer))
    (move-to-previous-virtual-line (current-point))
    (lem:previous-single-property-change (lem:current-point) :field)))

(define-command forward-prompt () ()
  (when (equal (current-buffer) (repl-buffer))
    (move-to-next-virtual-line (current-point))
    (lem:next-single-property-change (lem:current-point) :field)
    (lem:next-single-property-change (lem:current-point) :field)))
