#lang racket

(require web-server/servlet
         web-server/servlet-env)

(provide app/get
         app/post
         app/delete
         app/put
         app/listen
         app/run
         response/json
         response/404
         response/make
         param)

(define handlers (make-hash))
(hash-set! handlers 'get (make-hash))
(hash-set! handlers 'post (make-hash))
(hash-set! handlers 'put (make-hash))
(hash-set! handlers 'delete (make-hash))

(define (app/get path proc) (app/handler 'get path proc))
(define (app/post path proc) (app/handler 'post path proc))
(define (app/put path proc) (app/handler 'put path proc))
(define (app/delete path proc) (app/handler 'delete path proc))

(define app/handler
  (lambda (method path proc)
    (hash-set! (hash-ref handlers method) path proc)))

(define path->regexp
  (lambda (path)
    (regexp 
     (string-append
      "^/" 
      (string-trim (regexp-replace* #rx":[^\\/]+" path "([^/?]+)") "/") "(?:\\?|$)"))))

(define env/port 80)

(define (app/listen [port 80])
  (set! env/port port))

(define params (make-hash))
(define param
  (lambda (name)
    (hash-ref params name #f)))

(define response/json
  (lambda (content)
    (response/make #:mime-type #"application/json" content)))

(define response/404
  (lambda () 
    (response/make  #:code 404 "page not found")))

(define (response/make
         #:code [code 200]
         #:message [message #"OK"]
         #:seconds [seconds (current-seconds)]
         #:mime-type [mime-type TEXT/HTML-MIME-TYPE] 
         #:headers [headers (list (make-header #"Cache-Control" #"no-cache"))]
         content)
  
  (response/full
   code 
   message
   seconds
   mime-type
   headers
   (list (string->bytes/utf-8 content))))

(define app/run
  (lambda ()
    (serve/servlet
     (lambda (req)
       
       (define path (regexp-replace* #rx"\\?.*" (url->string (request-uri req)) ""))

       (define method
         (case (request-method req)
           [(#"GET") 'get]
           [(#"POST") 'post]
           [(#"PUT") 'put]
           [(#"DELETE") 'delete]))
       
       (define handler-key
         (findf 
          (lambda (key)
            (regexp-match (path->regexp key) path))
          
          (hash-keys (hash-ref handlers method))))
       
       (case handler-key
         [(#f) (response/404)]
         [else 
          (define keys
            (map (lambda (match) (string->symbol (substring match 2)))
                 (regexp-match* #rx"/:([^\\/]+)" handler-key)))
          
          (define pairs
            (for/list ([key keys] [val (cdr (regexp-match (path->regexp handler-key) path))])
              (cons key val)))
          
          (set! params (make-hash (append pairs (url-query (request-uri req)))))
          
          (define handler (hash-ref handlers method))
          (define response ((hash-ref handler handler-key #f) req))
          (if (response? response)
              response
              (response/make ((hash-ref handler handler-key #f) req)))]))
     
     #:launch-browser? #f
     #:servlet-path "/"
     #:port env/port
     #:listen-ip #f
     #:servlet-regexp #rx"")))
