(local fennel (require :lib.fennel))
(local lume (require :lib.lume))

(local config (require :src.config))
(local debug (require :src.debug))
(local entity (require :src.entity))
(local quads (require :src.quads))
(local hitbox (require :src.hitbox))
(local level (require :src.level))
(local util-coll (require :src.util.coll))

(local paddle-color-order 
  [:blue :green :red :purple])

;; TODO: change to var when done developping
(global state 
  {:debug true
   :paused false
   :balls-left 1
   :level-number 1
   :entities {:indexed-bricks {} 
              :indexed-balls {} 
              :indexed-paddles {}}
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

(fn draw-paddles [{: images : quads : paddles}]
  (each [_ paddle (pairs paddles)]
    (draw-paddle {: paddle : images : quads}))) 

(fn draw-ball [{: ball : images : quads}]
  (let [{: skin : position} ball 
        {: x : y} position
        {: width : height} (entity.ball-dimensions {:ball ball :quads quads})
        atlas (. images :main)
        quad (. quads.balls skin)]
    (love.graphics.draw atlas quad x y)))

(fn draw-balls [{: images : quads : balls}]
  (each [_ ball (pairs balls)]
    (draw-ball {: ball : images : quads}))) 
  
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
    (when (not (?. brick :invisible?))
      (draw-brick {: brick : images : quads})))) 

(fn draw-entities [{: images : quads : entities}]
  (let [bricks (util-coll.vals entities.indexed-bricks)
        paddles (util-coll.vals entities.indexed-paddles)
        balls (util-coll.vals entities.indexed-balls)]
    (draw-bricks {: bricks : quads : images}) 
    (draw-paddles {: paddles : images : quads})
    (draw-balls {: balls : images : quads}))) 

(fn draw []
  (let [images (. state.assets :images)
        fonts (. state.assets :fonts)
        quads (. state :quads)]
    ;; Draw all elements in the scene
    (draw-background-image images)
    (draw-entities {: images : quads :entities state.entities})
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

(fn update-paddle [{: paddle : dt : resolved-collisions}]
  (let [{: quads} state
        {: speed : position} paddle
        {: x} (if resolved-collisions resolved-collisions.position position)
        key (if 
              (love.keyboard.isDown :left) :left
              (love.keyboard.isDown :right) :right
              nil)]
    (set paddle.position.x (handle-keyboard {:speed speed :x x :dt dt :key key}))))

(fn detect-collisions [{: bricks : ball : paddle : quads}]
  (let [paddle-dim (entity.paddle-dimensions {:paddle paddle :quads quads})
        ball-dim (entity.ball-dimensions {:ball ball :quads quads})
        ;; TODO: dimensions should live on entities not here
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

    (each [_ brick (pairs bricks)]
      (when (not brick.invisible?)
        (when (hitbox.collides 
                {:x brick.position.x 
                 :y brick.position.y 
                 :width brick.width
                 :height brick.height}
                {:x ball.position.x 
                 :y ball.position.y 
                 :width ball-dim.width 
                 :height ball-dim.height})
          (let [collision-data (lume.merge data {:brick brick})]
            ;; TODO: add ball bouncing here
            (table.insert collisions {:collision-type :ball-brick :data collision-data})))))

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
            invisible? (<= new-tier 0)]
        {:brick {:invisible? invisible?
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

(fn game-over? [{: balls-left}]
  (<= balls-left 0))

(fn game-won? [{: entities}]
  (-> entities.indexed-bricks
      (util-coll.vals)
      (lume.all (fn [{: invisible?}] invisible?))))

(fn update-game-state [{: dt : entities : quads}]
  (let [paddle (lume.first (util-coll.vals state.entities.indexed-paddles))
        ball (lume.first (util-coll.vals state.entities.indexed-balls))
        {: indexed-bricks} entities
        bricks (util-coll.vals indexed-bricks)
        collisions (detect-collisions {: ball : paddle : quads : bricks})
        ;; TODO: this should aggregate and not take only the last event
        resolved-collisions (-> collisions
                                (lume.map handle-collision)
                                (lume.reduce lume.merge {}))]
    (when (. resolved-collisions :ball-lost?)
      (set state.balls-left (- state.balls-left 1)))
    (update-bricks {: indexed-bricks : dt : collisions :resolved-collisions (?. resolved-collisions :brick)})
    (update-ball {: ball : dt : collisions :resolved-collisions (?. resolved-collisions :ball)})
    (update-paddle {: paddle : dt :resolved-collisions (?. resolved-collisions :paddle)})))

(fn update [dt set-mode]
  (let [{: quads : entities : balls-left} state]
    (if 
      (game-over? {: balls-left})
      (do
        (print (fennel.view state))
        (set-mode :select-paddle {:assets (. state :assets)}))

      (game-won? {: entities})
      (do
        (print "You won the GAME!")
        (print (fennel.view state))
        (set-mode :select-paddle {:assets (. state :assets)}))

      (update-game-state {: entities : quads : dt}))))

(comment
  ;; For flushing REPL
  (+ 1 2))

(fn add-entity-id! [entity]
  (let [entity-id (lume.uuid)]
    (when (= :table (type entity))
      (set entity.id entity-id)
      entity)))

(fn initialize-entities [{: state : level-number : paddle : quads : assets}]
  (let [{: entities} (level.level-number->level-data level-number)
        brick-entities (lume.filter entities (fn [{: entity-type}] (= :brick entity-type)))]
    (each [_ entity (pairs entities)]
      (add-entity-id! entity))

    ;; Start with one ball only
    (let [initial-ball (add-entity-id! 
                         {:entity-type :ball 
                          :skin :blue 
                          :position {:x 80 :y 80 :dx -200 :dy -100}})]
      (set state.entities.indexed-balls (util-coll.index-by :id [initial-ball])))

    ;; Bricks
    (set state.entities.indexed-bricks (util-coll.index-by :id brick-entities))
    (set state.level-number level-number))

  ;; Paddle
  (let [{: width : height} (entity.paddle-dimensions {:paddle paddle :quads quads})
        default-paddle-speed config.GAMEPLAY.DEFAULT_PADDLE_SPEED
        default-paddle-position {:x (/ (- config.VIRTUAL_WIDTH width) 2) 
                                 :y (- config.VIRTUAL_HEIGHT height)}
        initial-paddle (lume.merge paddle {:entity-type :paddle
                                           :position default-paddle-position 
                                           :speed config.GAMEPLAY.DEFAULT_PADDLE_SPEED})
        indexed-paddles (util-coll.index-by :id [(add-entity-id! initial-paddle)])]
    (set state.entities.indexed-paddles indexed-paddles)))

(fn activate [{: level-number : assets : quads : paddle}]
  (set state.quads quads)
  (set state.assets assets)
  (initialize-entities {: state : paddle : quads : assets : level-number}))

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
