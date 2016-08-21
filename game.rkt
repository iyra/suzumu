#lang racket

; home directory: (find-system-path 'home-dir)
; game directory: (build-path (find-system-path 'home-dir) "suzumu")
; scenes directory: (build-path (find-system-path 'home-dir) "suzumu" "scenes")
; saves directory: (build-path (find-system-path 'home-dir) "suzumu" "saves")

(require racket/serialize)
(require racket/include)
(require racket/hash)

(define scenes-loc (build-path (find-system-path 'home-dir) "suzumu" "scenes"))
(define scenes-files (directory-list (build-path (find-system-path 'home-dir) "suzumu" "scenes") #:build? #t))

; from http://stackoverflow.com/a/20783438/1015599
(define-namespace-anchor anc)
(define ns (namespace-anchor->namespace anc))

(define (eval-clause clause state)
  (for ([x state])
    (eval `(define ,(first x) ,(second x)) ns))
  (eval (cons 'or (map (curryr eval ns) clause)) ns))

(struct scene
  (name description choices
        pre-scene-action)) ; the action that's taken before the scene is loaded

(struct choice
  (name ; the name of the choice presented to the user such as "Open door" (string)
   destination ; scene in scenes (string)
   requirement ; requirement for the player's stats/backpack (lambda)
   action)) ; the action that's taken after selection but before loading the next scene

(serializable-struct player
  (name ; human-readable name of the character (string)
   hp ; health points (integer)
   backpack-items)) ; list of items in backpack (string[])

(struct backpack-item
  (name ; human-readable name of item
   action)) ; what it does to player's stats/backpack

(define scenes (make-hash))

(define (insert-scenes files n)
  (if (not (empty? files))
      (if (string-suffix? (path->string (car files)) ".scene")
          (begin (hash-union! scenes (load-scenes (path->string (car files))))
                 (insert-scenes (cdr files) (+ n 1)))
          (insert-scenes (cdr files) n))
      (printf "~a scenes loaded.~n" n)))

(define (display-choices choices n)
  (printf "~a: ~a~n" n (choice-name (car choices)))
  (if (not (empty? (cdr choices)))
      (display-choices (cdr choices) (+ n 1))
      #t))

(define (add-to-backpack p item)
  (player (player-name p)
          (player-hp p)
          (cons item (player-backpack-items p))))

 (define scenesL
   (hash "first" (scene "First scene"
                        "Welcome to the game"
                        (list (choice "Go down coridoor" "second" '(λ (p) (> (player-hp p) 50)) '(λ (p) p))
                              (choice "Go down coridoor" "second" '(λ (p) (> (player-hp p) 50)) '(λ (p) p)))
                        '(λ (p) p))
         "second" (scene "Second scene"
                         "Welcome to the the lower end of the coridoor. There is a small door."
                         (list (choice "Use a key to open the door" "third" '(λ (p) (if (member "second-scene-coridoor-key" (player-backpack-items p)) #t #f)) '(λ (p) p))
                               (choice "Turn left" "left-coridoor" '(λ (p) #t) '(λ (p) p)))
                        '(λ (p) p))
         "left-coridoor" (scene "Left coridoor"
                                "You see a large room filled with shelves. This must be the shelf storage room."
                                (list (choice "Have a look around" "look-shelf-room" '(λ (p) #t) '(λ (p) p)))
                                '(λ (p) p))
         "look-shelf-room" (scene "Looking around in the shelf room"
                                  "After a few minutes of looking on shelves high or low, you find a small iron key, the sort that unlocks old doors with poor security."
                                  (list (choice "Pick up the key, turn right and go up the coridoor." "second" '(λ (p) p) '(λ (p) (add-to-backpack p "second-scene-coridoor-key"))))
                                  '(λ (p) p))
         "third" (scene "Discovery"
                        "Having found the key and opened the door, you see that it doesn't lead to a room at all, but rather a balcony overlooking a rolling green hills as far as the eye can see."
                        (list (choice "Kill yourself. There is nothing more to do in life. This is the most beauty a human must see. As someone once said, 'See Naples and die!'" #f '(λ (p) #t) '(λ (p) p))
                              (choice "ABC" #f '(λ (p) #t) '(λ (p) p))) '(λ (p) p))))

(define (choice-lists-to-choice-structs l acc)
  (if (not (empty? l))
      (let ([this-choice (car l)])
        (choice-lists-to-choice-structs (cdr l) (cons (choice (car this-choice)
                                                              (cadr this-choice)
                                                              (caddr this-choice)
                                                              (cadddr this-choice)) acc)))
      acc))

(define (slist-to-shash scene-list scene-hash)
  (if (not (empty? scene-list))
      (let ([this-scene (car scene-list)])
        (let ([scene-hash-reference (car this-scene)]
              [scene-title (cadr this-scene)]
              [scene-description (car (cdr (car (cdr this-scene))))]
              [scene-list-of-choice-lists (car (cdr (cdr (car (cdr this-scene)))))]
              [pre-scene-lambda (car (cdr (cdr (cdr (car (cdr this-scene))))))])
          (let ([scene-list-of-choice-structs (choice-lists-to-choice-structs scene-list-of-choice-lists '())])
            (printf "~a~n" scene-list-of-choice-lists)
            (slist-to-shash (cdr scene-list) (hash-set scene-hash scene-hash-reference (scene scene-title
                                                                                              scene-description
                                                                                              scene-list-of-choice-structs
                                                                                              pre-scene-lambda))))))
      scene-hash))

(define (scene-choice-to-list c)
  (list (choice-name c)
        (choice-destination c)
        (choice-requirement c)
        (choice-action c)))

(define (scene-choices-to-list c acc)
  (if (not (empty? c))
      (scene-choices-to-list (cdr c) (cons (scene-choice-to-list (car c)) acc))
      acc))

(define (scene-to-list s)
  ; s is a struct scene
  (let ([my-scene-title (scene-name s)]
        [my-scene-description (scene-description s)]
        [my-scene-choices (scene-choices-to-list (scene-choices s) '())]
        [my-pre-scene-lambda (scene-pre-scene-action s)])
    (list my-scene-title
          my-scene-description
          my-scene-choices
          my-pre-scene-lambda)))

(define (shash-to-slist h i acc)
    (if (not (hash-empty? h))
        (if (not (= i (- (hash-count h) 1))) ; we're not at the end yet
            (shash-to-slist h (+ i 1) (cons (list (hash-iterate-key h i) (scene-to-list (hash-iterate-value h i))) acc))
            (cons (list (hash-iterate-key h i) (scene-to-list (hash-iterate-value h i))) acc))
        #f))

(define (save-scenes h f)
  ; h is a hash of scenes
  (with-output-to-file f
    (lambda () (write (serialize (shash-to-slist h 0 '()))))
    #:exists 'replace))

(define (load-scenes f)
  (slist-to-shash (with-input-from-file f
                    (lambda () (deserialize (read)))) (hash)))

(define (save-player p)
  (with-output-to-file (format "game-player-~a.save" (player-name p))
    (lambda () (write (serialize p)))
    #:exists 'replace))

(define (load-player p)
  (with-input-from-file (format "game-player-~a.save" p)
    (lambda () (deserialize (read)))))

(define items
  (hash "potion" (backpack-item "Some potion"
                                (λ (p)
                                  (player (player-name p)
                                          (+ 7 (player-hp p))
                                          (remove "potion" (player-backpack-items p)))))))

(define (gather-input)
  (let ([in (read-line)])
    (if (string->number in)
        (list 'num (string->number in))
        (list 'cmd in))))

(define (game-over) (displayln "Thanks for playing."))

(define (display-lines lines)
  (if (not (empty? lines))
      (if (string? (car lines))
          (begin (displayln (car lines))
                 (display-lines (cdr lines)))
          #t) #t))
  

(define (handle-command c p desc choices)
  (let ([cmd (string-split (car c))])
    (case (car cmd)
      [("use" "apply") (if (= (length cmd) 2)
                           (if (member (list-ref cmd 1) (player-backpack-items p))
                               `(#t ,((backpack-item-action (hash-ref items (list-ref cmd 1))) p))
                               '(#f "That item wasn't found in the backpack."))
                           '(#f "Wrong number of arguments for 'use' (expected: use <item>)"))]
      [("h" "help" "?") '(#f "This game is made of scenes. Each scene will tell you a bit about where you are and give you a list of choices."
                             "To select a choice, just type the number of the choice you want to select and hit enter."
                             "There are also commands you can use to access your backpack for example."
                             "Available commands are:"
                             "(use|apply) <backpack item> APPLY ITEM FROM BACKPACK TO PLAYER"
                             "(help|h|?) PRINT THIS HELP MENU"
                             "desc VIEW SCENE DESCRIPTION"
                             "(choices|list) LIST SCENE CHOICES"
                             "stats LIST PLAYER STATISTICS AND BACKPACK CONTENTS"
                             "save SAVE THE PLAYER TO FILE")]
      [("desc") `(#f ,desc)]
      [("choices" "list") `(#f ,(display-choices choices 0))]
      [("stats") `(#f ,(format "HP: ~a~nBackpack items: ~a" (player-hp p) (player-backpack-items p)))]
      [("save") (begin (save-player p)
                       `(#f ,(format "Player ~a saved (filename: game-player-~a.save)" (player-name p) (player-name p))))]
      [else '(#f "That command is unknown.")])))
                           
(define (play s p dd? dc?)
  ; when calling (play) inside (and going to anything but the first scene), be sure to apply the pre-scene of where we're going
  (if dd?
      (displayln (scene-description s))
      #t)
  (if dc?
      (display-choices (scene-choices s) 0)
      #t)
  (let ([in (gather-input)])
    (cond [(eq? (car in) 'num)
        (let ((my-choice-num (cadr in))
              (available-choices (scene-choices s)))
          (if (and (>= my-choice-num 0) (< my-choice-num (length available-choices)))
              ; the choice is one of the available choices
              (let
                  ([selection (list-ref available-choices my-choice-num)])
                (if (choice-destination selection)
                    ; if choice-destination is true, the game continues
                    (if ((eval (choice-requirement selection) ns) p)
                        (if (hash-ref scenes (choice-destination selection) #f)
                            (let ([next-scene (hash-ref scenes (choice-destination selection))])
                              (let ([psa (eval (scene-pre-scene-action next-scene) ns)]
                                    [ca (eval (choice-action selection) ns)])
                                (play next-scene
                                    (psa (ca p))
                                    #t #t)))
                            (printf "The scene referred to in scene ~a for the choice '~a', '~a', was not found; check the code.~n" (scene-name s) (choice-name selection) (choice-destination selection)))
                        (begin (displayln "This choice is unavailable due to your stats or items in your backpack.")
                               (play s p #f #t)))
                    ; if choice-destination is false, the game ends
                    (game-over)))
              (begin (print "That isn't a valid choice. Please try again ('h' for help)~n")
               (play s p #f #t))))]
          [(eq? (car in) 'cmd) (let ([o (handle-command (cdr in) p (scene-description s) (scene-choices s))])
                                 (if (car o)
                                     ; handle-command return successful player
                                     (play s (cadr o) #f #t)
                                     ; handle-command returns something else
                                     (begin (display-lines (cdr o))
                                            (play s p #f #f))))])))
  

(define (launch-game)
  (let ([cmd (string-split (read-line))])
    (case (car cmd)
      [("new" "n") (play (hash-ref scenes "first") (player "Gameplayer" 70 (list "book")) #t #t)]
      [("scene-with-new" "swn") (if (hash-ref scenes (cadr cmd) #f)
                                    (play (hash-ref scenes (cadr cmd)  (player "Gameplayer" 70 (list "book")) #t #t))
                                    (begin (printf "The scene ~a does not exist.~n" (cadr cmd))
                                           (launch-game)))]
      [("scene-with-player" "swp") (if (hash-ref scenes (cadr cmd) #f)
                                        (let ([my-p (load-player (car (cdr (cdr cmd))))])
                                            (if my-p
                                                (play (hash-ref scenes (cadr cmd)) my-p #t #t)
                                                (begin
                                                  (printf "There was a problem loading the player from the filename ~a.~n" (car (cdr (cdr cmd))))
                                                  (launch-game))))
                                        (begin (printf "The scene ~a does not exist.~n" (cadr cmd))
                                               (launch-game)))]
      [("h" "help" "?") (begin (display-lines "Available commands:"
                                              "(new|n) START A NEW GAME WITH A FRESH PLAYER"
                                              "(scene-with-new|swn) <scene> LOAD A SCENE WITH A NEW PLAYER"
                                              "(scene-with-player|swp) <scene> <player savefile> LOAD A SCENE WITH A SPECIFIED PLAYER")
                               (launch-game))])))

(insert-scenes scenes-files 0)
(launch-game)

;(play (hash-ref scenes "first") (player "iyra" 70 (list "potion")) #t #t)
;(handle-command (list "use potion") (player "iyra" 70 (list "potion")) (scene-description (hash-ref scenes "first")) (scene-choices (hash-ref scenes "first")))
;(launch-game)