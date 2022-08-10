(local fennel (require :lib.fennel))

(local debug (require :src.debug))
(local config (require :src.config))
(local quads (require :src.quads))

(var state 
  {:debug true
   :paddle {:skin :purple
            :size-type :medium}
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
        bottom-margin 20]
    (love.graphics.draw 
      atlas 
      quad 
      ;; Center middle the paddle using its width and height
      (/ (- config.VIRTUAL_WIDTH width) 2) 
      (- config.VIRTUAL_HEIGHT height bottom-margin))))
  
(fn draw-arrows [images])

(fn draw []
  ; (let [atlas (. state.assets.images :main)
  ;       quad (. state.quads.blue :small)]
  ;   ;; TODO: figure out how to draw a quad here
  ;   (love.graphics.draw atlas quad 5 5)
  ;   (love.graphics.draw atlas 5 5 0 (: atlas :getWidth) (: atlas :getHeight)))
  (draw-background-image (. state.assets :images))
  (draw-paddle {:images (. state.assets :images)
                :paddle (. state :paddle)
                :quads (. state :quads)})
  ; (draw-arrows (. state.assets :images))
  (when (. state :debug)
    (debug.display-fps state.assets.fonts.small)))

(fn update [dt set-mode])

(fn activate [{: assets}]
  (let [atlas (. assets.images :main)
        loaded-quads {:paddles (quads.paddles atlas)}]
    (set state.quads loaded-quads))
  (set state.assets assets))

(fn keypressed [key set-mode]
  (if 
    ;; Debugging
    (= key "s")
    (fennel.view state)

    (= key :escape)
    (love.event.quit)))

(comment
  (. _G :sp))

{: draw : update : activate : keypressed}
