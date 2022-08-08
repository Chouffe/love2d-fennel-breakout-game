(local fennel (require :lib.fennel))
(local repl (require :lib.stdio))
(local assets (require :src.assets))
(local push (require :lib.push))
(local config (require :src.config))

(var (mode mode-name) nil)

(comment
  _G

   ;; REPL for changing modes and threading data
  (set-mode :intro)
  (set-mode :start {:assets (assets.load-assets)}))

(fn set-mode [new-mode-name ...]
  (let [modes-path :src.modes.]
    (set (mode mode-name) (values (require (.. modes-path new-mode-name)) new-mode-name))
    (when mode.activate
      (match (pcall mode.activate ...)
        (false msg) (print mode-name "activate error" msg)))))

(fn love.load [args]
  (love.graphics.setDefaultFilter "nearest" "nearest")
  (push:setupScreen 
    config.VIRTUAL_WIDTH 
    config.VIRTUAL_HEIGHT 
    config.WINDOW_WIDTH 
    config.WINDOW_HEIGHT
    {:vsync true
     :fullscreen false
     :resizable true})
  (let [loaded-assets (assets.load-assets)]
    (set-mode :start {:assets loaded-assets}))
  (when (~= :web (. args 1)) (repl.start)))

(fn safely [f]
  (xpcall f #(set-mode :error mode-name $ (fennel.traceback))))

(fn love.draw []
  (push:apply "start")
  (when (and (= "table" (type mode)) mode.update)
    (safely mode.draw))
  (push:apply "end"))

(fn love.resize [w h]
  (push:resize w h))

(fn love.update [dt]
  (when (and (= "table" (type mode)) mode.update)
    (safely #(mode.update dt set-mode))))

(fn love.keypressed [key]
  (if (and (love.keyboard.isDown "lctrl" "rctrl" "capslock") 
           (= key "q"))
      (love.event.quit)
      ;; add what each keypress should do in each mode
      (safely #(mode.keypressed key set-mode))))
