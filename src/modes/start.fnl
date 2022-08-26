(local config (require :src.config))
(local util-render (require :src.util.render))

(var state 
  {:highlighted :play
   :quads {}
   :assets {}})

(fn draw-title [fonts]
  (love.graphics.setFont (. fonts :large))
  (love.graphics.printf "BREAKOUT" 0 (/ config.VIRTUAL_HEIGHT 3) config.VIRTUAL_WIDTH :center))

(fn draw-menu [fonts highlighted]
  (let [selected-color {:r (/ 103 255) :g 1 :b 1 :a 1}]
    (love.graphics.setFont (. fonts :medium))

    (when (= :play highlighted)
      (love.graphics.setColor 
        (. selected-color :r) 
        (. selected-color :g) 
        (. selected-color :b) 
        (. selected-color :a))) 
    (love.graphics.printf 
      "START" 
      0 
      (+ (/ config.VIRTUAL_HEIGHT 2) 70) 
      config.VIRTUAL_WIDTH 
      :center)

    ;; reset color
    (love.graphics.setColor 1 1 1 1)

    (when (= :high-scores highlighted)
      (love.graphics.setColor 
        (. selected-color :r) 
        (. selected-color :g) 
        (. selected-color :b) 
        (. selected-color :a))) 
    (love.graphics.printf 
      "HIGH SCORES" 
      0 
      (+ (/ config.VIRTUAL_HEIGHT 2) 90) 
      config.VIRTUAL_WIDTH 
      :center)

    ;; reset color
    (love.graphics.setColor 1 1 1 1)))
  
(fn draw []
  (util-render.draw-background-image (. state.assets :images))
  (draw-title (. state.assets :fonts))
  (draw-menu (. state.assets :fonts) (. state :highlighted))
  (when (. state :debug)
    (util-render.draw-fps state.assets.fonts.small)))

(fn activate [{: assets : quads}]
  (let [initial-state {: quads : assets :highlighted :play}]
    (set state initial-state))
  (assets.sounds.music:setLooping true)
  (assets.sounds.music:play))

(fn keypressed [key set-mode]
  (if 
    (= key :escape)
    (love.event.quit)

    (or (= key :enter) (= key :return))
    (set-mode :select-paddle {:assets state.assets :quads state.quads})

    (= key :up)
    (do
      (: (. state.assets.sounds :paddle-hit) :play)
      (set state.highlighted :play))

    (= key :down)
    (do
      (: (. state.assets.sounds :paddle-hit) :play)
      (set state.highlighted :high-scores))))

{: draw : activate : keypressed}
