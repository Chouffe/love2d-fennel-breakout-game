(local fennel (require :lib.fennel))
(local lume (require :lib.lume))
(local config (require :src.config))
(local util (require :src.util))

;; TODO: add other level-matrices
(local level-matrix-1
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

;; TODO: implement multiple levels here
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
        {:entity-type :brick 
         : x : y : color : tier 
         :width cell-width 
         :height cell-height}))))

;; TODO: find a way to do it functionally instead
(fn level->level-data [level]
  (let [matrix level-matrix-1
        [x0 y0] [30 40]
        entities []]
    (each [y-index v (pairs matrix)]
      (each [x-index cell (pairs v)]
        ;; TODO: this should not be done here but in the load function in play
        (let [entity-id (lume.uuid)
              entity (cell->entity cell { : x0 : y0 : x-index : y-index})]
          (when (= :table (type entity))
            (set entity.id entity-id)
            (table.insert entities entity))))) 
    {: matrix : entities : x0 : y0}))

(comment 
  (level->level-data 1))

(fn draw-cell-entity
  [entity {: images : quads}]
  (when (= :table (type entity))
    (let [{: entity-type : x : y : width : height} entity]
      (if (= entity-type :brick)
        (let [{: color : tier} entity
              quad (. (. quads.bricks color) tier)
              atlas (. images :main)]
          (love.graphics.draw atlas quad x y))))))

(fn draw-level [{: level : images : quads}]
  (let [{: entities} (level->level-data level)]
    (each [_ entity (pairs entities)]
      (draw-cell-entity entity { : images : quads}))))

;; TODO: remove the draw level from here
{: draw-level 
 : draw-cell-entity 
 : level->level-data}
