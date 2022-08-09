(local debug (require :src.debug))
(local config (require :src.config))

(var state 
  {:debug true
   :highlighted :play
   :assets {}})

;; Used for poking at it via the REPL
(global si state)

(comment
  ;; Change debug rendering
  (set si.debug false)
  (set si.debug true)

  ;; Change menu selection with the REPL
  (set si.highlighted :high-scores)
  (set si.highlighted :play))

(comment
  (let [image (. si.assets.images :background)
        (width height) (image:getDimensions)]
    [width height]
    (love.graphics.draw image 0 0 0 width height)))

(fn draw-background-image [images]
  (let [background-image (. images :background)
        (width height) (background-image:getDimensions)]
    (love.graphics.draw 
      background-image 
      ;; Draw at coordinates 0 0
      0 0 
      ;; No rotation
      0 
      ;; Scale factors on X and Y axis so that it fits the whole screen
      (/ config.VIRTUAL_WIDTH (- width 1)) 
      (/ config.VIRTUAL_HEIGHT (- height 1)))))

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
  (draw-background-image (. state.assets :images))
  (draw-title (. state.assets :fonts))
  (draw-menu (. state.assets :fonts) (. state :highlighted))
  (when (. state :debug)
    (debug.display-fps state.assets.fonts.small)))

(fn update [dt set-mode])

(fn activate [{: assets}]
  (assets.sounds.music:setLooping true)
  (assets.sounds.music:play)
  (set state.assets assets))

(fn keypressed [key set-mode]
  (if 
    (= key :escape)
    (love.event.quit)

    (or (= key :enter) (= key :return))
    (set-mode :play {:assets state.assets})

    (= key :up)
    (do
      (: (. state.assets.sounds :paddle-hit) :play)
      (set state.highlighted :play))

    (= key :down)
    (do
      (: (. state.assets.sounds :paddle-hit) :play)
      (set state.highlighted :high-scores))))

{: draw : update : activate : keypressed}
