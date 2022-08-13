(fn paddle-dimensions [{: paddle : quads}]
  (let [{: size-type : skin : position } paddle 
        quad (. (. quads.paddles skin) size-type)
        (_ _ width height) (: quad :getViewport)]
    {:width width :height height}))

(fn ball-dimensions [{: ball : quads}]
  {:width 8 :height 8})

{: paddle-dimensions : ball-dimensions}
