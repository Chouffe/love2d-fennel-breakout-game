(var state {:assets {}})

(global si state)

(fn draw [])

(fn update [dt set-mode])

(fn activate [{: assets}]
  (assets.sounds.music:setLooping true)
  (assets.sounds.music:play)
  (set state.assets assets))

(fn keypressed [key set-mode])

{: draw : update : activate : keypressed}
