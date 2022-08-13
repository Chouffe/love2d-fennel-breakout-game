(local fennel (require :lib.fennel))

(local config (require :src.config))
(local debug (require :src.debug))
(local entity (require :src.entity))
(local quads (require :src.quads))
(local hitbox (require :src.hitbox))

(local paddle-color-order 
  [:blue :green :red :purple])

;; TODO: change to var when done developping
(global state 
  {:debug true
   :paused false
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

(fn draw []
  (draw-background-image (. state.assets :images))
  (when state.paused
    (draw-pause (. state.assets :fonts)))
  (draw-paddle {:images (. state.assets :images)
                :paddle (. state :paddle)
                :quads (. state :quads)})
  (draw-ball {:images (. state.assets :images)
              :ball (. state :ball)
              :quads (. state :quads)})
  (when (. state :debug)
    (debug.display-fps state.assets.fonts.small)))

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

(fn detect-collisions [{: ball : paddle : quads}]
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

(fn update-ball [{: dt : collisions : data-resolved-collisions : resolved-collisions}]
  (let [{: ball : paddle} state
        {: position} ball
        {: x : y : dx : dy} (if resolved-collisions resolved-collisions.position position)
        new-x (+ x (* dx dt)) 
        new-y (+ y (* dy dt)) 
        new-position {:x new-x :y new-y :dx dx :dy dy}]
    (set state.ball.position new-position)))

(fn is-game-done [{: resolved-collisions}]
  (?. resolved-collisions :ball-lost))

(fn update [dt]
  (let [{: ball : paddle : quads} state
        collisions (detect-collisions {:ball ball :paddle paddle :quads quads})
        resolved-collisions (-> collisions
                                (lume.map handle-collision)
                                (lume.reduce lume.merge {}))
        game-over (is-game-done {: resolved-collisions})]
    (if (is-game-done {: resolved-collisions})
      ;; TODO: activate new mode here
      (print "Game game over!")
      (do
       (update-ball {: dt : collisions :resolved-collisions (?. resolved-collisions :ball)})
       (update-paddle {: dt :resolved-collisions (?. resolved-collisions :paddle)})))))

(comment
  ;; For flushing REPL
  (+ 1 2))

(fn activate [{: assets : quads : paddle}]
  (set state.quads quads)
  (set state.assets assets)
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

{: draw : update : activate : keypressed}
