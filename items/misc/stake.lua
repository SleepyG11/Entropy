SMODS.Atlas({key = 'stakes', path = 'stakes.png', px = 29, py = 29})
local entropic = {
    dependencies = {
        items = {
          "set_entr_misc"
        }
    },
	object_type = "Stake",
    order = 1,
    name = "entr-Entropic Stake",
    key = "entropic",
    pos = { x = 0, y = 0 },
    atlas = "stakes",
    applied_stakes = { "cry_ascendant" },
    prefix_config = { applied_stakes = { mod = false } },
    sticker_atlas = "stickers",
    sticker_pos = {x=0,y=1},
    modifiers = function()
        G.GAME.modifiers.entropic = true
    end,
    shiny=true,
    order = 9999,
    colour = HEX("ff0000")
}

local zenith = {
    dependencies = {
        items = {
          "set_entr_misc"
        }
    },
	object_type = "Stake",
    order = 2,
    name = "entr-Zenith Stake",
    key = "zenith",
    pos = { x = 1, y = 0 },
    atlas = "stakes",
    applied_stakes = { "entr_entropic" },
    prefix_config = { applied_stakes = { mod = false } },
    sticker_atlas = "stickers",
    sticker_pos = {x=0,y=1},
    modifiers = function()
        G.GAME.modifiers.zenith = true
    end,
    shiny=true,
    order = 10000,
    colour = HEX("ff00ff")
}

return {
    items = {
        entropic,
        zenith
    }
}