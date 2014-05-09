#lang racket

(require "main.rkt")

(app/get "/"
         (lambda (req) "hello this is index"))

(app/get "aboutme"
         (lambda (req)
           (response/json "something about me")))

(app/get "post/:id/:name"
         (lambda (req)
           (let* ([id (param 'id)] [name (param 'name)])
             (cond
               [(not (string? id)) (set! id "1")])
             (string-append "id is"  id " name is " name))))

(app/listen 8002)

(app/run)
