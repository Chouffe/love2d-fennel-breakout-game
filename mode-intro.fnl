(import-macros {: incf} :sample-macros)

(var counter 0)
(var time 0)

(comment
   counter)


(local (major minor revision) (love.getVersion))

(comment

   ;; Getting the global variables for changing modes via the REPL
   _G
   (. _G :sm)
   (. _G :modename)

   ;; REPL for changing modes and threading data
   (let [set-mode (. _G :sm)]
      (set-mode :mode-two {:font-size 50}))

   (let [set-mode (. _G :sm)]
      (set-mode :mode-intro)))

{:draw (fn draw [message]
         (local (w h _flags) (love.window.getMode))
         (love.graphics.printf
          (: "Love Version: %s.%s.%s"
             :format  major minor revision) 0 10 w :center)
         (love.graphics.printf
          (: "This Window should close in %0.1f seconds"
             :format (math.max 0 (- 3 time)))
          0 (- (/ h 2) 15) w :center))
 :update (fn update [dt set-mode]
             (if (< counter 65535)
                 (set counter (+ counter 1))
                 (set counter 0))
             (incf time dt))
             ; (when (> time 3)
             ;   (love.event.quit)))
 :activate (fn activate [_] 
              (love.graphics.setNewFont 30)
              (print "Activating"))
 :keypressed (fn keypressed [key set-mode]
                (global sm set-mode)
                (when (= key :escape) 
                   (love.event.quit)))}
