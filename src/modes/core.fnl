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
        {:level 1
         :level-number 1
         :assets loaded-assets
         :quads loaded-quads
         :paddle default-paddle})
    
      (= mode-name :select-paddle)
      {:assets loaded-assets
       :quads loaded-quads}

      (= mode-name :start)
      {:assets loaded-assets
       :quads loaded-quads}
      
      {})))

(fn get-mode-name []
  mode-name)

(fn get-mode []
  mode)

{: set-mode
 : get-mode
 : get-mode-name
 : mode-name->default-args
 : live-reload-mode}
 
