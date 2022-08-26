(local fennel (require :lib.fennel))
(local lume (require :lib.lume))

(local config (require :src.config))
(local entity (require :src.entity.core))
(local entity-render (require :src.entity.render))
(local quads (require :src.assets.quads))
(local hitbox (require :src.hitbox))
(local level (require :src.level.core))
(local util-coll (require :src.util.coll))
(local util-render (require :src.util.render))
(local game-logic (require :src.game-logic.core))

(var state 
  {:debug false
   :paused? false
   :balls-left 1
   :level-number 1
   :entities {:indexed-bricks {} 
              :indexed-balls {} 
              :indexed-paddles {}}
   :quads {}
   :assets {}})

(fn draw []
  (let [
        {: assets : quads : level-number} state 
        {: images : fonts} assets]
    ;; Draw all elements in the scene
    (util-render.draw-background-image images)
    (entity-render.draw-entities {: images : quads :entities state.entities})
    (util-render.draw-level-number {: fonts : level-number})
    (when state.paused?
      (util-render.draw-pause fonts))
    (when (. state :debug)
      (util-render.draw-fps (. fonts :small)))))

;; TODO: move to a paddle namespace?
(fn handle-keyboard [{: x : speed : dt : key}]
  (if 
    (= key :left)
    (- x (* speed dt))

    (= key :right)
    (+ x (* speed dt))

    x))

(fn update-paddle [{: paddle : dt : resolved-collisions}]
  (let [{: quads} state
        {: speed : position} paddle
        {: x} (if resolved-collisions resolved-collisions.position position)
        new-x (+ x (* dt (or position.dx 0)))]
    (set paddle.position.x new-x)))
    ; (set paddle.position.x (handle-keyboard {:speed speed :x x :dt dt :key key}))))

(fn detect-collisions [{: bricks : ball : paddle : quads : dt}]
  (let [paddle-dim (entity.paddle-dimensions {:paddle paddle :quads quads})
        ball-dim (entity.ball-dimensions {:ball ball :quads quads})
        brick-dim (entity.brick-dimensions {:brick {} : quads})
        ;; TODO: dimensions should live on entities not here
        data {:paddle-dim paddle-dim 
              :ball-dim ball-dim 
              :brick-dim brick-dim 
              :ball ball 
              :paddle paddle 
              :quads quads}
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

    (each [_ brick (pairs bricks)]
      (when (not brick.invisible?)
        (let [pos1 {:x ball.position.x 
                    :y ball.position.y 
                    :dx ball.position.dx
                    :dy ball.position.dy
                    :width ball-dim.width 
                    :height ball-dim.height}
              pos2 {:x brick.position.x 
                    :y brick.position.y 
                    :dx 0
                    :dy 0
                    :width brick.width
                    :height brick.height}]
          (when (hitbox.collides pos1 pos2)
            (let [impact-details (hitbox.impact-details {: pos1 : pos2 : dt})
                  collision-data (lume.merge data {:brick brick
                                                   :ball-impact impact-details.impact-entity-1
                                                   :brick-impact impact-details.impact-entity-2})]
              (table.insert collisions {:collision-type :ball-brick :data collision-data}))))))

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

      (= collision-type :ball-brick)
      (let [new-tier (- data.brick.tier 1)
            invisible? (<= new-tier 0)
            new-ball-position (match data.ball-impact
                                :top {:x data.ball.position.x
                                      :y (+ 1 data.brick.position.y data.brick-dim.height)
                                      :dx data.ball.position.dx
                                      :dy (- 0 data.ball.position.dy)}
                                :bottom {:x data.ball.position.x
                                         :y (- data.brick.position.y data.ball-dim.height 1)
                                         :dx data.ball.position.dx
                                         :dy (- 0 data.ball.position.dy)}
                                :left {:x (+ 1 data.brick.position.x data.brick-dim.width)
                                       :y data.ball.position.y
                                       :dx (- 0 data.ball.position.dx)
                                       :dy data.ball.position.dy}
                                :right {:x (- data.brick.position.x data.ball-dim.width 1)
                                        :y data.ball.position.y
                                        :dx (- 0 data.ball.position.dx)
                                        :dy data.ball.position.dy}
                                _ data.ball.position)]
        {:ball {:position new-ball-position}
         :brick {:invisible? invisible?
                 :tier (if invisible? data.brick.tier new-tier)
                 :hello :foo
                 :id data.brick.id}})

      ;; Ball
      ;; TODO: restructure to make it possible to have multiple balls
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
      {:ball-lost? true})))

