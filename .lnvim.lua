local _2afile_2a = "/home/chouffe/GameDev/fennel-repl-sandbox/min-love2d-fennel/.lnvim.fnl"
local nvim = require("aniseed.nvim")
nvim.g["conjure#filetype#fennel"] = "conjure.client.fennel.stdio"
nvim.g["conjure#client#fennel#stdio#command"] = "love ."
return nil