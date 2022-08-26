(local fennel (require :lib.fennel))

(local config (require :src.config))
(local entity (require :src.entity))
(local quads (require :src.quads))
(local util-coll (require :src.util.coll))

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

{: draw-entities}