(fn update-bricks [{: indexed-bricks : dt : collisions : resolved-collisions}]
  (when resolved-collisions
    (let [{: invisible? : tier : id} resolved-collisions
          brick (. indexed-bricks id)]
      (when invisible?
        (set brick.invisible? invisible?))
      (set brick.tier tier))))

(fn update-ball [{: ball : dt : collisions : data-resolved-collisions : resolved-collisions}]
  (let [{: position : entity-id} ball
        {: x : y : dx : dy} (if resolved-collisions resolved-collisions.position position)
        new-x (+ x (* dx dt)) 
        new-y (+ y (* dy dt)) 
        new-position {:x new-x :y new-y :dx dx :dy dy}]
    (set ball.position new-position)))

(fn collision-type->sound-effect-name 
  [collision-type]
  (match collision-type
    :ball-wall-left :wall-hit
    :ball-wall-right :wall-hit
    :ball-wall-top :wall-hit
    :ball-wall-bottom :hurt
    :ball-paddle :paddle-hit
    :ball-brick :brick-hit-1
    _ nil))

(fn collisions->sound-effects! [{: sounds : collisions}]
  (each [_ collision (pairs collisions)]
    (let [sound-effect-name (collision-type->sound-effect-name collision.collision-type)]
      (when sound-effect-name
        (: (. sounds sound-effect-name) :play)))))

(fn update-game-state [{: dt : entities : quads}]
  (let [paddle (lume.first (util-coll.vals state.entities.indexed-paddles))
        ball (lume.first (util-coll.vals state.entities.indexed-balls))
        {: indexed-bricks} entities
        bricks (util-coll.vals indexed-bricks)
        collisions (detect-collisions {: ball : paddle : quads : bricks : dt})
        ;; TODO: this should aggregate and not take only the last event
        resolved-collisions (-> collisions
                                (lume.map handle-collision)
                                (lume.reduce lume.merge {}))]
    (collisions->sound-effects! {: collisions :sounds state.assets.sounds})
    (when (. resolved-collisions :ball-lost?)
      (set state.balls-left (- state.balls-left 1)))
    (update-bricks {: indexed-bricks : dt : collisions :resolved-collisions (?. resolved-collisions :brick)})
    (update-ball {: ball : dt : collisions :resolved-collisions (?. resolved-collisions :ball)})
    (update-paddle {: paddle : dt :resolved-collisions (?. resolved-collisions :paddle)})))

(fn update [dt set-mode]
  (let [{: level-number : assets : quads : entities : balls-left : paused?} state]
    (if 
      (game-logic.game-over? {: balls-left})
      (set-mode :game-over {: assets : quads : level-number})

      (game-logic.game-won? {: entities})
      (let [paddle (-> state.entities.indexed-paddles
                       (util-coll.vals)
                       (lume.first))]
        (: assets.sounds.victory :play)
        (set-mode :level-cleared {: quads : paddle : assets : level-number})) 

      (when (not paused?)
        (update-game-state {: entities : quads : dt})))))

(fn activate [{: level-number : assets : quads : entities}]
  (let [initial-state {: quads : assets : entities : level-number
                       :debug false
                       :paused? false
                       :balls-left 1}]
    (set state initial-state)))

(fn keypressed [key set-mode]
  (let [paddle (lume.first (util-coll.vals state.entities.indexed-paddles))]
    (if 
      ;; Quit
      (= key :escape)
      (love.event.quit)

      (= key :left)
      (set paddle.position.dx (- 0 config.GAMEPLAY.DEFAULT_PADDLE_SPEED))

      (= key :right)
      (set paddle.position.dx config.GAMEPLAY.DEFAULT_PADDLE_SPEED)

      ;; Pause
      (= key "p")
      (do
        (if (not state.paused?)
           (love.audio.pause)
           (state.assets.sounds.music:play))
          
        (: (. state.assets.sounds :pause) :play)
        (set state.paused? (not state.paused?)))

      ;; Debug
      (= key "d")
      (do
        (set state.debug (not state.debug))
        (print (fennel.view state))))))

(fn keyreleased [key set-mode]
  (let [paddle (lume.first (util-coll.vals state.entities.indexed-paddles))]
    (if 
      (or (= key :right) (= key :left))
      (set paddle.position.dx 0))))

{: draw : update : activate : keypressed : keyreleased}
