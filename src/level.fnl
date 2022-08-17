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
    {:cell-type :brick :color :green :tier 4}]])

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

(comment 
  (. [1 2 3] 1))

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
              y (+ y0 (* brick-height (- y-index 1)))]
          (draw-cell 
            cell 
            {: x0 : y0 : x-index : y-index : images  
             :quads loaded-quads}))))))
          ; (print (fennel.view [x-index y-index]))
          ; (print (fennel.view [x y]))
          ; (print (fennel.view cell)))))

{: draw-level}
