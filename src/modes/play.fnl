(local fennel (require :lib.fennel))
(local lume (require :lib.lume))

(local config (require :src.config))
(local debug (require :src.debug))
(local entity (require :src.entity))
(local quads (require :src.quads))
(local hitbox (require :src.hitbox))
(local level (require :src.level))

(local paddle-color-order 
  [:blue :green :red :purple])

;; TODO: change to var when done developping
(global state 
  {:debug true
   :paused false
   :level 1
   :level-number 1
   :indexed-bricks {}
   :bricks []
   :ball {:skin :blue
          :position {:x 80 :y 80 :dx -200 :dy -100}}
   :paddle {:skin :blue
            :speed 200
            :size-type :medium}
   :quads {}
   :assets {}})

(fn draw-background-image [images]
  (let [background-image (. images :background)
        (width height) (background-image:getDimensions)]
    (love.graphics.draw 
      background-image 
      ;; Draw at coordinates 0 0
      0 0 
      ;; No rotation
      0 
      ;; Scale factors on X and Y axis so that it fits the whole screen
      (/ config.VIRTUAL_WIDTH (- width 1)) 
      (/ config.VIRTUAL_HEIGHT (- height 1)))))

(fn draw-paddle [{: paddle : images : quads}]
  (let [{: size-type : skin : position} paddle 
        {: x : y} position
        {: width : height} (entity.paddle-dimensions {:paddle paddle :quads quads})
        atlas (. images :main)
        quad (. (. quads.paddles skin) size-type)]
    (love.graphics.draw atlas quad x y)))

(fn draw-ball [{: ball : images : quads}]
  (let [{: skin : position} ball 
        {: x : y} position
        {: width : height} (entity.ball-dimensions {:ball ball :quads quads})
        atlas (. images :main)
        quad (. quads.balls skin)]
    (love.graphics.draw atlas quad x y)))
  
(fn draw-pause [fonts]
  (love.graphics.setFont (. fonts :large))
  (love.graphics.printf "Game paused" 0 (/ config.VIRTUAL_HEIGHT 3) config.VIRTUAL_WIDTH :center)
  (love.graphics.setFont (. fonts :medium))
  (love.graphics.printf "Press p to resume" 0 (+ (/ config.VIRTUAL_HEIGHT 3) 35) config.VIRTUAL_WIDTH :center))

(fn draw-brick [{: images : quads : brick}]
  (let [{: visible? : position : width : height : color : tier} brick
        {: x : y} position
        quad (. (. quads.bricks color) tier)
        atlas (. images :main)]
    (when visible?
      (love.graphics.draw atlas quad x y))))

(fn draw-bricks [{: images : quads : bricks}]
  (each [_ brick (pairs bricks)]
    (draw-brick {: brick : images : quads}))) 

(fn draw []
  (let [images (. state.assets :images)
        fonts (. state.assets :fonts)
        quads (. state :quads)]
    ;; Draw all elements in the scene
    (draw-background-image images)
    (draw-bricks {:bricks (. state :bricks) : quads : images}) 
    (draw-paddle {:paddle (. state :paddle) : images : quads})
    (draw-ball {:ball (. state :ball) : images : quads}) 
    (when state.paused
      (draw-pause fonts))
    (when (. state :debug)
      (debug.display-fps (. fonts :small)))))

;; TODO: move to a paddle namespace?
(fn handle-keyboard [{: x : speed : dt : key}]
  (if 
    (= key :left)
    (- x (* speed dt))

    (= key :right)
    (+ x (* speed dt))

    x))

(fn update-paddle [{: dt : resolved-collisions}]
  (let [{: paddle : quads} state
        {: speed : position} paddle
        {: x} (if resolved-collisions resolved-collisions.position position)
        key (if 
              (love.keyboard.isDown :left) :left
              (love.keyboard.isDown :right) :right
              nil)]
    (set state.paddle.position.x (handle-keyboard {:speed speed :x x :dt dt :key key}))))

