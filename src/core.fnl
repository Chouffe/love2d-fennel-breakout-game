(local fennel (require :lib.fennel))
(local lume (require :lib.lume))
(local push (require :lib.push))
(local repl (require :lib.stdio))

(local assets (require :src.assets))
(local quads (require :src.quads))
(local config (require :src.config))

(var (mode mode-name) nil)

(fn set-mode [new-mode-name args]
  (let [modes-path :src.modes.
        mode-path (.. modes-path new-mode-name)]
    (set (mode mode-name) (values (require (.. modes-path new-mode-name)) new-mode-name))
    (when mode.activate
      (match (pcall mode.activate args)
        (false msg) (print mode-name "activate error" msg)))))

(+ 1 2)
(fn live-reload-mode [mode-name args]
  (let [mode-path (.. :src.modes. mode-name)]
    (lume.hotswap mode-path)
    ;; TODO: add all files that could have changed
    (lume.hotswap :src.quads)
    (lume.hotswap :src.assets)
    (set-mode mode-name args)))

(fn mode-name->default-args [mode-name]
  (let [loaded-assets (assets.load-assets)
        loaded-quads (quads.load-quads (. loaded-assets :images))]
    (if
      (= mode-name :play)
      (let [default-paddle {:skin :blue :size-type :medium}]
        {:assets loaded-assets
         :quads loaded-quads
         :paddle default-paddle})
    
      (= mode-name :select-paddle)
      {:assets loaded-assets
       :quads loaded-quads}

      (= mode-name :start)
      {:assets loaded-assets
       :quads loaded-quads}
      
      {})))

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
    (let [args (mode-name->default-args mode-name)]
      (print (fennel.view args))
      (live-reload-mode mode-name args))

    ;; add what each keypress should do in each mode
    (safely #(mode.keypressed key set-mode))))


(+ 1 2)

(comment 
  ;; REPL driven for hot reloading a mode
  ;; 1. First evaluate the whole buffer
  ;; 2. Evaluate the s-expression below
  ;; 3. Iterate quickly on the draw function or update logic
  (let [mode-name :play
        args (mode-name->default-args mode-name)]
    (live-reload-mode mode-name args)))
