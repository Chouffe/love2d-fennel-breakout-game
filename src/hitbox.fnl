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

;; `pos` is a table with the following keys {: x : y : dx : dy : width : height}
;; Calling this function only works when there is a detected collision between
;; pos1 and pos2
(fn impact-details [{:pos1 pos1 :pos2 pos2 : dt}]
  (let [;; Move back some time ago pos1
        number-time-steps 10
        previous-pos1 {:x (- pos1.x (* number-time-steps dt pos1.dx)) 
                       :y (- pos1.y (* number-time-steps dt pos1.dy)) 
                       :dx pos1.dx 
                       :dy pos1.dy
                       :width pos1.width 
                       :height pos1.height} 
        previous-pos2 {:x (- pos2.x (* number-time-steps dt pos2.dx)) 
                       :y (- pos2.y (* number-time-steps dt pos2.dy)) 
                       :dx pos2.dx 
                       :dy pos2.dy
                       :width pos2.width 
                       :height pos2.height}

        [previous-left1 previous-top1 previous-right1 previous-bottom1] 
        [(coords.left previous-pos1) 
         (coords.top previous-pos1) 
         (coords.right previous-pos1) 
         (coords.bottom previous-pos1)]

        [previous-left2 previous-top2 previous-right2 previous-bottom2] 
        [(coords.left previous-pos2) 
         (coords.top previous-pos2) 
         (coords.right previous-pos2) 
         (coords.bottom previous-pos2)]]

    (if 
      (< previous-bottom1 previous-top2) {:impact-entity-1 :bottom :imapct-entity-2 :top}
      (> previous-top1 previous-bottom2) {:impact-entity-1 :top :impact-entity-2 :bottom}
      (< previous-right1 previous-left2) {:impact-entity-1 :right :impact-entity-2 :left}
      (< previous-left1 previous-right2) {:impact-entity-1 :left :impact-entity-2 :right}
      :undefined)))

(comment

  (impact-details
    {:pos1 {:x 0 :y 0 :width 1 :height 1 :dx 1 :dy 0}
     :pos2 {:x 1 :y 0 :width 1 :height 1 :dx 0 :dy 0}
     :dt 0.01})

  (impact-details
    {:pos1 {:x 0 :y 0 :width 1 :height 1 :dx 0 :dy 1}
     :pos2 {:x 0 :y 1 :width 1 :height 1 :dx 0 :dy 0}
     :dt 0.01})

  (impact-details
    {:pos1 {:x 0 :y 1 :width 1 :height 1 :dx -1 :dy 0}
     :pos2 {:x 0 :y 0 :width 1 :height 1 :dx 0 :dy 0}
     :dt 0.01})

  (impact-details
    {:pos1 {:x 0 :y 1 :width 1 :height 1 :dx 0 :dy -1}
     :pos2 {:x 0 :y 0 :width 1 :height 1 :dx 0 :dy 0}
     :dt 0.01}))


{: collides : impact-details}
