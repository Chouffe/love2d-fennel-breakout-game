(local lume (require :lib.lume))
(local util-coll (require :src.util.coll))

(fn game-over? [{: balls-left}]
  (<= balls-left 0))

(fn game-won? [{: entities}]
  (-> entities.indexed-bricks
      (util-coll.vals)
      (lume.all (fn [{: invisible?}] invisible?))))

{: game-won? : game-over?}
