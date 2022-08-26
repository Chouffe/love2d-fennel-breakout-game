(local lume (require :lib.lume))
(local util-coll (require :src.util.coll))

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

(fn arrows [atlas]
  {:left (love.graphics.newQuad 0 0 24 24 (: atlas :getDimensions))
   :right (love.graphics.newQuad 24 0 24 24 (: atlas :getDimensions))})

(comment

  (let [assets (require :src.assets) 
        loaded-assets (assets.load-assets)
        loaded-quads (load-quads (. loaded-assets :images))
        atlas (. loaded-assets.images :main)
        (atlas-width atlas-height) (: atlas :getDimensions)]
    loaded-assets
    loaded-quads
    [atlas-width atlas-height]
    (util-coll.range 0 atlas-height 16)
    (util-coll.range 0 atlas-width 32)
    (lume.slice (util-coll.range 0 atlas-width 32) 1 6)))

(comment
  (lume.slice [1 2 3 4 5] 1 3))

(fn bricks [atlas]
  (let [brick-width 32
        brick-height 16
        (atlas-width atlas-height) (: atlas :getDimensions)
        all-quads (-> (util-coll.range 0 (- atlas-height brick-height) brick-height)
                      (lume.map (fn [y]
                                  (-> (util-coll.range 0 (- atlas-width brick-width) brick-width)
                                      (lume.map (fn [x] {:x x :y y})))))
                      (lume.reduce lume.concat [])
                      (lume.map (fn [{: x : y}]
                                  (love.graphics.newQuad x y brick-width brick-height atlas-width atlas-height))))]
    {:blue (lume.map (util-coll.range 1 4 1) (fn [idx] ( . all-quads idx))) 
     :green (lume.map (util-coll.range 5 8 1) (fn [idx] ( . all-quads idx)))
     :red (lume.map (util-coll.range 9 12 1) (fn [idx] ( . all-quads idx)))
     :purple (lume.map (util-coll.range 13 17 1) (fn [idx] ( . all-quads idx)))
     :yellow (lume.map (util-coll.range 17 20 1) (fn [idx] ( . all-quads idx)))}))

(comment
  (let [assets (require :src.assets) 
        loaded-assets (assets.load-assets)
        atlas (. loaded-assets.images :main)]
    (bricks atlas)))
        ;; Returns multiple values


(fn load-quads [images]
  {:balls (balls (. images :main))
   :paddles (paddles (. images :main))
   :bricks (bricks (. images :main))
   :arrows (arrows (. images :arrows))})

(comment

  (let [assets (require :src.assets) 
        loaded-assets (assets.load-assets)
        atlas (. loaded-assets.images :main)
        ;; Returns multiple values
        (w h) (: atlas :getDimensions)]
    [w h])

  (let [
        assets (require :src.assets) 
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

