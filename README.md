raf
===

A simple REST Application Framework implements by [Racket](racket-lang.org)


####Usage

```racket
#lang racket

(require "main.rkt")

(app/get "/"
         (lambda (req) "hello world"))

(app/get "post/:id/:name"
         (lambda (req)
           (let* ([id (param 'id)] [name (param 'name)])
             (cond
               [(not (string? id)) (set! id "")])
             (string-append "id is"  id " and name is " name))))

(app/listen 80)

(app/run)
```
