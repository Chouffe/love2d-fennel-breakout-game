(local fennel (require :lib.fennel))

(local config (require :src.config))
(local quads (require :src.assets.quads))
(local util-render (require :src.util.render))

(var state 
  {:debug false
   :level-number 1
   :paddle {}
   :quads {}
   :assets {}})

(fn draw-title [{: fonts : level-number}]
  (love.graphics.setFont (. fonts :medium))
  (love.graphics.printf (.. "You cleared level " (tostring level-number) "!") 0 (/ config.VIRTUAL_HEIGHT 3) config.VIRTUAL_WIDTH :center)
  (love.graphics.printf (.. "Press Enter to continue") 0 (+ (/ config.VIRTUAL_HEIGHT 3) 30) config.VIRTUAL_WIDTH :center))
  
(fn draw []
  (util-render.draw-background-image (. state.assets :images))
  (draw-title 
    {:fonts state.assets.fonts 
     :level-number state.level-number})
  (when (. state :debug)
    (util-render.draw-fps state.assets.fonts.small)))

(fn activate [{: assets : quads : paddle : level-number}]
  (let [initial-state {: quads : paddle : assets : level-number}]
    (set state initial-state)))

(fn keypressed [key set-mode]
  (if 
    ;; Quit
    (= key :escape)
    (love.event.quit)

    (or (= key :enter) (= key :return))
    (set-mode :select-paddle {:level-number (+ state.level-number 1)
                              :paddle state.paddle
                              :assets state.assets
                              :quads state.quads})))

{: draw : activate : keypressed}

