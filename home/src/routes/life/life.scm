(define canvas (dom-element "#life"))
(define ctx (js-invoke canvas "getContext" "2d"))
(define width (js-ref canvas "width"))
(define height (js-ref canvas "height"))

(define cell-size 20)
(define num-rows (/ width cell-size))
(define num-cols (/ height cell-size))
(define grid-size (* num-rows num-cols))

(define iterations 0)

(define (make-state w h)
    (make-vector (* w h) #f))

(define s0 (make-state num-rows num-cols))
(define s1 (make-state num-rows num-rows))

;; set a position in the state to a certain value
(define (state-set! state i j v)
    (vector-set! state (grid-index i j) v))

(define (state-ref state i j)
    (let ((index (grid-index i j)))
        (if (or (< index 0) (>= index grid-size)) #f
            (vector-ref state index))))

(define (init-states)
    (begin
        (vector-fill! s0 #f)
        (vector-fill! s1 #f)))

(define (swap-states!)
    (let ((tmp s0))
        (set! s0 s1)
        (set! s1 tmp)))

(define (grid-index x y)
    (+ (* y num-cols) x))

(define (count-neighbors state x y)
    (length (filter
        (lambda (coords) (state-ref state (car coords) (cdr coords)))
        (quasiquote
        ((,(- x 1) . ,(+ y 1)) (,x . ,(+ y 1)) (,(+ x 1) . ,(+ y 1))
        (,(- x 1) . ,y) (,(+ x 1) . ,y)
        (,(- x 1) . ,(- y 1)) (, x . ,(- y 1)) (,(+ x 1) . ,(- y 1)))))))

(define (transition state x y)
    (let ((is-populated (state-ref state x y))
        (num-neighbors (count-neighbors state x y)))
        (cond ((and is-populated (= num-neighbors 2)) #t)
                ((and is-populated (= num-neighbors 3)) #t)
                ((and (not is-populated) (= num-neighbors 3)) #t)
                (else #f))))

;; result new state in 0, old state in 1
(define (next-state current)
    (let loop ((i 0) (j 0))
        (cond ((>= j num-rows) '())
            ((>= i num-cols) (loop 0 (+ j 1)))
            (else
                (state-set! s1 i j (transition current i j))
                (loop (+ i 1) j)))))

(define (draw-cell x y fill)
    (let ((x (* x cell-size)) (y (* y cell-size)))
        (begin
            (if fill
                (js-invoke ctx "fillRect" x y cell-size cell-size)
                (js-invoke ctx "clearRect" x y cell-size cell-size)))
            (js-invoke ctx "strokeRect" x y cell-size cell-size)))

(define (draw-state state)
    (let loop ((i 0) (j 0))
        (cond ((>= j num-rows) '())
            ((>= i num-cols) (loop 0 (+ j 1)))
            (else
                (draw-cell i j (state-ref state i j))
                (loop (+ i 1) j)))))

(define (step)
    (next-state s0)
    (swap-states!)
    (draw-state s0))

(define (int-div a b)
    (floor (/ a b)))

(define offset-left (js-ref canvas "offsetLeft"))
(define offset-top (js-ref canvas "offsetTop"))

(add-handler! canvas "click" (lambda (ev)
    (let* ((x (- (js-ref ev "pageX") offset-left))
            (y (- (js-ref ev "pageY") offset-top))
            (i (int-div x cell-size))
            (j (int-div y cell-size))
            (v (not (state-ref s0 i j))))
                (begin
                    (state-set! s0 i j v)
                    (draw-cell i j v)))))

(define (start)
    (step)
    (set! iterations (+ iterations 1)))

(define (stop) (print "stop!"))

(define (reset)
    (init-states)
    (draw-state s0))

(reset)