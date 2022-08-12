(local fennel (require :lib.fennel))

(local config (require :src.config))
(local debug (require :src.debug))
(local quads (require :src.quads))

(local paddle-color-order 
  [:blue :green :red :purple])

(var state 
  {:debug true
   :paused false
   :ball {:skin :blue
          :position {:x 80 :y 80 :dx 30 :dy 50}}
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

(fn update [dt set-mode]
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
