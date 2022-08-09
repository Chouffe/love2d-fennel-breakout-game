(local debug (require :src.debug))
(local config (require :src.config))
(local quads (require :src.quads))

(var state 
  {:debug true
   :quads {}
   :assets {}})

(global sp state)

(comment
  _G
  (. _G :sp)
  (. sp :assets)
  (let [atlas (. _G.sp.assets.images :main)]
    (quads.paddles atlas))
  ;; Change debug rendering
  (set sp.debug false)
  (set sp.debug true))

(fn draw []
  (when (. state :debug)
    (debug.display-fps state.assets.fonts.small)))

(fn update [dt set-mode])

(fn activate [{: assets}]
  (set state.assets assets))

(fn keypressed [key set-mode]
  (if 
    (= key :escape)
    (love.event.quit)))

{: draw : update : activate : keypressed}
