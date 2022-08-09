(fn paddles [atlas]
  (let [[offset-x offset-y] [0 64]
        [small-width small-height] [32 16]
        [small-width small-height] [32 16]
        small (love.graphics.newQuad offset-x offset-y small-width small-height (: atlas :getDimensions))
        medium true
        large true
        x-large true]
    {:blue {:small small}}))

(comment

  (let [atlas (love.graphics.newImage "assets/images/breakout.png")
        quads (paddles atlas)
        quad (. quads.blue :small)]
    (love.graphics.draw atlas quad 5 5)
    quads
    (. quads.blue :small)))

{: paddles}
