(local debug (require :src.debug))
(local config (require :src.config))

(var state {:assets {}})

(global si state)

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
  
(fn draw []
  (draw-background-image (. si.assets :images))
  (debug.display-fps state.assets.fonts.small))

(fn update [dt set-mode])

(fn activate [{: assets}]
  (assets.sounds.music:setLooping true)
  (assets.sounds.music:play)
  (set state.assets assets))

(fn keypressed [key set-mode])

{: draw : update : activate : keypressed}
