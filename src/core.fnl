(local fennel (require :lib.fennel))
(local lume (require :lib.lume))
(local push (require :lib.push))
(local repl (require :lib.stdio))

(local assets (require :src.assets))
(local config (require :src.config))

(var (mode mode-name) nil)

(fn set-mode [new-mode-name ...]
  (let [modes-path :src.modes.
        mode-path (.. modes-path new-mode-name)]
    (set (mode mode-name) (values (require (.. modes-path new-mode-name)) new-mode-name))
    (when mode.activate
      (match (pcall mode.activate ...)
        (false msg) (print mode-name "activate error" msg)))))

(fn live-reload-mode [mode-name loaded-assets]
  (let [mode-path (.. :src.modes. mode-name)
        args {:assets loaded-assets}]
    (lume.hotswap mode-path)
    ;; TODO: add all files that could have changed
    (lume.hotswap :src.quads)
    (set-mode mode-name args)))

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
  (print (.. ">>> key pressed: " key))

  (if 
    (and (love.keyboard.isDown "lctrl" "rctrl" "capslock") (= key "q"))
    (love.event.quit)

    ;; Hot reload the current mode using a shortcut
    (= key "r")
    (let [loaded-assets (assets.load-assets)]
      (live-reload-mode mode-name loaded-assets))

    ;; add what each keypress should do in each mode
    (safely #(mode.keypressed key set-mode))))


(comment 
  ;; REPL driven for hot reloading a mode
  ;; 1. First evaluate the whole buffer
  ;; 2. Evaluate the s-expression below
  (let [mode-name :play
  ;; 3. Iterate quickly on the draw function or update logic
        loaded-assets (assets.load-assets)]
    (live-reload-mode mode-name loaded-assets)))

