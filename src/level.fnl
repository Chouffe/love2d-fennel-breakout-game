(local fennel (require :lib.fennel))
(local lume (require :lib.lume))
(local config (require :src.config))

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
         :position {: x : y}
         :visible? true
         : color 
         : tier 
         :width cell-width 
         :height cell-height}))))

;; TODO: find a way to do it functionally instead
(fn level-number->level-data [level]
  (let [matrix level-matrix-1
        [x0 y0] [30 40]
        entities []]
    (each [y-index v (pairs matrix)]
      (each [x-index cell (pairs v)]
        (let [entity (cell->entity cell { : x0 : y0 : x-index : y-index})]
          (when (= :table (type entity))
            (table.insert entities entity))))) 
    {: matrix : entities : x0 : y0}))

(comment 
  (level-number->level-data 1))

{: level-number->level-data}
