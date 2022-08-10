(local fennel (require :lib.fennel))
(local repl (require :lib.stdio))
(local assets (require :src.assets))
(local push (require :lib.push))
(local config (require :src.config))
(local lume (require :lib.lume))

;; Non REPL driven dev
; (var (mode mode-name) nil)

;; For REPL dev
(global mode nil)
(global modename nil)

(comment
  _G

  (let [modes-path :src.modes
        mode-path (.. modes-path :start)
        set-mode (fn set-mode [new-mode-name ...]
                   (let [modes-path :src.modes.
                         mode-path (.. modes-path new-mode-name)]
                     (lume.hotswap mode-path)
                     (global mode (require mode-path))
                     (global modename new-mode-name)
                     (when mode.activate
                       (match (pcall mode.activate ...)
                         (false msg) (print modename "activate error" msg)))))
        assets (require :src.assets)
        loaded-assets (assets.load-assets)
        mode-name :start 
        args {:assets loaded-assets}]
    (lume.hotswap mode-path)
    (set-mode :start args)
    (set-mode mode-name args)
    loaded-assets)

  ;; Live reload from the REPL 
  (let [set-mode (fn set-mode [new-mode-name ...]
                   (let [modes-path :src.modes.
                         mode-path (.. modes-path new-mode-name)]
                     (lume.hotswap mode-path)
                     (global mode (require mode-path))
                     (global modename new-mode-name)
                     (when mode.activate
                       (match (pcall mode.activate ...)
                         (false msg) (print modename "activate error" msg)))))
        assets (require :src.assets)
        loaded-assets (assets.load-assets)
        mode-name :start 
        args {:assets loaded-assets}]
    (set-mode :start args)
    (set-mode mode-name args)
    loaded-assets))

;; REPL driven dev
(fn set-mode [new-mode-name ...]
  (let [modes-path :src.modes.
        mode-path (.. modes-path new-mode-name)]
    (lume.hotswap mode-path)
    (global mode (require (.. modes-path new-mode-name)))
    (global modename new-mode-name)
    (when mode.activate
      (match (pcall mode.activate ...)
        (false msg) (print modename "activate error" msg)))))

(global setmode set-mode)

(fn live-reload-mode [mode-name loaded-assets]
  (let [mode-name (. _G :modename)
        args {:assets loaded-assets}]
    (set-mode mode-name args)))

;; Non REPL driven dev
; (fn set-mode [new-mode-name ...]
;   (let [modes-path :src.modes.]
;     (set (mode mode-name) (values (require (.. modes-path new-mode-name)) new-mode-name))
;     (when mode.activate
;       (match (pcall mode.activate ...)
;         (false msg) (print mode-name "activate error" msg)))))

; ;; For REPL dev
; (global sm set-mode)

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

;; REPL Driven dev
(fn safely [f]
  (xpcall f #(set-mode :error modename $ (fennel.traceback))))

;; Non REPL Driven dev
; (fn safely [f]
;   (xpcall f #(set-mode :error mode-name $ (fennel.traceback))))

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

    (= key "r")
    (let [loaded-assets (assets.load-assets)]
      (live-reload-mode (. _G :modename) loaded-assets))

    ;; add what each keypress should do in each mode
    (safely #(mode.keypressed key set-mode))))

; (print (fennel.view {:hello-world "hello" :hello_word "hello"}))

; (global hello-world "hello")
; (global hello+world "hello")
; (global hello_world "hello")
; (global helloworld "hello")
