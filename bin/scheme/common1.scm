(provide 'common1.scm)


;; redefine 'ow!'
#||
(set! ow! (lambda ()      
  (call-with-output-string
   (lambda (p)
     (let ((ow (owlet))
	   (elist (list (rootlet))))
       
       ;; show current error data
       (format p "\n;error: ~A" (ow 'error-type))
       (when (pair? (ow 'error-data))
             (format p ": ~A" (apply format #f (ow 'error-data))))

       (format p "~%;error-code: ~S~%" (ow 'error-code))
       (if (ow 'error-line)
           (format p "~%;error-file/line: ~S[~A]~%" (ow 'error-file) (ow 'error-line))
           (format p "~%;error-file/line: ; no file/linenum"))

       (define (print-frame num x l f)
         (if (and (integer? (car l))
                  (string? (car f))
                  (not (string=? (car f) "*stdout*")))
             (format p " ~%    ~A. ~S~40T;~A[~A]" num (car x) (car f) (car l))
             (format p " ~%    ~A. ~S; no file/linenum" num (car x))))
         
       ;; show history, if available
       (when (pair? (ow 'error-history)) ; a circular list, starts at error-code, entries stored backwards
	 (let ((history ())
	       (lines ())
	       (files ())
               (num 2)
	       (start (ow 'error-history)))
	   (do ((x (cdr start) (cdr x)))
	       ((eq? x start)
		(format p "~%error-history:~%    1. ~S ; no file/linenum" (car start))
                ;;(print-frame 1 x lines files)
		(do ((x history (cdr x))
		     (l lines (cdr l))
		     (f files (cdr f)))
		    ((null? x))
		  (if (and (integer? (car l))
			   (string? (car f))
			   (not (string=? (car f) "*stdout*")))
		      (format p " ~%    ~A. ~S~40T;~A[~A]" num (car x) (car f) (car l))
		      (format p " ~%    ~A. ~S; no file/linenum" num (car x)))
                  (set! num (1+ num)))
		(format p "~%"))
	     (set! history (cons (car x) history))
	     (set! lines (cons (pair-line-number (car x)) lines))
	     (set! files (cons (pair-filename (car x)) files)))))
       
       ;; show the enclosing contexts
       (let ((old-print-length (*s7* 'print-length)))
	 (set! (*s7* 'print-length) 8)
	 (do ((e (outlet ow) (outlet e))) 
	     ((memq e elist)
	      (set! (*s7* 'print-length) old-print-length))
	   (if (> (length e) 0)
	       (format p "~%~{~A~| ~}~%" e))
	   (set! elist (cons e elist))))))))
      )
||#


 
#||
(define (c-display . rest)
  (for-each (lambda (d)
              (display d)
              (display " "))
            rest)
  (newline))
||#

#||
(define (hash-table-to-string table)
  (<-> "hash:(map values (hash-table* 'b 2 'c 3))
  (values table))

(hash-table-to-string (hash-table* 'b 2 'c 3))
||#

(define-expansion (define2 name correct-type? value)
  (define s (gensym "s"))
  (define v (gensym "v"))
  (if (<ra> :release-mode)
      `(define ,name ,value)
      `(begin     
         (define ,name (let ((,v ,value))
                         (if (,correct-type? ,v)
                             ,v
                             (error 'wrong-type (list "For " ',name ': ,v)))))
         (set! (symbol-access ',name)
               (lambda (,s ,v)
                 (if (,correct-type? ,v)
                     ,v
                     (error 'wrong-type (list "For " ',name "New value:" ,v "Prev value:" ,name))))))))

#!!
(pp (macroexpand (define2 add9 integer? 50)))

(define2 anint2 integer? 'b)
(define2 anint2 integer? 5)

(set! anint2 30)
(set! anint2 'b)
!!#


;; Partial application
(define (P-> funcname . args)
  (lambda args2
    (apply funcname (append args args2))))

;; Small one-arg function
(define-expansion (L-> body)
  `(lambda (_)
     ,body))

(define (curry-or . funcs)
  (L-> (let loop ((funcs funcs))
         (if (null? funcs)
             #f
             (or ((car funcs) _)
                 (loop (cdr funcs)))))))

(define (to-displayable-string a)
  ;;(display "____ a: ")(display a)(newline)
  (cond ((keyword? a)
         (<-> "#:" (to-displayable-string (keyword->symbol a))))
        ((symbol? a)
         (<-> "'" (symbol->string a)))
        ((string? a)
         a)
        ((char? a)
         a)
        ((number? a)
         (number->string a))
        ((equal? #t a)
         "#t")
        ((equal? #f a)
         "#f")
        ((list? a)
         (<-> "(" (apply <-> (map (lambda (b) (<-> (to-displayable-string b) " ")) a)) ")"))
        ((pair? a)
         (<-> "(" (to-displayable-string (car a)) " . " (to-displayable-string (cdr a)) ")"))
        ((vector? a)
         (<-> "[" (apply <-> (map (lambda (b) (<-> (to-displayable-string b) " ")) (vector->list a))) "]"))
        ;;((hash-table? a)
        ;; (<-> 
        ((procedure? a)
         (if #f
             "something"
             (catch #t
                    (lambda ()
                      (event-to-string a))
                    (lambda args
                      (catch #t
                             (lambda ()
                               (cloned-instrument-to-string a))
                             (lambda args
                               (catch #t
                                      (lambda ()
                                        (to-displayable-string (a :dir)))
                                      (lambda args
                                        (with-output-to-string
                                          (lambda ()
                                            (display a)))))))))))
        ((hash-table? a)
         (with-output-to-string
           (lambda ()
             (display a))))
        ;;(<-> "{ " (to-displayable-string (map values a)) " }"))
        ;;(<-> "function [ " (to-displayable-string (procedure-source a)) " ]"))))))
        (else
         "#unknown type")))


#||

(define (provoceit)
  (define (delete-note2)
    (ra:undo-notes (pianonote-info :tracknum))
    (ra:delete-pianonote 0
                         (pianonote-info :notenum)
                         (pianonote-info :tracknum))
    #f)
  
  (define (add-pitch2)
    (ra:undo-notes (pianonote-info :tracknum))
    (define Place (get-place-from-y $button $y))
    (define Value (ra:get-note-value (pianonote-info :notenum) (pianonote-info :tracknum)))
    (define Num (ra:create-pitch Value Place (pianonote-info :tracknum)))
    (if (= -1 Num)
        #f
        #f))
  (popup-menu "Delete Note2" delete-note2
              "Add Portamento2" add-pitch2))

;;(provoceit)



'(string-append ""
               (catch #t
                      (lambda ()
                        (cloned-instrument-to-string 'asdf))
                      (lambda args
                        (catch #t
                               (lambda ()
                                 (event-to-string a))
                               (lambda args
                                 "error"))))
               "")
(define level 0)
(define (to-displayable-string2 a)
  (for-each (lambda (level)
             (display "  "))
           (iota level))
  (display level)(display ": ")(display a)(newline)
  (set! level (1+ level))
  (define result (to-displayable-string-intern a))
  (set! level (1- level))
  (for-each (lambda (level)
             (display "  "))
           (iota level))
  (display level)(display "<____ res: ")(display result)(newline)
  result)

||#

(define-constant *empty-symbol* '___empty_symbol) ;; s7 doesn't allow converting empty string to symbol

(define (to-string a)
  (cond ((symbol? a)
         (if (eq? *empty-symbol* a)
             ""
             (symbol->string a)))
        ((string? a)
         a)
        ((number? a)
         (number->string a))
        ((equal? #t a)
         "#t")
        ((equal? #f a)
         "#f")
        ((procedure? a)
         (catch #t
                (lambda ()
                  (event-to-string a))
                (lambda args
                  a)))
        ((keyword? a)
         (<-> "#:" (to-string (keyword->symbol a))))
        (else
         (with-output-to-string
           (lambda ()
             (display a))))))

(define (<-> . args) (apply string-append (map to-string args)))
(define (<_> . args)
  (let ((s (apply <-> args)))
    (if (string=? "" s)
        *empty-symbol*
        (string->symbol s))))

(define (<-displayable-> . args) (apply string-append (map to-displayable-string args)))

#||
(let ((result (<-> "hello: "
                   (with-output-to-string
                     (lambda ()
                       (write (lambda (a b c) 'hello)))))))
  (c-display "result2: -" result "-"))
||#


#||
(<-displayable-> (list 2 3 4))
(<-displayable-> (cons 3 4))
(<-displayable-> :ga)
(<-displayable-> ':ga)
(<-displayable-> 'ga)
(<-displayable-> :'ga)
||#

(define (c-display . args)
  (for-each (lambda (arg)
              (display (to-displayable-string arg))
              (display " "))
            args)
  (newline))

(define *my-gensym-N* 0)

(define (identity a)
  a)

(define (nth n list)
  (list-ref list (- n 1)))

#||
(define (1+ n)
  (+ n 1))

(define (1- n)
  (- n 1))
||#

(define (yppla l c)
  (apply c l))


(define (last das-list) ;; Wouldn't be surprised if this version is slower than '(car (reverse das-list))' though... (but no, this one is much faster with the test below)
  ;;(c-display "last//// " das-list)
  (let loop ((a (car das-list))
             (b (cdr das-list)))
    (if (null? b)
        a
        (loop (car b)
              (cdr b)))))

#||
(define (last2 das-list)
  (car (reverse das-list)))

(let ((list (make-list 10000000 "hello")))
  (c-display "1")
  (last list)
  (c-display "2")
  (last2 list)
  (c-display "3"))
||#


(define (find-first das-list func)
  (cond ((null? das-list)
         #f)
        ((func (car das-list))
         (car das-list))
        (else
         (find-first (cdr das-list) func))))


(define (find-last das-list func)
  (let loop ((candidate #f)
             (das-list das-list))
    (if (null? das-list)
        candidate
        (loop (or (and (func (car das-list))
                       (car das-list))
                  candidate)
              (cdr das-list)))))

#||
(find-last '(2 5 3 9 8) (lambda (x)
                          (< x 4)))
||#

(define (split-list das-list func)
  (let loop ((before '())
             (after das-list))
    (cond ((null? after)
           (list (reverse before) '()))
          ((func (car after))
           (list (reverse before) after))
          (else
           (loop (cons (car after) before)
                 (cdr after))))))
  
(define (take-while das-list func)
  (cond ((null? das-list)
         '())
        ((func (car das-list))
         (cons (car das-list)
               (take-while (cdr das-list) func)))
        (else
         '())))

(define (remove-while das-list func)
  (cond ((null? das-list)
         '())
        ((func (car das-list))
         (remove-while (cdr das-list) func))
        (else
         das-list)))


;; a 50 b 90 c 100 -> '((a 50)(b 90)(c 100))
(define (make-assoc-from-flat-list rest)  
  (if (null? rest)
      '()
      (let ((A (car rest))
            (B (cadr rest))
            (Rest (cddr rest)))
        (cons (list A B)
              (make-assoc-from-flat-list Rest)))))

#||
(make-assoc-from-flat-list (list "a" 50 "b" 90 "c" 100))
||#


;; string

(define (string-split string ch)
  (if (string=? string "")
      '()
      (let ((splitted (split-list (string->list string)
                                  (lambda (ch2)
                                    (char=? ch ch2)))))
        (cond ((null? (cadr splitted))
               (list string))
              ((null? (car splitted))
               (string-split (list->string (cdr (cadr splitted))) ch))
              (else
               (cons (list->string (car splitted))
                     (string-split (list->string (cdr (cadr splitted))) ch)))))))

;; Other variants (not implemented): string-take, string-drop-right, string-take-right
(define (string-drop string pos)
  (substring string pos))

(***assert*** (string-drop "abcd" 1)
              "bcd")

(define (string-starts-with? string startswith)
  (define (loop string startswith)
    (cond ((null? startswith)
           #t)
          ((null? string)
           #f)
          ((char=? (car string) (car startswith))
           (loop (cdr string) (cdr startswith)))
          (else
           #f)))
  (loop (string->list string)
        (string->list startswith)))

(***assert*** (string-starts-with? "" "") #t)
(***assert*** (string-starts-with? "asdf" "as") #t)
(***assert*** (string-starts-with? "asdf" "") #t)
(***assert*** (string-starts-with? "" "a") #f)
(***assert*** (string-starts-with? "a" "a") #t)
(***assert*** (string-starts-with? "a" "b") #f)
(***assert*** (string-starts-with? "ab" "a") #t)

(define (string-ends-with? string endswith)
  (define (loop string startswith)
    (cond ((null? startswith)
           #t)
          ((null? string)
           #f)
          ((char=? (car string) (car startswith))
           (loop (cdr string) (cdr startswith)))
          (else
           #f)))
  (loop (reverse (string->list string))
        (reverse (string->list endswith))))

(***assert*** (string-ends-with? "" "") #t)
(***assert*** (string-ends-with? "asdf" "df") #t)
(***assert*** (string-ends-with? "asdf" "") #t)
(***assert*** (string-ends-with? "" "a") #f)
(***assert*** (string-ends-with? "a" "a") #t)
(***assert*** (string-ends-with? "a" "b") #f)
(***assert*** (string-ends-with? "ab" "b") #t)

;; Returns true if bb is placed inside aa.
(define (string-contains? aa bb)
  (if (or (string=? bb "")
          (string-position bb aa))
      #t
      #f))
#||
  (if (string=? bb "")
      #t
      (begin
        (define b (bb 0))
        (let loop ((aa (string->list aa)))
          (cond ((null? aa)
                 #f)
                ((and (char=? b (car aa))
                      (string-starts-with? (list->string aa) bb))
                 #t)
                (else
                 (loop (cdr aa))))))))
  ||#
  
(***assert*** (string-contains? "" "") #t)
(***assert*** (string-contains? "asdf" "df") #t)
(***assert*** (string-contains? "asdf" "") #t)
(***assert*** (string-contains? "" "a") #f)
(***assert*** (string-contains? "a" "a") #t)
(***assert*** (string-contains? "a" "b") #f)
(***assert*** (string-contains? "ab" "b") #t)
(***assert*** (string-contains? "abcd" "bc") #t)
(***assert*** (string-contains? "abccb" "bcd") #f)
(***assert*** (string-contains? "abbcd" "bcd") #t)

(define (string-case-insensitive-contains? aa bb)
  (string-contains? (string-upcase aa) (string-upcase bb)))

(define (capitalize-first-char-in-stringlist l)
  (cons (char-upcase (car l))
        (cdr l)))

(define (capitalize-first-char-in-string str)
  (list->string (capitalize-first-char-in-stringlist (string->list str))))


(define (string-join strings separator)
  (if (null? strings)
      ""
      (<-> (car strings)
           (let loop ((strings (cdr strings)))
             (if (null? strings)
                 ""
                 (<-> separator
                      (car strings)
                      (loop (cdr strings))))))))

(***assert*** (string-join (list "a" "bb" "ccc") " + ")
              "a + bb + ccc")

(define (get-python-ra-funcname funcname)
  (let ((parts (string-split (string-drop funcname 3) #\-)))
    (<-> "ra."
         (car parts)
         (apply <->
                (map capitalize-first-char-in-string
                     (cdr parts))))))

(***assert*** (get-python-ra-funcname "ra:transpose-block")
              "ra.transposeBlock")

(define (get-python-ra-funccall rafuncname args)
  (<-> (get-python-ra-funcname rafuncname)
       "("
       (string-join (map to-displayable-string args) ",")
       ")"))
              
(***assert*** (get-python-ra-funccall "ra:transpose-block" (list 1))
              "ra.transposeBlock(1)")


