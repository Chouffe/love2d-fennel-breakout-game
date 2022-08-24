(local lume (require :lib.lume))

(fn vals [map]
  (let [result []]
    (each [k v (pairs map)]
      (table.insert result v))
    result))

(comment
  (vals {:a 12 :b 42 :c :hello}))

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

(fn index-by [key coll]
  (lume.reduce coll 
               (fn [acc x]
                 (let [k (. x key)]
                   (lume.merge acc {k x})))
               {}))

{: index-by : range : vals}
