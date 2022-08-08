(fn display-fps [font]
  (love.graphics.setFont font)
  (love.graphics.setColor 0 1 0 1)
  (let [fps (love.timer.getFPS)]
    (love.graphics.print 
      (.. "FPS: " (tostring fps)) 
      ;; Draw at (5, 5) from top left
      5 5)))

{: display-fps}
