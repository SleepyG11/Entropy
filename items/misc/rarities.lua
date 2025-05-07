Entropy.entropic_gradient = SMODS.Gradient {
    key = "entropic_gradient",
    colours = {
        G.C.RED,
        G.C.GOLD,
        G.C.GREEN,
        G.C.BLUE,
        G.C.PURPLE
    }
}

SMODS.Rarity {
    key = "entropic",
    badge_colour = Entropy.entropic_gradient
}

local loc_colour_ref = loc_colour
function loc_colour(_c, default)
    if not G.ARGS.LOC_COLOURS then
        loc_colour_ref(_c, default)
    elseif not G.ARGS.LOC_COLOURS.entr_colours then
        G.ARGS.LOC_COLOURS.entr_colours = true
        local new_colors = {
            entr_entropic = Entropy.entropic_gradient,
        }

        for k, v in pairs(new_colors) do
            G.ARGS.LOC_COLOURS[k] = v
        end
    end

    return loc_colour_ref(_c, default)
end