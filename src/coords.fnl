(fn left [{: x}]
  x)

(fn right [{: x : width}]
  (+ x width))

(fn top [{: y}]
  y)
  
(fn bottom [{: y : height}]
  (+ y height))

{: left : right : top : bottom}
