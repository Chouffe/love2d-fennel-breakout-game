(local lume (require :lib.lume))

(comment
  (->>)
  (lume.reduce [{:a 1} {:b 2}] lume.merge)
  (lume.map [1 2 3] (fn [x] (* x 2)))
  (->> :hello)
  (lume.map [{:skin :blue :offset [0 64]} {:skin :green :offset [0 96]}] (fn [{: skin : offset }] skin)))

(fn skin->paddles [{: atlas : offset : skin}]
  (let [[offset-x offset-y] offset
        [small-width small-height] [32 16]
        [medium-width medium-height] [64 16]
        [large-width large-height] [96 16]
        [x-large-width x-large-height] [128 16]
        small (love.graphics.newQuad offset-x offset-y small-width small-height (: atlas :getDimensions))
        medium (love.graphics.newQuad (+ offset-x 32) offset-y medium-width medium-height (: atlas :getDimensions))
        large (love.graphics.newQuad (+ offset-x 96) offset-y large-width large-height (: atlas :getDimensions))
        x-large (love.graphics.newQuad offset-x (+ offset-y 16) x-large-width x-large-height (: atlas :getDimensions))]
    {:small small
     :medium medium
     :large large
     :x-large x-large}))

(fn paddles [atlas]
  (-> [{:skin :blue :offset [0 64]} 
       {:skin :green :offset [0 96]}
       {:skin :red :offset [0 128]}
       {:skin :purple :offset [0 160]}]
      (lume.map (fn [{: skin : offset}] 
                  {skin (skin->paddles { : atlas : skin : offset})}))
      (lume.reduce lume.merge)))

(comment

  (let [atlas (love.graphics.newImage "assets/images/breakout.png")
        quads (paddles atlas)]
        ; quad (. quads.blue :small)
        ; (w h) (: quads.blue.small :getTextureDimensions)]
    ; (love.graphics.draw atlas quad 5 5)
    quads))
    ; (. quads.blue :small)
    ; (: quads.blue.small :getTextureDimensions)
    ; [w h]))

{: paddles}
