(local fennel (require :lib.fennel))
(local lume (require :lib.lume))
(local config (require :src.config))
(local util (require :src.util))

;; TODO: remove
(local assets (require :src.assets))
(local quads (require :src.quads))

(local level-matrix-data
  [[{:cell-type :brick :color :blue :tier 1} 
    {:cell-type :brick :color :blue :tier 2} 
    {:cell-type :void}
    {:cell-type :brick :color :blue :tier 3} 
    {:cell-type :brick :color :blue :tier 4}]
   [{:cell-type :brick :color :green :tier 1} 
    {:cell-type :brick :color :green :tier 2} 
    {:cell-type :brick :color :green :tier 3} 
    {:cell-type :void}
    {:cell-type :brick :color :green :tier 4}]
   [{:cell-type :brick :color :red :tier 1} 
    {:cell-type :void}
    {:cell-type :brick :color :red :tier 2} 
    {:cell-type :brick :color :red :tier 3} 
    {:cell-type :brick :color :red :tier 4}]
   [{:cell-type :brick :color :yellow :tier 1} 
    {:cell-type :void}
    {:cell-type :brick :color :yellow :tier 2} 
    {:cell-type :brick :color :yellow :tier 3} 
    {:cell-type :brick :color :yellow :tier 4}]
   [{:cell-type :brick :color :purple :tier 1} 
    {:cell-type :void}
    {:cell-type :brick :color :purple :tier 2} 
    {:cell-type :brick :color :purple :tier 3} 
    {:cell-type :brick :color :purple :tier 4}]])

(fn cell->entity 
  [cell {: x0  : y0 : x-index : y-index}]
  (let [{: cell-type} cell
        [cell-width cell-height] [32 16]
        [cell-spacing-x cell-spacing-y] [5 10]
        x (+ x0 
             (* cell-width (- x-index 1)) 
             (* cell-spacing-x (- x-index 1)))
        y (+ y0 
             (* cell-height (- y-index 1))
             (* cell-spacing-y (- y-index 1)))]
    (if (= cell-type :brick)
      (let [{: color : tier} cell]
        {:entity-type :brick : x : y : color : tier :width cell-width :height cell-height}))))

(comment
  (let [x-index 3
        y-index 2
        cell (. level-matrix-data y-index x-index)
        entity (cell->entity cell {:x0 0 :y0 0 : x-index : y-index})]
    entity))

(fn draw-cell-entity
  [entity {: images : quads}]
  (when (= :table (type entity))
    (let [{: entity-type : x : y : width : height} entity]
      (if (= entity-type :brick)
        (let [{: color : tier} entity
              quad (. (. quads.bricks color) tier)
              atlas (. images :main)]
          (love.graphics.draw atlas quad x y))))))

(comment
  (let [loaded-assets (assets.load-assets)
        images (. loaded-assets :images)
        loaded-quads (quads.load-quads images)
        x-index 3
        y-index 2
        cell (. level-matrix-data y-index x-index)
        entity (cell->entity cell {:x0 0 :y0 0 : x-index : y-index})]
    entity
    (draw-cell-entity nil { : images :quads loaded-quads})))
    ; (draw-cell-entity entity { : images :quads loaded-quads})))

(fn draw-cell 
  [cell {: x0  : y0 : x-index : y-index : images : quads}]
  (let [{: cell-type} cell
        [cell-width cell-height] [32 16]
        [cell-spacing-x cell-spacing-y] [5 10]
        x (+ x0 
             (* cell-width (- x-index 1)) 
             (* cell-spacing-x (- x-index 1)))
        y (+ y0 
             (* cell-height (- y-index 1))
             (* cell-spacing-y (- y-index 1)))]
    (if (= cell-type :brick)
      (let [{: color : tier} cell
            quad (. (. quads.bricks color) tier)
            atlas (. images :main)]
        (love.graphics.draw atlas quad x y)))))

(fn draw-level []
  (let [loaded-assets (assets.load-assets)
        images (. loaded-assets :images)
        loaded-quads (quads.load-quads images)
        horizontal-spacing 5
        vertical-spacing 10
        brick-width 32
        brick-height 16
        padding-top 20
        padding-bottom 50
        padding-left 15
        padding-right 15
        x0 padding-left
        y0 padding-top
        height (- config.VIRTUAL_HEIGHT padding-top padding-bottom)
        width (- config.VIRTUAL_WIDTH padding-left padding-right)
        rows (length level-matrix-data)
        columns (length (lume.first level-matrix-data))]
    [rows columns]
    (each [y-index v (pairs level-matrix-data)]
      (each [x-index cell (pairs v)]
        (let [x (+ x0 (* brick-width (- x-index 1)))
              y (+ y0 (* brick-height (- y-index 1)))
              entity (cell->entity cell { : x0 : y0 : x-index : y-index})]
          (draw-cell-entity 
            entity 
            { : images :quads loaded-quads}))))))

{: draw-level}
