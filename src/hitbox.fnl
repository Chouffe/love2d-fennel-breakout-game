(local coords (require :src.coords))

;; pos is a table with the following keys {: x : y : width : height}
(fn collides [pos1 pos2]
  (let [[left1 top1 right1 bottom1] [(coords.left pos1) 
                                     (coords.top pos1) 
                                     (coords.right pos1) 
                                     (coords.bottom pos1)]
        [left2 top2 right2 bottom2] [(coords.left pos2) 
                                     (coords.top pos2) 
                                     (coords.right pos2) 
                                     (coords.bottom pos2)]]
    (and (< left1 right2)
         (> right1 left2)
         (< top1 bottom2)
         (> bottom1 top2))))

{: collides}