(fn detect-collisions [{: bricks : ball : paddle : quads}]
  (let [paddle-dim (entity.paddle-dimensions {:paddle paddle :quads quads})
        ball-dim (entity.ball-dimensions {:ball ball :quads quads})
        data {:paddle-dim paddle-dim :ball-dim ball-dim :ball ball :paddle paddle :quads quads}
        collisions []]
    ;; Paddle collision with walls
    (when (<= paddle.position.x 0)
      (table.insert collisions {:collision-type :paddle-wall-left :data data}))
    (when (>= paddle.position.x (- config.VIRTUAL_WIDTH paddle-dim.width))
      (table.insert collisions {:collision-type :paddle-wall-right :data data}))
    ;; Ball collision with walls
    (when (<= ball.position.x 0)
      (table.insert collisions {:collision-type :ball-wall-left :data data}))
    (when (>= ball.position.x (- config.VIRTUAL_WIDTH ball-dim.width))
      (table.insert collisions {:collision-type :ball-wall-right :data data}))
    (when (<= ball.position.y 0)
      (table.insert collisions {:collision-type :ball-wall-top :data data}))
    (when (>= ball.position.y config.VIRTUAL_HEIGHT)
      (table.insert collisions {:collision-type :ball-wall-bottom :data data}))
    ;; Ball collision with entities
    ;; TODO
    (each [_ brick (pairs bricks)]
      (when brick.visible?
        (when (hitbox.collides 
                {:x brick.position.x 
                 :y brick.position.y 
                 :width brick.width
                 :height brick.height}
                {:x ball.position.x 
                 :y ball.position.y 
                 :width ball-dim.width 
                 :height ball-dim.height})
          (table.insert collisions {:collision-type :ball-brick :data data}))))
    ;; Ball collision with paddle
    (when (hitbox.collides 
            {:x paddle.position.x 
             :y paddle.position.y 
             :width paddle-dim.width 
             :height paddle-dim.height}
            {:x ball.position.x 
             :y ball.position.y 
             :width ball-dim.width 
             :height ball-dim.height})
      (table.insert collisions {:collision-type :ball-paddle :data data}))
    collisions))

(fn handle-collision [{: collision-type : data}]
  (let [wall-margin 1
        paddle-ball-margin 1]
    (if
      ;; Paddle
      (= :paddle-wall-left collision-type)
      {:paddle {:position {:x 0
                           :y data.paddle.position.y}}}

      (= :paddle-wall-right collision-type)
      {:paddle {:position {:x (- config.VIRTUAL_WIDTH data.paddle-dim.width)
                           :y data.paddle.position.y}}}

      ;; TODO: Brick
      ;; Should we use event names like hit and then process them?
      (= collision-type :brick)
      (let [new-tier (- data.brick.tier 1)
            visible? (<= 0 new-tier)]
        {:brick {:visible? visible?
                 :tier (if visible? new-tier data.brick.tier)
                 :entity-id data.brick.entity-id}})

      ;; Ball
      (= :ball-paddle collision-type)
      {:ball {:position {:x data.ball.position.x 
                         :y (- config.VIRTUAL_HEIGHT data.paddle-dim.height data.ball-dim.height paddle-ball-margin)
                         :dx data.ball.position.dx 
                         :dy (- 0 data.ball.position.dy)}}}

      (= :ball-wall-top collision-type) 
      {:ball {:position {:x data.ball.position.x 
                         :y wall-margin 
                         :dx data.ball.position.dx 
                         :dy (- 0 data.ball.position.dy)}}}

      (= :ball-wall-right collision-type) 
      {:ball {:position {:x (- config.VIRTUAL_WIDTH data.ball-dim.width wall-margin)
                         :y data.ball.position.y
                         :dx (- 0 data.ball.position.dx) 
                         :dy data.ball.position.dy}}}

      (= :ball-wall-left collision-type) 
      {:ball {:position {:x wall-margin
                         :y data.ball.position.y
                         :dx (- 0 data.ball.position.dx) 
                         :dy data.ball.position.dy}}}

      (= :ball-wall-bottom collision-type) 
      {:ball-lost true})))

