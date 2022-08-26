(local fennel (require :lib.fennel))
(local lume (require :lib.lume))
(local push (require :lib.push))
(local repl (require :lib.stdio))
(local clj (require :cljlib))
(import-macros cljm :cljlib)

(local assets (require :src.assets.core))
(local quads (require :src.assets.quads))
(local config (require :src.config))
(local modes (require :src.modes.core))

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
  (let [loaded-assets (assets.load-assets)
        loaded-quads (quads.load-quads loaded-assets.images)]
    (print loaded-quads)
    (modes.set-mode :start {:assets loaded-assets :quads loaded-quads}))
  (when (~= :web (. args 1)) (repl.start)))

(fn safely [f]
  (xpcall f #(modes.set-mode :error {:old-mode :start :msg $ :traceback (fennel.traceback)})))

(fn love.draw []
  (push:apply "start")
  (let [mode (modes.get-mode)]
    (when (and (= "table" (type mode)) mode.draw)
      (safely mode.draw)))
  (push:apply "end"))

(fn love.resize [w h]
  (push:resize w h))

(fn love.update [dt]
  (let [mode (modes.get-mode)]
    (when (and (= "table" (type mode)) mode.update)
      (safely #(mode.update dt modes.set-mode)))))

(fn love.keypressed [key]
  (print (.. ">>> key pressed: " key))

  (if 
    (and (love.keyboard.isDown "lctrl" "rctrl" "capslock") (= key "q"))
    (love.event.quit)

    ;; Hot reload the current mode using a shortcut
    (= key "r")
    (let [mode-name (modes.get-mode-name)
          args (modes.mode-name->default-args mode-name)]
      (print (fennel.view args))
      (modes.live-reload-mode mode-name args))

    ;; add what each keypress should do in each mode
    (let [mode (modes.get-mode)]
      (safely #(mode.keypressed key modes.set-mode)))))

(fn love.keyreleased [key]
  (print (.. ">>> key released " key))

  ;; add what each keyreleased should do in each mode
  (let [mode (modes.get-mode)]
    (when mode.keyreleased
      (safely #(mode.keyreleased key modes.set-mode)))))

(comment 
  ;; REPL driven for hot reloading a mode
  ;; 1. First evaluate the whole buffer
  ;; 2. Evaluate the s-expression below
  ;; 3. Iterate quickly on the draw function or update logic
  (let [mode-name :play
        args (modes.mode-name->default-args mode-name)]
    (modes.live-reload-mode mode-name args)))
