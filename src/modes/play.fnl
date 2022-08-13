(local fennel (require :lib.fennel))

(local config (require :src.config))
(local debug (require :src.debug))
(local quads (require :src.quads))
(local hitbox (require :src.hitbox))

(local paddle-color-order 
  [:blue :green :red :purple])

(global state 
  {:debug true
   :paused false
   :ball {:skin :blue
          :position {:x 80 :y 80 :dx 200 :dy -100}}
   :paddle {:skin :blue
            :speed 200
            :size-type :medium}
   :quads {}
   :assets {}})

(global sp state)

(comment
  _G
  (. _G :sp)

  ;; Moving the paddle
  (let [paddle (. _G.sp :paddle)
        new-position {:x (+ paddle.position.x 100)
                      :y paddle.position.y}]
    (set _G.sp.paddle.position new-position))

  (let [atlas (. _G.sp.assets.images :main)]
    (quads.paddles atlas)
    (: atlas :getWidth)
    (: atlas :getHeight))
  ;; Change debug rendering
  (set sp.debug false)
  (set sp.debug true))

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

(comment
  (+ 1 2))

;; TODO: move this to the paddle namespace
(fn paddle-dimensions [{: paddle : quads}]
  (let [{: size-type : skin : position } paddle 
        quad (. (. quads.paddles skin) size-type)
        (_ _ width height) (: quad :getViewport)]
    {:width width :height height}))

(fn ball-dimensions [{: ball : quads}]
  {:width 8 :height 8})

(fn draw-paddle [{: paddle : images : quads}]
  (let [{: size-type : skin : position} paddle 
        {: x : y} position
        {: width : height} (paddle-dimensions {:paddle paddle :quads quads})
        atlas (. images :main)
        quad (. (. quads.paddles skin) size-type)]
    (love.graphics.draw atlas quad x y)))

(fn draw-ball [{: ball : images : quads}]
  (let [{: skin : position} ball 
        {: x : y} position
        {: width : height} (ball-dimensions {:ball ball :quads quads})
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

(fn update-paddle [{: dt}]
  (let [{: paddle : quads} state
        {: speed : position} paddle
        {: width} (paddle-dimensions {:paddle paddle :quads quads})
        {: x} position
        key (if 
              (love.keyboard.isDown :left) :left
              (love.keyboard.isDown :right) :right
              nil)
        new-x (-> (handle-keyboard {:speed speed :x x :dt dt :key key})
                  ;; Make sure the paddle stays in the window at all time
                  (lume.clamp 0 (- config.VIRTUAL_WIDTH width)))]
    (set state.paddle.position.x new-x)))

(fn detect-collisions [{: ball : paddle : quads}]
  (let [paddle-dim (paddle-dimensions {:paddle paddle :quads quads})
        ball-dim (ball-dimensions {:ball ball :quads quads})
        data {:paddle-dim paddle-dim :ball-dim ball-dim :ball ball :paddle paddle :quads quads}
        collisions []]
    ;; TODO: should we also handle the collision with the paddle and walls?
    (when (<= ball.position.x 0)
      (table.insert collisions {:collision-type :wall-left :data data}))
    (when (>= ball.position.x (- config.VIRTUAL_WIDTH ball-dim.width))
      (table.insert collisions {:collision-type :wall-right :data data}))
    (when (<= ball.position.y 0)
      (table.insert collisions {:collision-type :wall-top :data data}))
    (when (hitbox.collides 
            {:x paddle.position.x 
             :y paddle.position.y 
             :width paddle-dim.width 
             :height paddle-dim.height}
            {:x ball.position.x 
             :y ball.position.y 
             :width ball-dim.width 
             :height ball-dim.height})
      (table.insert collisions {:collision-type :paddle :data data}))
    collisions))

(fn handle-collision [{: collision-type : data}]
  (let [wall-margin 1
        paddle-margin 1]
    (if
      (= :wall-top collision-type) 
      {:ball {:position {:x data.ball.position.x 
                         :y wall-margin 
                         :dx data.ball.position.dx 
                         :dy (- 0 data.ball.position.dy)}}})))

(comment
  (lume.first []))

(fn update-ball [{: dt : collisions : data-resolved-collisions}]
  (let [{: ball : paddle} state
        {: position} ball
        {: x : y : dx : dy} (if data-resolved-collisions data-resolved-collisions.ball.position position)
        ; {: x : y : dx : dy} position
        new-x (+ x (* dx dt)) 
        new-y (+ y (* dy dt)) 
        ;; TODO: Collision detection with wall
        new-position {:x new-x :y new-y :dx dx :dy dy}]
    (set state.ball.position new-position)))

(fn update-ball-2 [{: dt : collisions}]
  (let [{: ball : quads : paddle} state
        {: position} ball
        {: width : height} (ball-dimensions {:ball ball :quads quads})
        {: x : y : dx : dy} position
        pad-dim (paddle-dimensions {:paddle paddle :quads quads})
        wall-margin 1
        paddle-margin 1
        new-x (+ x (* dx dt)) 
        new-y (+ y (* dy dt)) 
        ;; Collision detection with wall
        new-dx (if 
                 (<= new-x wall-margin) 
                 (- 0 dx) 

                 (>= new-x (- config.VIRTUAL_WIDTH width wall-margin))
                 (- 0 dx)

                 dx) 
        is-paddle-collision (hitbox.collides 
                              {:x state.paddle.position.x :y state.paddle.position.y :width pad-dim.width :height pad-dim.height}
                              {:x x :y y :width width :height height})
        new-dy (if 
                 (<= new-y wall-margin) 
                 (- 0 dy) 

                 is-paddle-collision 
                 (- 0 dy)

                 dy)
        clamped-new-x (lume.clamp new-x wall-margin (- config.VIRTUAL_WIDTH width))
        clamped-new-y (lume.clamp new-y wall-margin (if is-paddle-collision 
                                                      (- config.VIRTUAL_HEIGHT height pad-dim.height paddle-margin) 
                                                      (+ config.VIRTUAL_HEIGHT height wall-margin)))
        new-position {:x clamped-new-x :y clamped-new-y :dx new-dx :dy new-dy}]
    (set state.ball.position new-position)))


(fn update [dt]
  (let [{: ball : paddle : quads} state
        collisions (detect-collisions {:ball ball :paddle paddle :quads quads})
        data-resolved-collisions (lume.first (lume.map collisions handle-collision))]
    (when (> (length collisions) 0)
      (print ">>> collisions: " (fennel.view collisions))
      (print ">>> data-resolved-collisions " (fennel.view data-resolved-collisions)))
    (update-ball {: dt : collisions : data-resolved-collisions})
    (update-paddle {: dt})))

(comment
  ;; For flushing REPL
  (+ 1 2))

(fn activate [{: assets : quads : paddle}]
  (set state.quads quads)
  (set state.assets assets)
  ;; Updating paddle entity
  (let [{: width : height} (paddle-dimensions {:paddle paddle :quads quads})
        default-paddle-speed 200
        default-paddle-position {:x (/ (- config.VIRTUAL_WIDTH width) 2) 
                                 :y (- config.VIRTUAL_HEIGHT height)}]
    (set state.paddle paddle)
    (set state.paddle.position default-paddle-position)
    (set state.paddle.speed default-paddle-speed)))

(comment
  (+ 1 2))

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
