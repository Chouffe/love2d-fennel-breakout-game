;;; This file is here purely for Neovim Conjure usage. It does the magic of
;;; starting the game and connecting Conjure to it (+ whatever you want it to).
(local nvim (require :aniseed.nvim))

;; Use normal fennel, instead of (the default) aniseed.
(set nvim.g.conjure#filetype#fennel "conjure.client.fennel.stdio")

;; Start the game and connect the Conjure fennel client to it.
(set nvim.g.conjure#client#fennel#stdio#command "love .")