(fn update-brick [{: dt : collisions : resolved-collisions}]
  (let [{: bricks : ball} state]
    ;; TODO
    42))
    ;; TODO: hit brick function that triggers
    ; (print "updating brick")))
    

(fn update-ball [{: dt : collisions : data-resolved-collisions : resolved-collisions}]
  (let [{: ball : paddle} state
        {: position} ball
        {: x : y : dx : dy} (if resolved-collisions resolved-collisions.position position)
        new-x (+ x (* dx dt)) 
        new-y (+ y (* dy dt)) 
        new-position {:x new-x :y new-y :dx dx :dy dy}]
    (set state.ball.position new-position)))

(fn game-over? [{: resolved-collisions}]
  (?. resolved-collisions :ball-lost))

(fn update [dt set-mode]
  (let [{: ball : paddle : quads : bricks} state
        collisions (detect-collisions {: ball : paddle : quads : bricks})
        resolved-collisions (-> collisions
                                (lume.map handle-collision)
                                (lume.reduce lume.merge {}))]
    (if (game-over? {: resolved-collisions})
      ;; TODO: Make a game over mode here
      (do
        42)
        ; (print (fennel.view state))
        ; (set-mode :select-paddle {:assets (. state :assets)}))
      (do
        (update-brick {: dt : collisions :resolved-collisions (?. resolved-collisions :brick)})
        (update-ball {: dt : collisions :resolved-collisions (?. resolved-collisions :ball)})
        (update-paddle {: dt :resolved-collisions (?. resolved-collisions :paddle)})))))

(comment
  ;; For flushing REPL
  (+ 1 2))

(fn add-entity-id! [entity]
  (let [entity-id (lume.uuid)]
    (when (= :table (type entity))
      (set entity.id entity-id)
      entity)))

(fn index-by [key coll]
  (lume.reduce coll 
               (fn [acc x]
                 (let [k (. x key)]
                   (lume.merge acc {k x})))
               {}))

(comment
  (lume.merge {:a 1} {:b 2})
  (index-by :id [{:id "haha" :val :hello} {:id "bebe" :val "foobar"}])
  (-> (lume.reduce [{:id "haha" :val :hello} {:id "bebe" :val "foobar"}] 
                   (fn [acc x]
                     (let [id (. x :id)]
                       (print (pp acc))
                       (lume.merge acc {id x})))
                   {})))
                    

(fn activate [{: level-number : assets : quads : paddle}]
  (set state.quads quads)
  (set state.assets assets)
  ;; Set the initial level
  (let [{: entities} (level.level-number->level-data level-number)]
    (each [_ entity (pairs entities)]
      (add-entity-id! entity))
    (set state.level-number level-number)
    (set state.bricks entities))
  ;; Updating paddle entity
  (let [{: width : height} (entity.paddle-dimensions {:paddle paddle :quads quads})
        default-paddle-speed 200
        default-paddle-position {:x (/ (- config.VIRTUAL_WIDTH width) 2) 
                                 :y (- config.VIRTUAL_HEIGHT height)}]
    (set state.paddle paddle)
    (set state.paddle.position default-paddle-position)
    (set state.paddle.speed default-paddle-speed)))

(fn keypressed [key set-mode]
  (if 
    ;; Quit
    (= key :escape)
    (love.event.quit)

    ;; Pause
    (= key "p")
    (do
      (: (. state.assets.sounds :pause) :play)
      (set state.paused (not state.paused)))

    ;; Debug
    (= key "d")
    (do
      (set state.debug (not state.debug))
      (print (fennel.view state)))))

{: draw 
 : update 
 : activate 
 : keypressed}
