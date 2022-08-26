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
  {:debug false
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
    (let [;; Needs to sit on the paddle
          paddle-dim (entity.paddle-dimensions {:paddle paddle :quads quads})
          ball-dim (entity.ball-dimensions {:ball {} : quads})
          initial-ball (add-entity-id! 
                         {:entity-type :ball 
                          :skin :blue 
                          :position {:x (/ (- config.VIRTUAL_WIDTH ball-dim.width) 2) 
                                     :y (- config.VIRTUAL_HEIGHT paddle-dim.height ball-dim.height 1) 
                                     :dx -80
                                     :dy -50}})]
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

    (or (= key :enter) 
        (= key :return) 
        (= key :space))
    (set-mode :play {:level-number state.level-number
                     :assets state.assets
                     :entities state.entities
                     :quads state.quads
                     :paddle state.paddle})

    ;; Debug
    (= key "d")
    (do
      (set state.debug (not state.debug))
      (print (fennel.view state)))))

{: draw : activate : keypressed}
