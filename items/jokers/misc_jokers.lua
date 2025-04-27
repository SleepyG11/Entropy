SMODS.Joker({
    key = "surreal_joker",
    config = {
        qmult = 4
    },
    rarity = 1,
    cost = 7,
    unlocked = true,

    blueprint_compat = true,
    eternal_compat = true,
    pos = { x = 0, y = 0 },
    atlas = "jokers",
    demicoloncompat = true,
    pools = { ["Meme"] = true },
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                " "..card.ability.qmult
            },
        }
    end,
    calculate = function (self, card, context)
        if context.joker_main or context.forcetrigger then
            G.GAME.current_round.current_hand.mult = card.ability.qmult
            update_hand_text({delay = 0}, {chips = G.GAME.current_round.current_hand.chips and hand_chips, mult = card.ability.qmult})
            return {
                Eqmult_mod = card.ability.qmult
            }
        end
    end
})

SMODS.Joker({
    key = "tesseract",
    config = {
        degrees = 90
    },
    rarity = 1,
    cost = 3,
    unlocked = true,
    pools = { ["Meme"] = true },
    blueprint_compat = true,
    eternal_compat = true,
    pos = { x = 1, y = 0 },
    atlas = "jokers",
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                number_format(card.ability.degrees)
            },
        }
    end,
})

local ref = update_hand_text

function update_hand_text(config, vals)
    if type(vals.mult) == "number" or type(vals.mult) == "table" and HasJoker("j_entr_tesseract",true) and math.abs(to_big(vals.mult)) > to_big(0.001) then
        local total_angle = 0
        for i, v in pairs(G.jokers.cards) do
            if v.config.center.key == "j_entr_tesseract" then
                total_angle = total_angle + v.ability.degrees
            end
        end
        total_angle = (total_angle/360)*2*3.141592
        local base = {r=math.cos(total_angle),c=math.sin(total_angle)}
        local str = Entropy.WhatTheFuck(base, vals.mult)
        vals.mult = str
    end
    if type(vals.chips) == "number" or type(vals.chips) == "table" and HasJoker("j_entr_tesseract",true) and math.abs(to_big(vals.chips)) > to_big(0.001) then
        local total_angle = 0
        for i, v in pairs(G.jokers.cards) do
            if v.config.center.key == "j_entr_tesseract" then
                total_angle = total_angle + v.ability.degrees
            end
        end
        total_angle = -(total_angle/360)*2*3.14159265
        local base = {r=math.cos(total_angle),c=math.sin(total_angle)}
        local str = Entropy.WhatTheFuck(base, vals.chips)
        vals.chips = str
    end
    ref(config, vals)
end

SMODS.Joker({
    key = "solarflare",
    name="entr-solarflare",
    config = {
        asc=1.6
    },
    rarity = 2,
    cost = 2,
    unlocked = true,

    blueprint_compat = true,
    eternal_compat = true,
    pos = { x = 2, y = 0 },
    atlas = "jokers",
    demicoloncompat = true,
    loc_vars = function(self, info_queue, center)
        if not center.edition or (center.edition and not center.edition.sol) then
			info_queue[#info_queue + 1] = G.P_CENTERS.e_entr_solar
		end
        return {
            vars = {
                number_format(center.ability.asc)
            },
        }
    end,
    calculate = function(self, card, context)
		if
			(context.other_joker
			and context.other_joker.edition
			and context.other_joker.edition.sol
			and card ~= context.other_joker)
		then
			if not Talisman.config_file.disable_anims then
				G.E_MANAGER:add_event(Event({
					func = function()
						context.other_joker:juice_up(0.5, 0.5)
						return true
					end,
				}))
			end
			return {
				asc = lenient_bignum(card.ability.asc),
			}
		end
		if context.individual and context.cardarea == G.play then
			if context.other_card.edition and context.other_card.edition.sol then
				return {
					asc = lenient_bignum(card.ability.asc),
					colour = G.C.MULT,
					card = card,
				}
			end
		end
		if
			(context.individual
			and context.cardarea == G.hand
			and context.other_card.edition
			and context.other_card.edition.sol
			and not context.end_of_round)
		then
			if context.other_card.debuff then
				return {
					message = localize("k_debuffed"),
					colour = G.C.RED,
					card = card,
				}
			else
				return {
					asc = lenient_bignum(card.ability.asc),
					card = card,
				}
			end
		end
        if context.forcetrigger then
            return {
                asc = lenient_bignum(card.ability.asc),
                card = card,
            }
        end
	end
})

local create_ref = create_card
function create_card(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
    local card = create_ref(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
    if card and card.ability and card.ability.name == "entr-solarflare" then
		card:set_edition("e_entr_solar", true, nil, true)
	end
    return card
end

SMODS.Joker({
    key = "strawberry_pie",
    config = {
        level_amount = 2
    },
    rarity = 3,
    cost = 10,
    unlocked = true,

    blueprint_compat = false,
    eternal_compat = true,
    pos = { x = 2, y = 1 },
    atlas = "jokers",
    demicoloncompat = true,
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                number_format(card.ability.level_amount)
            },
        }
    end,
})
local ref = level_up_hand
function level_up_hand(card, hand, instant, amount)
    if HasJoker("j_entr_strawberry_pie",true) and hand ~= "High Card" then
        local mult = 1
        for i, v in pairs(G.jokers.cards) do
            if v.config.center.key == "j_entr_strawberry_pie" and not v.debuff then
                hand = "High Card"
                mult = v.ability.level_amount
            end
        end
        amount = (amount or 1) * mult
    end
    ref(card,hand,instant,amount)
end

SMODS.Joker({
    key = "recursive_joker",
    config = {
        used_this_round = false
    },
    rarity = 2,
    cost = 4,
    unlocked = true,

    blueprint_compat = false,
    eternal_compat = true,
    pos = { x = 3, y = 1 },
    atlas = "jokers",
    demicoloncompat = true,
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.used_this_round and "Inactive" or "Active"
            },
        }
    end,
    calculate = function(self, card, context)
        if context.end_of_round then
            card.ability.used_this_round = false
        end
        if context.selling_card and context.card == card and not card.ability.used_this_round then
            card.ability.used_this_round = true
            local card = copy_card(card)
            card:add_to_deck()
            G.jokers:emplace(card)
        end
    end
})