function Entropy.GetHighlightedCards(cardareas, ignorecard, blacklist)
    local cards = {}
    blacklist = blacklist or {}
    for i, area in pairs(cardareas) do
        if area.cards then
            for i2, card in ipairs(area.highlighted) do
                if card ~= ignorecard and not blacklist[card.config.center.key] and card.highlighted then
                    cards[#cards + 1] = card
                end
            end
        end
    end
    return cards
end

function Entropy.FilterTable(table, func)
    local temp = {}
    for i, v in ipairs(table) do
        if func(v, i) then
            temp[#temp + 1] = v
        end
    end
    return temp
end

function Entropy.Inversion(card)
    return Entropy.FlipsideInversions[card.config.center.key]
end

function Entropy.FlipThen(cardlist, func, before, after)
    if not Talisman.config_file.disable_anims then
        for i, v in ipairs(cardlist) do
            local card = cardlist[i]
            if card then
                G.E_MANAGER:add_event(
                    Event(
                        {
                            trigger = "after",
                            delay = 0.1,
                            func = function()
                                if before then
                                    before(card)
                                end
                                if card.flip then
                                    card:flip()
                                end
                                return true
                            end
                        }
                    )
                )
            end
        end
    else
        if before then
            before(card)
        end
    end
    for i, v in ipairs(cardlist) do
        local card = cardlist[i]
        if card then
            G.E_MANAGER:add_event(
                Event(
                    {
                        trigger = "after",
                        delay = 0.15,
                        func = function()
                            func(card, cardlist, i)
                            return true
                        end
                    }
                )
            )
        end
    end
    if not Talisman.config_file.disable_anims then
        for i, v in ipairs(cardlist) do
            local card = cardlist[i]
            if card then
                G.E_MANAGER:add_event(
                    Event(
                        {
                            trigger = "after",
                            delay = 0.1,
                            func = function()
                                if card.flip then
                                    card:flip()
                                end
                                if after then
                                    after(card)
                                end
                                return true
                            end
                        }
                    )
                )
            end
        end
    else    
        if after then
            after(card)
        end
    end
end

function Entropy.SealSpectral(key, sprite_pos, seal,order, inversion)
    return {
        dependencies = {
            items = {
              "set_entr_inversions",
              seal
            }
        },
        object_type = "Consumable",
        order = order,
        key = key,
        set = "RSpectral",
        
        atlas = "consumables",
        config = {
            highlighted = 1
        },
        pos = sprite_pos,
        inversion = inversion,
        --soul_pos = { x = 5, y = 0},
        use = Entropy.ModifyHandCard({seal=seal}),
        can_use = function(self, card)
            local cards = Entropy.GetHighlightedCards({G.hand}, card)
            return #cards > 0 and #cards <= card.ability.highlighted
        end,
        loc_vars = function(self, q, card)
            q[#q+1] = {key = seal.."_seal", set="Other"}
            return {
                vars = {
                    card.ability.highlighted,
                    colours = {
                        SMODS.Seal.obj_table[seal].badge_colour or G.C.RED
                    }
                }
            }
        end,
    }
end

function Entropy.ModifyHandCard(modifications, cards)
    return function()
        Entropy.FlipThen(cards or G.hand.highlighted, function(mcard)
            if modifications.suit or modifications.rank then
                SMODS.change_base(mcard, modifications.suit, modifications.rank)
            end
            if modifications.enhancement then
                mcard:set_ability(G.P_CENTERS[modifications.enhancement])
            end
            if modifications.edition then
                if type(modifications.edition) == "table" then
                    mcard:set_edition(modifications.edition)
                else
                    mcard:set_edition(G.P_CENTERS[modifications.edition])
                end
            end
            if modifications.seal then
                mcard:set_seal(modifications.seal)
            end
            if modifications.sticker then
                Entropy.ApplySticker(mcard, modifications.sticker)
            end
            if modifications.extra then
                for i, v in pairs(modifications.extra) do mcard.ability[i] = v end
            end
        end)
    end
end

function Entropy.FindPreviousInPool(item, pool)
    for i, v in pairs(G.P_CENTER_POOLS[pool]) do
        if G.P_CENTER_POOLS[pool][i].key == item then
            return G.P_CENTER_POOLS[pool][i-1].key
        end
    end
    return nil
end

Entropy.charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890~#$^~#$^~#$^~#$^~#$^"
function Entropy.StringRandom(length) 
    local total = ""
    for i = 0, length do
        local val = math.random(1,#Entropy.charset)
        total = total..(Entropy.charset:sub(val, val))
    end
    return total
end

function Entropy.FormatDollarValue(val)
    if to_big(val) >= to_big(0) then
        return localize("$")..val
    else
        return "-"..localize("$")..(-val)
    end
end
function Entropy.Pseudorandom(seed, min, max)
    return math.floor(pseudorandom(seed)*(max-min)+0.5)+min
end

function Entropy.HasJoker(key, checkdebuff)
    local num = nil
    for i, v in ipairs(G.jokers and G.jokers.cards or {}) do
        if v.config.center.key == key and (not checkdebuff or not v.debuff) and not v.ability.turned_off then num = (num or 0) + 1 end
    end
    return num
end

function Entropy.HasConsumable(key)
    for i, v in pairs(G.consumeables.cards) do if v.config.center.key == key then return true end end
    if G.pack_cards then for i, v in pairs(G.pack_cards.cards or {}) do if v.config.center.key == key then return true end end end
    for i, v in pairs(G.hand.cards) do if v.config.center.key == key then return true end end
end

function Entropy.InTable(table, val)
    for i, v in ipairs(table) do if v == val then return true end end
end

function Entropy.GetNextRarity(rarity)
    if rarity == "entr_reverse_legendary" then return "cry_exotic" end
    for i, v in pairs(Entropy.RarityChecks) do
        if v == rarity then return Entropy.RarityChecks[i+1] or v end
    end
    return rarity
end

function Entropy.GetHigherVoucherTier(voucher_key)
    for i, v in pairs(G.P_CENTER_POOLS.Voucher) do
        if Entropy.InTable(v.requires or {}, voucher_key) then return v.key end
    end
end

local gfcfbs = G.FUNCS.check_for_buy_space
G.FUNCS.check_for_buy_space = function(card)
	if
		not card or card.ability.infinitesimal or card.ability.set == "Back" or card.ability.set == "Sleeve"
	then
		return true
	end
	return gfcfbs(card)
end

function Entropy.RandomForcetrigger(card, num,context)
    local res = { }
			local cards = Entropy.GetRandomCards({G.jokers, G.hand, G.consumeables, G.play}, num, "fractured", function(card) return not card.edition or card.edition.key ~= "e_entr_fractured" end)
			for i, v in pairs(cards) do
				if Cryptid.demicolonGetTriggerable(v) and (not v.edition or v.edition.key ~= "e_entr_fractured") then
					local results = Cryptid.forcetrigger(v, context)
					if results then
						for i, v in pairs(results) do
							for i2, result in pairs(v) do
								if type(result) == "number" or (type(result) == "table" and result.tetrate) then
									res[i2] = Entropy.StackEvalReturns(res[i2], result, i2)
								else
									res[i2] = result
								end
							end
						end
					end
					card_eval_status_text(
						v,
						"extra",
						nil,
						nil,
						nil,
						{ message = localize("cry_demicolon"), colour = G.C.GREEN }
					)
				elseif v.base.id and (not v.edition or v.edition.key ~= "e_entr_fractured") then
					local results = eval_card(v, {cardarea=G.play,main_scoring=true, forcetrigger=true, individual=true})
					if results then
						for i, v in pairs(results) do
							for i2, result in pairs(v) do
								if type(result) == "number" or (type(result) == "table" and result.tetrate) then
									res[i2] = Entropy.StackEvalReturns(res[i2], result, i2)
								else
									res[i2] = result
								end
							end
						end
					end
					local results = eval_card(v, {cardarea=G.hand,main_scoring=true, forcetrigger=true, individual=true})
					if results then
						for i, v in pairs(results) do
							for i2, result in pairs(v) do
								if type(result) == "number" or (type(result) == "table" and result.tetrate) then
									res[i2] = Entropy.StackEvalReturns(res[i2], result, i2)
								else
									res[i2] = result
								end
							end
						end
					end
					card_eval_status_text(
						v,
						"extra",
						nil,
						nil,
						nil,
						{ message = localize("cry_demicolon"), colour = G.C.GREEN }
					)
				end
			end
			if res.p_dollars then ease_dollars(res.p_dollars) end
			return res
end

function Entropy.GetRandomSet(has_parakmi)
    local pool = pseudorandom_element(G.P_CENTER_POOLS, pseudoseed(has_parakmi and "parakmi" or "chaos"))
    local set = pool and pool[1] and pool[1].set
    while not set or Entropy.ParakmiBlacklist[set] or (not has_parakmi and Entropy.ChaosBlacklist[set]) do
        pool = pseudorandom_element(G.P_CENTER_POOLS, pseudoseed(has_parakmi and "parakmi" or "chaos"))
        set = pool and pool[1] and pool[1].set
    end
    return set
end

function Entropy.BlindIs(blind)
    if G.GAME.blind and G.GAME.blind.config and G.GAME.blind.config.blind.key == blind then return true end
    if Entropy.IsEE() and Entropy.EEWhitelist[blind] then return true end
end

function Entropy.card_eval_status_text_eq(card, eval_type, amt, percent, dir, extra, pref, col, sound, vol)
    percent = percent or (0.9 + 0.2*math.random())
    if dir == 'down' then 
        percent = 1-percent
    end

    if extra and extra.focus then card = extra.focus end

    local text = ''
    local volume = vol or 1
    local card_aligned = 'bm'
    local y_off = 0.15*G.CARD_H
    if card.area == G.jokers or card.area == G.consumeables then
        y_off = 0.05*card.T.h
    elseif card.area == G.hand then
        y_off = -0.05*G.CARD_H
        card_aligned = 'tm'
    elseif card.area == G.play then
        y_off = -0.05*G.CARD_H
        card_aligned = 'tm'
    elseif card.jimbo  then
        y_off = -0.05*G.CARD_H
        card_aligned = 'tm'
    end
    local config = {}
    local delay = 0.65
    local colour = config.colour or (extra and extra.colour) or ( G.C.FILTER )
    local extrafunc = nil
    sound = sound or 'multhit1'--'other1'
    amt = amt
    text = (pref) or ("Mult = "..amt)
    colour = col or G.C.MULT
    config.type = 'fade'
    config.scale = 0.7
    delay = delay*1.25
    if to_big(amt) > to_big(0) or to_big(amt) < to_big(0) then
        if extra and extra.instant then
            if extrafunc then extrafunc() end
            attention_text({
                text = text,
                scale = config.scale or 1, 
                hold = delay - 0.2,
                backdrop_colour = colour,
                align = card_aligned,
                major = card,
                offset = {x = 0, y = y_off}
            })
            play_sound(sound, 0.8+percent*0.2, volume)
            if not extra or not extra.no_juice then
                card:juice_up(0.6, 0.1)
                G.ROOM.jiggle = G.ROOM.jiggle + 0.7
            end
        else
            G.E_MANAGER:add_event(Event({ --Add bonus chips from this card
                    trigger = 'before',
                    delay = delay,
                    func = function()
                    if extrafunc then extrafunc() end
                    attention_text({
                        text = text,
                        scale = config.scale or 1, 
                        hold = delay - 0.2,
                        backdrop_colour = colour,
                        align = card_aligned,
                        major = card,
                        offset = {x = 0, y = y_off}
                    })
                    play_sound(sound, 0.8+percent*0.2, volume)
                    if not extra or not extra.no_juice then
                        card:juice_up(0.6, 0.1)
                        G.ROOM.jiggle = G.ROOM.jiggle + 0.7
                    end
                    return true
                    end
            }))
        end
    end
    if extra and extra.playing_cards_created then 
        playing_card_joker_effects(extra.playing_cards_created)
    end
end

function Entropy.FormatArrowMult(arrows, mult)
    mult = number_format(mult)
    if to_big(arrows) < to_big(-1) then 
        return "="..mult 
    elseif to_big(arrows) < to_big(0) then 
        return "+"..mult 
    elseif to_big(arrows) < to_big(6) then 
        if to_big(arrows) < to_big(1) then
            return "X"..mult
        end
        local arr = ""
        for i = 1, to_big(arrows):to_number() do
            arr = arr.."^"
        end
        return arr..mult
    else
        return "{"..arrows.."}"..mult
    end
end

function Entropy.RareTag(rarity, key, ascendant, colour, pos, fac, legendary,order)
    return {
        object_type = "Tag",
        order = order,
        dependencies = {
          items = {
            "set_entr_tags",
            "j_entr_exousia"
          }
        },
        shiny_atlas="entr_shiny_ascendant_tags",
        key = (ascendant and "ascendant_" or "")..key,
        atlas = (ascendant and "ascendant_tags" or "tags"),
        pos = pos,
        config = { type = "store_joker_create" },
        in_pool = ascendant and function() return false end or nil,
        apply = function(self, tag, context)
            if context.type == "store_joker_create" then
                local rares_in_posession = { 0 }
                for k, v in ipairs(G.jokers.cards) do
                    if v.config.center.rarity == rarity and not rares_in_posession[v.config.center.key] then
                        rares_in_posession[1] = rares_in_posession[1] + 1
                        rares_in_posession[v.config.center.key] = true
                    end
                end
                local card
                if #G.P_JOKER_RARITY_POOLS[rarity] > rares_in_posession[1] then
                    card = create_card('Joker', context.area, legendary, rarity, nil, nil, nil, 'uta')
                    create_shop_card_ui(card, "Joker", context.area)
                    card.states.visible = false
                    tag:yep("+", G.C.RARITY[colour], function()
                        card:start_materialize()
                        card.misprint_cost_fac = 0 or fac
                        card:set_cost()
                        return true
                    end)
                else
                    tag:nope()
                end
                tag.triggered = true
                return card
            end
        end,
    }
end

function Entropy.EditionTag(edition, key, ascendant, pos,order)
    return {
        object_type = "Tag",
        dependencies = {
            items = {
                "set_entr_tags",
                "j_entr_exousia"
            }
        },
        order = order,
        shiny_atlas="entr_shiny_ascendant_tags",
        key = (ascendant and "ascendant_" or "")..key,
        atlas = (ascendant and "ascendant_tags" or "tags"),
        pos = pos,
        config = { type = "store_joker_modify" },
        in_pool = ascendant and function() return false end or nil,
        apply = function(self, tag, context)
            if context.type == "store_joker_modify" then
                tag:yep("+", G.C.RARITY[colour], function()
                    for i, v in pairs(G.shop_jokers.cards) do
                        v:set_edition(edition)
                    end
                    for i, v in pairs(G.shop_booster.cards) do
                        v:set_edition(edition)
                    end
                    for i, v in pairs(G.shop_vouchers.cards) do
                        v:set_edition(edition)
                    end
                    return true
                end)
                tag.triggered = true
            end
        end,
        loc_vars = function(s,q,c)
            q[#q+1] = edition and G.P_CENTERS[edition] or nil
        end
    }
end

Entropy.EEWhitelist["bl_final_heart"]=true
Entropy.EEWhitelist["bl_final_leaf"]=true
Entropy.EEWhitelist["bl_final_vessel"]=true
Entropy.EEWhitelist["bl_final_acorn"]=true
Entropy.EEWhitelist["bl_final_bell"]=true
Entropy.EEWhitelist["bl_cry_sapphire_stamp"]=true
Entropy.EEWhitelist["bl_entr_burgundy_baracuda"]=true
Entropy.EEWhitelist["bl_entr_diamond_dawn"]=true
Entropy.EEWhitelist["bl_entr_olive_orchard"]=true
Entropy.EEWhitelist["bl_entr_scarlet_sun"]=true
Entropy.EEWhitelist["bl_entr_citrine_comet"]=true

function Entropy.GetEEBlinds()
    local blinds = {}
    for i, v in pairs(G.P_BLINDS) do
        if Entropy.EEWhitelist[i] then
            blinds[i]=v
        end
    end
    return blinds
end

function Entropy.GetRandomCards(areas, cardns, rpseudoseed, cond)
    local cards = {}
    for i, v in pairs(areas) do
        for i2, v2 in pairs(v.cards) do
            if not cond or cond(v2) then cards[#cards+1]=v2 end
        end
    end
    pseudoshuffle(cards, pseudoseed(rpseudoseed or "fractured"))
    local temp = {}
    for i = 1, cardns do
        temp[i] = cards[i]
    end
    return temp
end

function Entropy.StackEvalReturns(orig, new, etype)
    if etype == "Xmult" or etype == "x_mult" or etype == "Xmult_mod" or etype == "Xchips" or etype == "Xchip_mod" or etype == "asc" or etype == "Emult_mod" or etype == "Echip_mod" then return (orig or 1) * new else
        return (orig or 0) + new
    end
end

function Entropy.DeckOrSleeve(key)
    local num = 0
    if key == "doc" and G.GAME.modifiers.doc_antimatter then num = num + 1 end
    if CardSleeves then
        if G.GAME.selected_sleeve == ("sleeve_entr_"..key) then num = num + 1 end
    end
    for i, v in pairs(G.GAME.entr_bought_decks or {}) do
        if v == "b_entr_"..key then num = num + 1 end
    end
    if  G.GAME.selected_back and G.GAME.selected_back.effect.center.original_key == key then num = num + 1 end
    return num > 0 and num or nil
end

Entropy.charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890~#$^~#$^~#$^~#$^~#$^"
function Entropy.srandom(length) 
    local total = ""
    for i = 0, length do
        local val = math.random(1,#Entropy.charset)
        total = total..(Entropy.charset:sub(val, val))
    end
    return total
end

function Entropy.ChangeEnhancements(areas, enh, required, uhl)
    for i, v in pairs(areas) do
        if not v.cards then 
            areas[i] = {
                cards = {v}
            }
        end
    end
    for i, v in pairs(areas) do
        for i2, v2 in pairs(v.cards) do
            if not required or (v2.config and v2.config.center.key == required) then
                if enh == "null" then
                    v2:start_dissolve()
                elseif enh == "ccd" then

                else
                    v2:set_ability(G.P_CENTERS[enh])
                    v2:juice_up()
                end
            end
        end
    end
end

function Entropy.ApplySticker(card, key)
    if not card.ability then card.ability = {} end
    if card.ability then
        if not SMODS.Stickers[key] then return end
        card.ability[key] = true
        if SMODS.Stickers[key].apply then SMODS.Stickers[key].apply(SMODS.Stickers[key], card) end
    end
end

function Entropy.HigherCardRank(card)
	if not card.base then return nil end
	local rank_suffix = math.min(card.base.id, 14)
	if rank_suffix < 10 then rank_suffix = tostring(rank_suffix)
	elseif rank_suffix == 10 then rank_suffix = '10'
	elseif rank_suffix == 11 then rank_suffix = 'Jack'
	elseif rank_suffix == 12 then rank_suffix = 'Queen'
	elseif rank_suffix == 13 then rank_suffix = 'King'
	elseif rank_suffix == 14 then raFnk_suffix = 'Ace'
	end
	return ({
		Queen = "King",
		Jack = "Queen",
		["10"] = "Jack",
		["9"] = "10",
		["8"] = "9",
		["7"] = "8",
		["6"] = "7",
		["5"] = "6",
		["4"] = "5",
		["3"] = "4",
		["2"] = "3",
		Ace = "2",
		King = "Ace",
	})[tostring(rank_suffix)]
end

Entropy.ReverseRarityChecks = {

}
for i, v in ipairs(Entropy.RarityChecks) do
    Entropy.ReverseRarityChecks[v]=i
end
function Entropy.RarityAbove(check, threshold, gte)
    if not Entropy.ReverseRarityChecks[check] then Entropy.ReverseRarityChecks[check] = 1 end
    if not Entropy.ReverseRarityChecks[threshold] then Entropy.ReverseRarityChecks[threshold] = 1 end
    if gte then return Entropy.ReverseRarityChecks[check] < Entropy.ReverseRarityChecks[threshold] end
    return Entropy.ReverseRarityChecks[check] <= Entropy.ReverseRarityChecks[threshold]
end
function Entropy.GetRandomRarityCard(rare)
    if rare == 1 then rare = "Common" end
    if rare == 2 then rare = "Uncommon" end
    if rare == 3 then rare = "Rare" end
    local _pool, _pool_key = get_current_pool("Joker", rare, rare == 4, "ieros")
    local center = pseudorandom_element(_pool, pseudoseed(_pool_key))
    local it = 1
    while center == 'UNAVAILABLE' do
        it = it + 1
        center = pseudorandom_element(_pool, pseudoseed(_pool_key..'_resample'..it))
    end
    return center
end

function Entropy.CanCreateZenith()
    local _pool, _pool_key = get_current_pool("Joker", "cry_exotic", nil, "zenith")
    for i, v in ipairs(_pool) do
        if v ~= "UNAVAILABLE" and not Entropy.HasJoker(v) and v ~= "j_joker" then return false end
    end

    local _pool, _pool_key = get_current_pool("Joker", "entr_entropic", nil, "zenith")
    for i, v in ipairs(_pool) do
        if v ~= "UNAVAILABLE" and not Entropy.HasJoker(v) and v ~= "j_joker" then return false end
    end
    return to_big(G.GAME.dollars) > to_big(1e300):tetrate(2)
end

function Entropy.randomchar(arr)
    return {
        n = G.UIT.O,
        config = {
            object = DynaText({
                string = arr,
                colours = { HEX("b1b1b1") },
                pop_in_rate = 9999999,
                silent = true,
                random_element = true,
                pop_delay = 0.1,
                scale = 0.3,
                min_cycle_time = 0,
            }),
        },
    }
end

function Entropy.GetJokerSumRarity(loc)
    if not G.jokers or #G.jokers.cards <= 0 then return "none" end
    local rarity = 1
    local sum = Entropy.SumJokerPoints()
    local last_sum = 0
    for i, v in pairs(Entropy.RarityPoints) do
        if type(sum) == "table" then
            if v > 12 and sum:gte(v-1) or sum:gte(v) then  
                if v > last_sum  then
                    rarity = i 
                    last_sum = v
                end
            end
        elseif sum >= (v > 12 and v-1 or v-0.01) then                 
            if v > last_sum  then
                rarity = i 
                last_sum = v
            end 
        end
    end
    if not loc then
        return rarity
    else
        return localize(({
            [1] = "k_common",
            [2] = "k_uncommon",
            [3] = "k_rare",
            [4] = "k_legendary"
        })[rarity] or "k_"..rarity)
    end
end
function Entropy.SumJokerPoints()
    local total = 0
    for i, v in pairs(G.jokers.cards) do
        total = total + Entropy.GetJokerPoints(v)
    end
    return total
end
function Entropy.GetJokerPoints(card)
    local total = Entropy.RarityPoints[card.config.center.rarity] or 1
    if card.edition then
        local factor = to_big(Entropy.GetEditionFactor(card.edition)) ^ (1.7/(Entropy.RarityDiminishers[card.config.center.rarity] or 1))
        total = total * factor
    end
    return total
end 
function Entropy.GetEditionFactor(edition)
    return Entropy.EditionFactors[edition.key] or 1
end

function Entropy.CanEeSpawn()
    if MP and MP.LOBBY and MP.LOBBY.code then return false end
    return true
end

function Entropy.stringsplit(s) 
    local tbl = {}
    for i = 1, #s do
        tbl[#tbl+1]=s:sub(i,i)
    end
    return tbl
end

function Entropy.TableAny(table, func)
    for i, v in pairs(table) do if func(v) then return true end end
end

function Card:is_sunny()
    if self.config.center.key == "j_entr_sunny_joker" then return true end
    if self.edition and self.edition.key == "e_entr_sunny" then return true end
    return nil
end

function Entropy.UpgradeEnhancement(card, bypass, blacklist)
    local enh = card.config.center.key
    if enh == "c_base" then return "m_bonus" end
    local cards = {}
    for i, v in pairs(G.P_CENTER_POOLS.Enhanced) do
        if (not v.no_doe or bypass) and not blacklist[v.key] then cards[#cards+1]=v end
    end
    table.sort(cards, function(a, b)
        return (a.upgrade_order or a.order) < (b.upgrade_order or b.order)
    end)
    for i, v in pairs(cards) do
        if v.key == enh then return cards[i+1] and cards[i+1].key end
    end
    return nil
end
function Entropy.GetAreaName(area) 
    if not area then return nil end
    for i, v in pairs(G) do
        if v == area then return i end
    end
end
function Entropy.GetIdxInArea(card)
    if card and card.area then
        for i, v in pairs(card.area.cards) do
            if v.unique_val == card.unique_val then return i end
        end
    end
end
function Entropy.FormatTesseract(base)
    if math.abs(to_big(base.c)) < to_big(0.001) then base.c = 0;base.minusc=false end
    if math.abs(to_big(base.r)) < to_big(0.001) then base.r = 0;base.minusr=false end
    local minr = base.minusr and "-" or ""
    local minc = base.minusc and "-" or ""
    if to_big(base.c) == to_big(0) then return minr..number_format(base.r) end
    if to_big(base.c) ~= to_big(0) and to_big(base.r) == to_big(0) then
        return minc..number_format(base.c).."i"
    end
    if base.minusc then
        return minr..number_format(base.r) .. "-" ..number_format(base.c).."i"
    end
    if not base.minusc then
        return minr..number_format(base.r) .. "+" ..number_format(base.c).."i"
    end
end


function Entropy.WhatTheFuck(base, val)
    if to_big(base.r) < to_big(0) then 
        base.r = -base.r
        base.minusr = true
    end
    if to_big(base.c) < to_big(0) then 
        base.c = math.abs(base.c)
        base.minusc = true
    end
    if to_big(math.abs(base.c)) < to_big(0.0001) then base.c = 0 end
    if to_big(math.abs(base.r)) < to_big(0.0001) then base.r = 0 end
    base.c = to_big(base.c) * to_big(val)
    base.r = to_big(base.r) * to_big(val)
    return Entropy.FormatTesseract(base)
end

function Entropy.RandomContext(seed)
    return pseudorandom_element({
        "before",
        "pre_joker",
        "joker_main",
        "individual",
        "pre_discard",
        "remove_playing_cards",
        "setting_blind",
        "ending_shop",
        "reroll_shop",
        "selling_card",
        "using_consumeable",
        "playing_card_added"
    }, pseudoseed(seed or "desync"))
end

function Entropy.ContextChecks(self, card, context, currc, edition)
    if not context.retrigger_joker and not context.blueprint and not context.forcetrigger and not context.post_trigger then
        if currc == "before" and context.before then return true end
        if currc == "pre_joker" and ((context.pre_joker) or (edition and context.main_scoring and context.cardarea == G.play)) then return true end
        if currc == "joker_main" and ((context.joker_main) or (edition and context.main_scoring and context.cardarea == G.play)) then return true end
        if currc == "individual" and ((context.individual and context.cardarea == G.play and not context.blueprint) or (edition and context.main_scoring and context.cardarea == G.play)) then return true end
        if currc == "pre_discard" and context.pre_discard and context.cardarea == G.hand and not context.retrigger_joker and not context.blueprint then return true end
        if currc == "remove_playing_cards" and context.remove_playing_cards and not context.blueprint then return true end
        if currc == "setting_blind" and context.setting_blind then return true end
        if currc == "ending_shop" and context.ending_shop then return true end
        if currc == "reroll_shop" and context.reroll_shop then return true end
        if currc == "selling_card" and context.selling_card then return true end
        if currc == "using_consumeable" and context.using_consumeable then return true end
        if currc == "playing_card_added" and context.playing_card_added then return true end
    end
end

function Entropy.IsEE()
    return G.GAME.blind and G.GAME.blind.config and G.GAME.blind.config.blind.key == "bl_entr_endless_entropy_phase_one"
    or G.GAME.blind and G.GAME.blind.config and G.GAME.blind.config.blind.key == "bl_entr_endless_entropy_phase_two"
    or G.GAME.blind and G.GAME.blind.config and G.GAME.blind.config.blind.key == "bl_entr_endless_entropy_phase_three"
    or G.GAME.blind and G.GAME.blind.config and G.GAME.blind.config.blind.key == "bl_entr_endless_entropy_phase_four"
end

function Entropy.WinEE()
    G.E_MANAGER:add_event(Event({
        trigger = 'immediate',
        func = (function()
            for k, v in pairs(G.I.CARD) do
                v.sticker_run = nil
            end
            
            play_sound('win')
            G.SETTINGS.paused = true
            G.GAME.TrueEndless = true
            G.FUNCS.overlay_menu{
                definition = create_UIBox_win(),
                config = {no_esc = true}
            }
            local Jimbo = nil

            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 2.5,
                blocking = false,
                func = (function()
                    if G.OVERLAY_MENU and G.OVERLAY_MENU:get_UIE_by_ID('jimbo_spot') then 
                        G.GAME.EECardCharacter = true
                        Jimbo = Card_Character({x = 0, y = 5, center = G.P_CENTERS.eecc})
                        local spot = G.OVERLAY_MENU:get_UIE_by_ID('jimbo_spot')
                        spot.config.object:remove()
                        spot.config.object = Jimbo
                        Jimbo.ui_object_updated = true
                        G.GAME.EECardCharacter =  nil
                        Jimbo:add_speech_bubble('wq_ee_'..math.random(1,5), nil, {quip = true})
                        Jimbo:say_stuff(5)
                        if G.F_JAN_CTA then 
                            G.E_MANAGER:add_event(Event({
                                func = function()
                                    Jimbo:add_button(localize('b_wishlist'), 'wishlist_steam', G.C.DARK_EDITION, nil, true, 1.6)
                                    return true
                                end}))
                        end
                        end
                    return true
                end)
            }))
            
            return true
        end)
    }))

    if (not G.GAME.seeded and not G.GAME.challenge) or SMODS.config.seeded_unlocks then
        G.PROFILES[G.SETTINGS.profile].stake = math.max(G.PROFILES[G.SETTINGS.profile].stake or 1, (G.GAME.stake or 1)+1)
    end
    G:save_progress()
    G.FILE_HANDLER.force = true
    G.E_MANAGER:add_event(Event({
        trigger = 'immediate',
        func = (function()
            if not G.SETTINGS.paused then
                G.GAME.current_round.round_text = 'Endless Round '
                return true
            end
        end)
    }))
end

Entropy.TMTrainerEffects["mult"] = function(key) return { mult = pseudorandom(key) * 400 } end
Entropy.TMTrainerEffects["chips"] = function(key) return { chips = pseudorandom(key) * 4000 } end
Entropy.TMTrainerEffects["xmult"] = function(key) return { xmult = pseudorandom(key) * 40 } end
Entropy.TMTrainerEffects["xchips"] = function(key) return { xchips = pseudorandom(key) * 40 } end
Entropy.TMTrainerEffects["emult"] = function(key) return { emult = pseudorandom(key) * 4 } end
Entropy.TMTrainerEffects["echips"] = function(key) return { echips = pseudorandom(key) * 4 } end
Entropy.TMTrainerEffects["dollars"] = function(key) ease_dollars(pseudorandom(key) * 20) end
Entropy.TMTrainerEffects["joker_random"] = function(key) SMODS.add_card({set = "Joker"}) end
Entropy.TMTrainerEffects["joker_choose_rarity"] = function(key) SMODS.add_card({set = "Joker", rarity = pseudorandom_element({1, 1, 1, 2, 2, 3, 3, "cry_epic"}, pseudoseed(key))}) end
Entropy.TMTrainerEffects["edition"] = function(key) 
    local element = pseudorandom_element(G.jokers.cards, pseudoseed(key))
    Entropy.FlipThen({element}, function(card)
        card:set_edition(pseudorandom_element(G.P_CENTER_POOLS.Edition, pseudoseed("entropy")).key)
    end)
end
Entropy.TMTrainerEffects["ante"] = function(key) ease_ante(-pseudorandom(key)*0.1) end
Entropy.TMTrainerEffects["consumable"] = function(key) SMODS.add_card({key = Cryptid.random_consumable("entr_segfault", nil, "c_entr_segfault").key, area = G.consumeables}) end
Entropy.TMTrainerEffects["enhancement_play"] = function(key) 
    local enhancement = pseudorandom_element(G.P_CENTER_POOLS.Enhanced, pseudoseed("entropy")).key
    while G.P_CENTERS[enhancement].no_doe or G.GAME.banned_keys[enhancement] do
        enhancement = pseudorandom_element(G.P_CENTER_POOLS.Enhanced, pseudoseed("entropy")).key
    end
    local element = pseudorandom_element(G.play.cards, pseudoseed(key))
    Entropy.FlipThen({element}, function(card)
        card:set_ability(G.P_CENTERS[enhancement])
    end)
end
Entropy.TMTrainerEffects["enhancement_hand"] = function(key) 
    local enhancement = pseudorandom_element(G.P_CENTER_POOLS.Enhanced, pseudoseed("entropy")).key
    while G.P_CENTERS[enhancement].no_doe or G.GAME.banned_keys[enhancement] do
        enhancement = pseudorandom_element(G.P_CENTER_POOLS.Enhanced, pseudoseed("entropy")).key
    end
    local element = pseudorandom_element(G.hand.cards, pseudoseed(key))
    Entropy.FlipThen({element}, function(card)
        card:set_ability(G.P_CENTERS[enhancement])
    end)
end
Entropy.TMTrainerEffects["random"] = function(key, context )
    local res = {}
    for i = 1, 3 do
        local results = Entropy.TMTrainerEffects[Entropy.RandomEffect()]("tmtrainer_actual_effect", context) or nil
        if results then
            for i, v in pairs(results) do
                for i2, result in pairs(v) do
                    if type(result) == "number" or (type(result) == "table" and result.tetrate) then
                        res[i2] = Entropy.StackEvalReturns(res[i2], result, i2)
                    else
                        res[i2] = result
                    end
                end
            end
        end
    end
    return res
end

Entropy.TMTrainerScoring["mult"]=true
Entropy.TMTrainerScoring["xmult"]=true
Entropy.TMTrainerScoring["emult"]=true
Entropy.TMTrainerScoring["chips"]=true
Entropy.TMTrainerScoring["xchips"]=true
Entropy.TMTrainerScoring["echips"]=true
Entropy.TMTrainerScoring["enhancement_play"]=true

function Entropy.RandomEffect(context)
    local keys = {}
    for i, v in pairs(Entropy.TMTrainerEffects) do
        keys[#keys+1] = i
    end
    local scoring = {
        before=true,
        pre_joker=true,
        joker_main=true,
        individual=true,
    }
    local element = pseudorandom_element(keys, pseudoseed("tmtrainer_effect"))
    while not scoring[context] and Entropy.TMTrainerScoring[element] do
        element = pseudorandom_element(keys, pseudoseed("tmtrainer_effect"))
    end
    return element
end
function Entropy.TMTTrainize(card)
    local context = Entropy.RandomContext()
    local effect = Entropy.RandomEffect(context)
    card.ability.tm_effect = effect
    card.ability.tm_context = context
end

SMODS.Edition:take_ownership("e_cry_glitched", {
    calculate = function(self, card, context)
        if card.ability.tm_effect then
            if Entropy.ContextChecks(self, card, context, card.ability.tm_context, true) then
                return Entropy.TMTrainerEffects[card.ability.tm_effect]("tmtrainer_actual_effect", card.ability.tm_context) or nil
            end
        end
    end,
    loc_vars = function(self, q, card) 
        if card and card.ability and card.ability.tm_effect then
            q[#q+1] = {set = "Other", key = "tmtrainer_dummy", vars = {localize("k_"..card.ability.tm_context), localize("k_tmt"..card.ability.tm_effect)}}
        end
    end
}, true)

function Entropy.ChangePhase()
    G.STATE = 1
    G.STATE_COMPLETE = false
    local remove_temp = {}
    for i, v in pairs({G.jokers, G.hand, G.consumeables, G.discard, G.deck}) do
        for ind, card in pairs(v.cards) do
            if card.ability then
                if card.ability.temporary or card.ability.temporary2 then
                    if card.area ~= G.hand and card.area ~= G.play and card.area ~= G.jokers and card.area ~= G.consumeables then card.states.visible = false end
                    card:remove_from_deck()
                    card:start_dissolve()
                    if card.ability.temporary then remove_temp[#remove_temp+1]=card end
                end
            end
        end
    end
    if #remove_temp > 0 then
        SMODS.calculate_context({remove_playing_cards = true, removed=remove_temp})
    end
    G.deck:shuffle()
    G.E_MANAGER:add_event(Event({func = function()
        G.GAME.ChangingPhase = nil
        return true
    end}))
end

function Entropy.LevelSuit(suit, card, amt)
    amt = amt or 1
    local used_consumable = copier or card
    if not G.GAME.SuitBuffs then G.GAME.SuitBuffs = {} end
    if not G.GAME.SuitBuffs[suit] then
        G.GAME.SuitBuffs[suit] = {level = 1, chips = 0}
    end
    if not G.GAME.SuitBuffs[suit].chips then G.GAME.SuitBuffs[suit].chips = 0 end
    if not G.GAME.SuitBuffs[suit].level then G.GAME.SuitBuffs[suit].level = 1 end
    update_hand_text(
    { sound = "button", volume = 0.7, pitch = 0.8, delay = 0.3 },
    { handname = localize(suit,'suits_plural'), chips = number_format(G.GAME.SuitBuffs[suit].chips), mult = "...", level = number_format(G.GAME.SuitBuffs[suit].level) }
    )
    G.GAME.SuitBuffs[suit].chips = G.GAME.SuitBuffs[suit].chips + amt
    G.GAME.SuitBuffs[suit].level = G.GAME.SuitBuffs[suit].level + 1
    for i, v in ipairs(G.I.CARD) do
        if v.base and v.base.suit == suit then
            v.ability.bonus = (v.ability.bonus or 0) + amt
            v.ability.bonus_from_suit = (v.ability.bonus_from_suit or 0) + amt
        end
    end
    G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.9, func = function()
            play_sound('tarot1')
            if card then card:juice_up(0.8, 0.5) end
            G.TAROT_INTERRUPT_PULSE = nil
            return true 
        end 
    }))
    G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.9, func = function()
            play_sound('tarot1')
            if card then card:juice_up(0.8, 0.5) end
            G.TAROT_INTERRUPT_PULSE = nil
            return true 
        end 
    }))
    update_hand_text({ sound = "button", volume = 0.7, pitch = 0.9, delay = 0 }, { chips="+"..number_format(amt), StatusText = true })
    G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.9, func = function()
            play_sound('tarot1')
            if card then card:juice_up(0.8, 0.5) end
            G.TAROT_INTERRUPT_PULSE = nil
            return true 
        end 
    }))
    update_hand_text({ sound = "button", volume = 0.7, pitch = 0.9, delay = 0 }, { level = number_format(G.GAME.SuitBuffs[suit].level+1), chips=number_format(G.GAME.SuitBuffs[suit].chips) })
    delay(1.3)
    update_hand_text(
    { sound = "button", volume = 0.7, pitch = 1.1, delay = 0 },
    { mult = 0, chips = 0, handname = "", level = "" }
    )
end

function Entropy.GetRepetitions(card)
    local res2 = {}
    for i, v in ipairs(G.jokers.cards) do
        local res = eval_card(v, {repetition=true, other_card=card,cardarea=card.area,card_effects={{},{}}})
        if res.jokers and res.jokers.repetitions then
            res2.repetitions = (res2.repetitions or 0) + res.jokers.repetitions
        end
    end
    return res2
end