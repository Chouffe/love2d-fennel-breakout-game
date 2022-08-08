(local fennel (require :lib.fennel))
(local repl (require :lib.stdio))

(local canvas 
  (let [(w h) (love.window.getMode)]
    (love.graphics.newCanvas w h)))

(var scale 1)

(var (mode mode-name) nil)

(comment
  _G

   ;; REPL for changing modes and threading data
  (set-mode :intro)
  (set-mode :two {:font-size 10}))

(fn set-mode [new-mode-name ...]
  (let [modes-path :src.modes.]
    (set (mode mode-name) (values (require (.. modes-path new-mode-name)) new-mode-name))

    ;; TODO: remove when needed
    ;; For REPL driven dev
    (global mod mode)
    (global modename mode-name)

    (when mode.activate
      (match (pcall mode.activate ...)
        (false msg) (print mode-name "activate error" msg)))))

(fn love.load [args]
  (set-mode :intro)
  (canvas:setFilter "nearest" "nearest")
  (when (~= :web (. args 1)) (repl.start)))

(fn safely [f]
  (xpcall f #(set-mode :error mode-name $ (fennel.traceback))))

(fn love.draw []
  ;; the canvas allows you to get sharp pixel-art style scaling; if you
  ;; don't want that, just skip that and call mode.draw directly.
  (love.graphics.setCanvas canvas)
  (love.graphics.clear)
  (love.graphics.setColor 1 1 1)
  (when (and (= "table" (type mode)) mode.update)
    (safely mode.draw))
  (love.graphics.setCanvas)
  (love.graphics.setColor 1 1 1)
  (love.graphics.draw canvas 0 0 0 scale scale))

(fn love.update [dt]
  (when (and (= "table" (type mode)) mode.update)
    (safely #(mode.update dt set-mode))))

(fn love.keypressed [key]
  (if (and (love.keyboard.isDown "lctrl" "rctrl" "capslock") 
           (= key "q"))
      (love.event.quit)
      ;; add what each keypress should do in each mode
      (safely #(mode.keypressed key set-mode))))
