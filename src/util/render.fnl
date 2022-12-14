(local config (require :src.config))

(fn draw-black-overlay []
  (love.graphics.setColor 0 0 0 0.7)
  (love.graphics.rectangle :fill 0 0 config.VIRTUAL_WIDTH config.VIRTUAL_HEIGHT 0 0 0)
  (love.graphics.setColor 1 1 1 1))

(fn draw-pause [fonts]
  (draw-black-overlay)
  (love.graphics.setFont (. fonts :large))
  (love.graphics.printf "Game paused" 0 (/ config.VIRTUAL_HEIGHT 3) config.VIRTUAL_WIDTH :center)
  (love.graphics.setFont (. fonts :medium))
  (love.graphics.printf "Press p to resume" 0 (+ (/ config.VIRTUAL_HEIGHT 3) 35) config.VIRTUAL_WIDTH :center))

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
      (/ config.VIRTUAL_HEIGHT (- height 1)))))

(fn draw-fps [font]
  (love.graphics.setFont font)
  (love.graphics.setColor 0 1 0 1)
  (let [fps (love.timer.getFPS)]
    (love.graphics.print 
      (.. "FPS: " (tostring fps)) 
      ;; Draw at (5, 5) from top left
      5 5)))

(fn draw-level-number [{: fonts : level-number}]
  (love.graphics.setFont (. fonts :small))
  (love.graphics.printf (.. "Level " (tostring level-number)) 5 5 config.VIRTUAL_WIDTH :left))

{: draw-pause 
 : draw-fps 
 : draw-background-image 
 : draw-level-number 
 : draw-black-overlay}
