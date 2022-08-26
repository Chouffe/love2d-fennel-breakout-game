(local fennel (require :lib.fennel))

(local config (require :src.config))
(local quads (require :src.assets.quads))
(local util-render (require :src.util.render))

(local paddle-skin-order 
  [:blue :green :red :purple])

(fn previous-paddle-skin [paddle-skin-order current-skin]
  (let [index (lume.find paddle-skin-order current-skin)]
    (if 
      (= index 1) nil
      (. paddle-skin-order (- index 1)))))

(fn next-paddle-skin [paddle-skin-order current-skin]
  (let [index (lume.find paddle-skin-order current-skin)]
    (if 
      (>= index (length paddle-skin-order)) nil
      (. paddle-skin-order (+ index 1)))))

(var state 
  {:debug false
   :paddle {}
   :quads {}
   :assets {}})

(fn draw-title [ {: fonts}]
  (love.graphics.setFont (. fonts :medium))
  (love.graphics.printf "Select your paddle and press Enter" 0 (/ config.VIRTUAL_HEIGHT 3) config.VIRTUAL_WIDTH :center))

(fn draw-paddle [{: paddle : images : quads}]
  (let [{: size-type : skin} paddle 
        atlas (. images :main)
        quad (. (. quads.paddles skin) size-type)
        (_ _ width height) (: quad :getViewport)
        bottom-margin 40]
    (love.graphics.draw 
      atlas 
      quad 
      ;; Center middle the paddle using its width and height
      (/ (- config.VIRTUAL_WIDTH width) 2) 
      (- config.VIRTUAL_HEIGHT height bottom-margin))))
  
(fn draw-arrows [{ : images : quads : current-paddle-skin}]
  (let [atlas (. images :arrows)
        left-quad (. quads.arrows :left)
        right-quad (. quads.arrows :right)
        (_ _ width height) (: left-quad :getViewport)
        bottom-margin 40
        side-margin 75
        next-skin (next-paddle-skin paddle-skin-order current-paddle-skin)
        previous-skin (previous-paddle-skin paddle-skin-order current-paddle-skin)
        [r g b a] [0.3 0.3 0.3 0.8]]
    (if (not previous-skin)
     (love.graphics.setColor r g b a)
     (love.graphics.setColor 1 1 1 1))
    (love.graphics.draw 
      atlas 
      left-quad 
      ;; Center middle the paddle using its width and height
      side-margin
      (- config.VIRTUAL_HEIGHT height bottom-margin))
    (if (not next-skin)
     (love.graphics.setColor r g b a)
     (love.graphics.setColor 1 1 1 1))
    (love.graphics.draw 
      atlas 
      right-quad 
      ;; Center middle the paddle using its width and height
      (- config.VIRTUAL_WIDTH width side-margin)
      (- config.VIRTUAL_HEIGHT height bottom-margin))))

(fn draw []
  (util-render.draw-background-image (. state.assets :images))
  (draw-title 
    {:fonts state.assets.fonts})
  (draw-paddle 
    {:images (. state.assets :images)
     :paddle (. state :paddle)
     :quads (. state :quads)})
  (draw-arrows 
    {:images (. state.assets :images)
     :quads (. state :quads)
     :current-paddle-skin (. state.paddle :skin)})
  (when (. state :debug)
    (util-render.draw-fps state.assets.fonts.small)))

(fn activate [{: assets : quads : paddle : level-number}]
  (let [default-paddle {:skin :blue :size-type :medium}
        default-level-number 1
        initial-state {: assets : quads : paddle 
                       :level-number (or level-number default-level-number)
                       :paddle (or paddle default-paddle)}]
    (set state initial-state)))

(fn keypressed [key set-mode]
  (if 
    ;; Quit
    (= key :escape)
    (love.event.quit)

    (or (= key :enter) 
        (= key :return))
    (do
      (state.assets.sounds.confirm:play)
      (set-mode :serve {:level-number state.level-number
                        :assets state.assets
                        :quads state.quads
                        :paddle state.paddle}))

    ;; TODO: add the sound effect
    (= key "right")
    (let [new-skin (next-paddle-skin paddle-skin-order state.paddle.skin)]
      (if new-skin
        (do
          (state.assets.sounds.select:play)
          (set state.paddle.skin new-skin))
        (state.assets.sounds.no-select:play)))
    

    ;; TODO: add the sound effect
    (= key "left")
    (let [new-skin (previous-paddle-skin paddle-skin-order state.paddle.skin)]
      (if new-skin
        (do
          (state.assets.sounds.select:play)
          (set state.paddle.skin new-skin))
        (state.assets.sounds.no-select:play)))

    ;; Debug
    (= key "d")
    (do
      (set state.debug (not state.debug))
      (print (fennel.view state)))))

{: draw : activate : keypressed}
