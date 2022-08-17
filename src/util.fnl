(local lume (require :lib.lume))

(fn range [start end step]
  (let [result []]
    (for [i start end step]
      (table.insert result i))
    result))

(comment
  (range 0 10 2)
  (range 0 192 32)
  (range 0 256 16)

  (-> (range 0 256 16)
      (lume.map (fn [y]
                  (-> (range 0 192 32)
                      (lume.map (fn [x] {:x x :y y})))))
      (lume.reduce lume.concat []))

  (lume.map))

{: range}
