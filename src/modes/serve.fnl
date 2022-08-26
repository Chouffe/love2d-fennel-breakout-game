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

;; TODO: change to var when done developping
(var state 
  {:debug false
   :level-number 1
   :entities {:indexed-bricks {} 
              :indexed-balls {} 
              :indexed-paddles {}}
   :quads {}
   :assets {}})

(fn draw-instructions [{: fonts}]
  (util-render.draw-black-overlay)
  (love.graphics.setFont (. fonts :medium))
  (love.graphics.printf (.. "Press Enter to serve") 0 (/ config.VIRTUAL_HEIGHT 3) config.VIRTUAL_WIDTH :center))

(fn draw []
  (let [{: assets : quads : level-number : entities} state 
        {: images : fonts} assets]
    ;; Draw all elements in the scene
    (util-render.draw-background-image images)
    (entity-render.draw-entities {: images : quads : entities}) 
    (draw-instructions {: fonts})
    (util-render.draw-level-number {: fonts : level-number})
    (when (. state :debug)
      (util-render.draw-fps (. fonts :small)))))

(fn add-entity-id! [entity]
  (let [entity-id (lume.uuid)]
    (when (= :table (type entity))
      (set entity.id entity-id)
      entity)))

(fn initialize-entities [{: level-number : paddle : quads : assets}]
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
                                     :dy -50}})
          default-paddle-speed config.GAMEPLAY.DEFAULT_PADDLE_SPEED
          default-paddle-position {:x (/ (- config.VIRTUAL_WIDTH paddle-dim.width) 2) 
                                   :y (- config.VIRTUAL_HEIGHT paddle-dim.height)}
          initial-paddle (lume.merge paddle {:entity-type :paddle
                                             :position default-paddle-position 
                                             :speed config.GAMEPLAY.DEFAULT_PADDLE_SPEED})
          indexed-paddles (util-coll.index-by :id [(add-entity-id! initial-paddle)])]
      {:indexed-balls (util-coll.index-by :id [initial-ball])
       :indexed-bricks (util-coll.index-by :id brick-entities)
       :indexed-paddles indexed-paddles})))

(fn activate [{: level-number : assets : quads : paddle}]
  (let [entities (initialize-entities {: paddle : quads : assets : level-number})
        initial-state {: quads : assets : level-number : entities}]
    (set state initial-state)))

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
