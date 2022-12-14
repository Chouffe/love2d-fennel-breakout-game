;; This mode has two purposes:
;; * display the stack trace that caused the error
;; * allow the user to decide whether to retry after reloading or quit

;; Since we can't know which module needs to be reloaded, we rely on the user
;; doing a ,reload foo in the repl.

(var state {})

(local explanation "Press `escape` to quit.
Press `space` to return to the previous mode after reloading in the repl.
Press `t` to display the stacktrace.")

(fn draw []
  (love.graphics.print explanation 15 25)
  (love.graphics.clear 0.34 0.61 0.86)
  (love.graphics.setColor 0.9 0.9 0.9)
  (let [small-font (love.graphics.newFont 9)
        medium-font (love.graphics.newFont 11)]
    (love.graphics.setFont (if state.trace small-font medium-font))
    (if (not state.trace)
      (love.graphics.print explanation 15 25)
      (do
        (love.graphics.print state.msg 10 10)
        (love.graphics.print state.traceback 15 70)))))

(fn keypressed [key set-mode]
  (match key
    :t (set state.trace (not state.trace))
    :escape (love.event.quit)
    :space (set-mode state.old-mode)))

(fn activate [{: old-mode : msg : traceback}]
  (print msg)
  (print traceback)
  (let [initial-state {:trace false : old-mode : msg : traceback}]
    (set state initial-state)))

{: draw : keypressed : activate}
