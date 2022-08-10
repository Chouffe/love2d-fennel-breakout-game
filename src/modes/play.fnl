(local fennel (require :lib.fennel))

(local config (require :src.config))
(local debug (require :src.debug))
(local quads (require :src.quads))

(var state 
  {:debug true
   :paused false
   :paddle {:skin :blue
            ; :size-type :medium
            :size-type :x-large}
            
   :quads {}
   :assets {}})

(global sp state)

(comment
  _G
  (. _G :sp)

  (let [atlas (. _G.sp.assets.images :main)]
    (quads.paddles atlas)
    (: atlas :getWidth)
    (: atlas :getHeight))
  ;; Change debug rendering
  (set sp.debug false)
  (set sp.debug true))

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
  
(fn draw-arrows [{ : images : quads}]
  (let [atlas (. images :arrows)
        left-quad (. quads.arrows :left)
        right-quad (. quads.arrows :right)
        (_ _ width height) (: left-quad :getViewport)
        bottom-margin 40
        side-margin 75]
    (love.graphics.draw 
      atlas 
      left-quad 
      ;; Center middle the paddle using its width and height
      side-margin
      (- config.VIRTUAL_HEIGHT height bottom-margin))
    (love.graphics.draw 
      atlas 
      right-quad 
      ;; Center middle the paddle using its width and height
      (- config.VIRTUAL_WIDTH width side-margin)
      (- config.VIRTUAL_HEIGHT height bottom-margin))))

(comment
  (+ 1 2))

(fn draw-pause [fonts]
  (love.graphics.setFont (. fonts :large))
  (love.graphics.printf "Game paused" 0 (/ config.VIRTUAL_HEIGHT 3) config.VIRTUAL_WIDTH :center)
  (love.graphics.setFont (. fonts :medium))
  (love.graphics.printf "Press p to resume" 0 (+ (/ config.VIRTUAL_HEIGHT 3) 35) config.VIRTUAL_WIDTH :center))

(fn draw []
  (draw-background-image (. state.assets :images))
  (when state.paused
    (draw-pause (. state.assets :fonts)))
  (draw-paddle {:images (. state.assets :images)
                :paddle (. state :paddle)
                :quads (. state :quads)})
  (draw-arrows {:images (. state.assets :images)
                :quads (. state :quads)})
  (when (. state :debug)
    (debug.display-fps state.assets.fonts.small)))

(fn update [dt set-mode])

(fn activate [{: assets}]
  (let [atlas (. assets.images :main)
        loaded-quads {:arrows (quads.arrows (. assets.images :arrows))
                      :paddles (quads.paddles (. assets.images :main))}]
    (set state.quads loaded-quads))
  (set state.assets assets))

(fn keypressed [key set-mode]
  (if 
    ;; Quit
    (= key :escape)
    (love.event.quit)

    ;; Pause
    (= key "p")
    (do
      (: (. state.assets.sounds :pause) :play)
      (set state.paused (not state.paused)))

    ;; Debug
    (= key "d")
    (do
      (set state.debug (not state.debug))
      (print (fennel.view state)))))

{: draw : update : activate : keypressed}
