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

(fn balls [atlas]
  (-> [{:skin :blue :offset [96 48]}
       {:skin :green :offset [104 48]}
       {:skin :red :offset [120 48]}]
      (lume.map (fn [{: skin : offset}]
                  (let [[x y] offset]
                    {skin (love.graphics.newQuad x y 8 8 (: atlas :getDimensions))})))
      (lume.reduce lume.merge)))

(comment
  (let [assets (require :src.assets) 
        loaded-assets (assets.load-assets)
        loaded-balls (balls (. loaded-assets.images :main))]
    loaded-assets
    loaded-balls))

(fn arrows [atlas]
  {:left (love.graphics.newQuad 0 0 24 24 (: atlas :getDimensions))
   :right (love.graphics.newQuad 24 0 24 24 (: atlas :getDimensions))})

(fn load-quads [images]
  {:balls (balls (. images :main))
   :paddles (paddles (. images :main))
   :arrows (arrows (. images :arrows))})

(comment
  (let [assets (require :src.assets) 
        loaded-assets (assets.load-assets)
        loaded-quads (load-quads (. loaded-assets :images))]
    loaded-quads)

  (let [
        ; atlas (love.graphics.newImage "assets/images/breakout.png")
        atlas (love.graphics.newImage "assets/images/arrows.png")
        ; quads (paddles atlas)
        quads (arrows atlas)]
        ; quad (. quads.blue :small)
        ; (w h) (: quads.blue.small :getTextureDimensions)]
    ; (love.graphics.draw atlas quad 5 5)
    quads
    (: (. quads :left) :getViewport)))
    ; (lume.map quads (fn [quad] (: quad :getViewport)))))
    ; (. quads.blue :small)
    ; (: quads.blue.small :getTextureDimensions)
    ; [w h]))

{: load-quads}
