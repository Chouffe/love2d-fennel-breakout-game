(fn load-fonts [path]
  {:small (love.graphics.newFont (.. path "font.ttf") 8)
   :medium (love.graphics.newFont (.. path "font.ttf") 16)
   :large (love.graphics.newFont (.. path "font.ttf") 32)})

(comment
  (load-fonts "assets/fonts/"))
   
(fn load-images [path]
  {:background (love.graphics.newImage (.. path "background.png"))
   :main (love.graphics.newImage (.. path "breakout.png"))
   :arrows (love.graphics.newImage (.. path "arrows.png"))
   :hearts (love.graphics.newImage (.. path "hearts.png"))
   :particle (love.graphics.newImage (.. path "particle.png"))})

(comment
  (load-images "assets/images/"))

(fn load-sounds [path]
  {:paddle-hit (love.audio.newSource (.. path "paddle_hit.wav") "static")
   :score (love.audio.newSource (.. path "score.wav") "static")
   :wall-hit (love.audio.newSource (.. path "wall_hit.wav") "static")
   :confirm (love.audio.newSource (.. path "confirm.wav") "static")
   :select (love.audio.newSource (.. path "select.wav") "static")
   :no-select (love.audio.newSource (.. path "no-select.wav") "static")
   :brick-hit-1 (love.audio.newSource (.. path "brick-hit-1.wav") "static")
   :brick-hit-2 (love.audio.newSource (.. path "brick-hit-2.wav") "static")
   :hurt (love.audio.newSource (.. path "hurt.wav") "static")
   :victory (love.audio.newSource (.. path "victory.wav") "static")
   :recover (love.audio.newSource (.. path "recover.wav") "static")
   :high-score (love.audio.newSource (.. path "high_score.wav") "static")
   :pause (love.audio.newSource (.. path "pause.wav") "static")
   :music (love.audio.newSource (.. path "music.wav") "static")})

(comment
  (load-sounds "assets/sounds/"))

(fn load-assets []
  (let [fonts (load-fonts "assets/fonts/")
        images (load-images "assets/images/")
        sounds (load-sounds "assets/sounds/")]
    {: fonts : images : sounds}))

(comment
  (load-assets))

{: load-assets}

