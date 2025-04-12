SMODS.ConsumableType({
	object_type = "ConsumableType",
	key = "RSpectral",
	primary_colour = HEX("ff00c4"),
	secondary_colour = HEX("ff00c4"),
	collection_rows = { 4, 5 },
	shop_rate = 0.0,
	loc_txt = {},
	default = "c_entr_memory_leak"
})

SMODS.Consumable({
    key = "changeling",
    set = "RSpectral",
    unlocked = true,
    discovered = true,
    atlas = "miscc",
    config = {
        num = 3
    },
	pos = {x=6,y=4},
    --soul_pos = { x = 5, y = 0},
    use = function(self, card2, area, copier)
        local cards = {}
        for i = 1, card2.ability.num do
            local ind = -1
            local tries = 100
            while (ind == -1 or cards[ind]) and tries > 0 do
                ind = Entropy.Pseudorandom("changeling", 1, #G.hand.cards)
                tries = tries - 1
            end
            cards[ind] = true
        end
        for i, v in pairs(cards) do
            cards[i] = G.hand.cards[i] 
        end
        Entropy.FlipThen(cards, function(card,area)
            card:set_edition(pseudorandom_element(G.P_CENTER_POOLS.Edition, pseudoseed("changeling")).key)
            SMODS.change_base(card, nil, pseudorandom_element({"King", "Queen", "Jack"}, pseudoseed("changeling")))
        end)
    end,
    can_use = function(self, card)
        return G.hand and #G.hand.cards > 0
	end,
    loc_vars = function(self, q, card)
        return {
            vars = {
                card.ability.num
            }
        }
    end,
})

SMODS.Consumable({
    key = "inscribe",
    set = "RSpectral",
    unlocked = true,
    discovered = true,
    atlas = "miscc",
    config = {
        chipmult = 3
    },
	pos = {x=8,y=4},
    --soul_pos = { x = 5, y = 0},
    use = function(self, card2, area, copier)
        Entropy.FlipThen(Entropy.FilterArea(G.hand.cards, function(card) return not card:is_face() and card.base.value ~= "Ace" end), function(card, area)
            card.base.nominal = card.base.nominal * card2.ability.chipmult
            card.perma_debuff = true
            card:set_debuff(true)
        end)
    end,
    can_use = function(self, card)
        return G.hand and #G.hand.cards > 0
	end,
    loc_vars = function(self, q, card)
        return {
            vars = {
                card.ability.chipmult
            }
        }
    end,
})

local set_debuffref = Card.set_debuff

function Card:set_debuff(should_debuff)
    if self.perma_debuff then should_debuff = true end
    set_debuffref(self, should_debuff)
end

Entropy.SealSpectral("insignia", {x=9,y=4}, "entr_silver")

SMODS.Consumable({
    key = "siphon",
    set = "RSpectral",
    unlocked = true,
    discovered = true,
    atlas = "miscc",
    config = {
        chipmult = 3
    },
	pos = {x=10,y=4},
    --soul_pos = { x = 5, y = 0},
    use = function(self, card2, area, copier)
        local lower = Entropy.FindPreviousInPool(G.jokers.highlighted[1].edition.key, "Edition")
        Entropy.FlipThen(G.hand.cards, function(card, area)
            card:set_edition(lower)
        end)
        G.jokers.highlighted[1]:start_dissolve()
    end,
    can_use = function(self, card)
        return G.jokers and #G.jokers.highlighted == 1 and G.jokers.highlighted[1].edition
	end,
    loc_vars = function(self, q, card)
        local str = "none"
        if G.jokers and #G.jokers.highlighted > 0 and G.jokers.highlighted[1].edition and Entropy.FindPreviousInPool(G.jokers.highlighted[1].edition.key, "Edition") then
            str = G.localization.descriptions.Edition[Entropy.FindPreviousInPool(G.jokers.highlighted[1].edition.key, "Edition")].name
        end
        return {
            vars = {
                str
            }
        }
    end,
    entr_credits = {
        idea = "crabus"
    }
})

SMODS.Consumable({
    key = "ward",
    set = "RSpectral",
    unlocked = true,
    discovered = true,
    atlas = "miscc",
    config = {
        sellmult = 2
    },
	pos = {x=11,y=4},
    --soul_pos = { x = 5, y = 0},
    use = function(self, card, area, copier)
        local total = 0
        for i, v in pairs(G.jokers.cards) do
            if not v.ability.eternal and not v.ability.cry_absolute then
                local joker = G.jokers.cards[i]
                total = total + joker.cost
                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 0.1,
                    func = function()
                        joker:start_dissolve()
                        return true
                    end
                }))
            end
        end
        ease_dollars(total * card.ability.sellmult)
    end,
    can_use = function(self, card)
        return G.jokers and #G.jokers.cards > 0
	end,
    loc_vars = function(self, q, card)
        return {
            vars = {
                card.ability.sellmult
            }
        }
    end,
})


Entropy.SealSpectral("rendezvous", {x=10,y=5}, "entr_crimson")
Entropy.SealSpectral("eclipse", {x=12,y=5}, "entr_sapphire")
Entropy.SealSpectral("calamity", {x=6,y=6}, "entr_pink")
Entropy.SealSpectral("calamity", {x=6,y=6}, "entr_pink")


SMODS.Consumable({
    key = "fervour",
    set = "RSpectral",
    unlocked = true,
    discovered = true,
    atlas = "miscc",
    config = {

    },
	name = "entr-Fervour",
    soul_rate = 0, --probably only obtainable from flipsiding a gateway
    hidden = true, 
	pos = {x=4,y=0},
    --soul_pos = { x = 5, y = 0},
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.4,
			func = function()
				play_sound("timpani")
				local card = create_card("Joker", G.jokers, nil, "entr_reverse_legendary", nil, nil, nil, "entr_beyond")
				card:add_to_deck()
				G.jokers:emplace(card)
				card:juice_up(0.3, 0.5)
				return true
			end,
		}))
		delay(0.6)
    end,
    can_use = function(self, card)
        return true
	end,
    loc_vars = function(self, q, card)
        return {
            vars = {
                colours = {
                    {3,3,3,3}
                }
            }
        }
    end,
    entr_credits = {
        custom = {key="card_art", text="gudusername_53951"}
    }
})

SMODS.Consumable({
    key = "quasar",
    set = "RSpectral",
    unlocked = true,
    discovered = true,
    atlas = "miscc",
    config = {
        level = 3
    },
    soul_rate = 0,
    hidden = true, 
	pos = {x=7,y=3},
    --soul_pos = { x = 5, y = 0},
    use = function(self, card, area, copier,amt)
        local amt = amt or 1
        local used_consumable = copier or card
        delay(0.4)
        local max=0
        local ind="High Card"
        for i, v in pairs(G.GAME.hands) do
            if v.played > max then
                max = v.played
                ind = i
            end
        end
        update_hand_text(
          { sound = "button", volume = 0.7, pitch = 0.8, delay = 0.3 },
          { handname = localize(ind,'poker_hands'), chips = "...", mult = "...", level = "" }
        )
        G.GAME.hands[ind].AscensionPower = (G.GAME.hands[ind].AscensionPower or 0) + G.GAME.hands[ind].level * amt * card.ability.level
        delay(1.0)
        G.E_MANAGER:add_event(Event({
          trigger = "after",
          delay = 0.2,
          func = function()
            play_sound("tarot1")
            ease_colour(G.C.UI_CHIPS, copy_table(G.C.GOLD), 0.1)
            ease_colour(G.C.UI_MULT, copy_table(G.C.GOLD), 0.1)
            Cryptid.pulse_flame(0.01, sunlevel)
            used_consumable:juice_up(0.8, 0.5)
            G.E_MANAGER:add_event(Event({
              trigger = "after",
              blockable = false,
              blocking = false,
              delay = 1.2,
              func = function()
                ease_colour(G.C.UI_CHIPS, G.C.BLUE, 1)
                ease_colour(G.C.UI_MULT, G.C.RED, 1)
                return true
              end,
            }))
            return true
          end,
        }))
        update_hand_text({ sound = "button", volume = 0.7, pitch = 0.9, delay = 0 }, { level = "+"..G.GAME.hands[ind].level..card.ability.level*amt })
        delay(2.6)
        update_hand_text(
          { sound = "button", volume = 0.7, pitch = 1.1, delay = 0 },
          { mult = 0, chips = 0, handname = "", level = "" }
        )
    end,
    bulk_use = function(self,card,area,copier,amt)
        self.use(self,card,area,copier,amt)
    end,
    can_use = function(self, card)
        return true
	end,
    loc_vars = function(self, q, card)
        local max=0
        local ind="High Card"
        for i, v in pairs(G.GAME.hands) do
            if v.played > max then
                max = v.played
                ind = i
            end
        end
        return {
            vars = {
                G.GAME.hands[ind].level * card.ability.level
            }
        }
    end,
})

SMODS.Consumable({
    key = "weld",
    set = "RSpectral",
    unlocked = true,
    discovered = true,
    atlas = "miscc",
    config = {
        select = 1,
        discard = 1
    },
	pos = {x=11,y=6},
    --soul_pos = { x = 5, y = 0},
    use = function(self, card, area, copier)
        for i = 1, card.ability.select do
            local card = G.jokers.highlighted[i]
            if card then
                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 0.2,
                    func = function()
                        card:flip()
                        return true
                    end
                }))
            end
        end
        for i = 1, card.ability.select do
            local card = G.jokers.highlighted[i]
            if card then
                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 0.2,
                    func = function()
                        card.cry_absolute = true
                        card:set_edition({
                            negative=true,
                            key="e_negative",
                            card_limit=1,
                            type="negative"
                        })
                        return true
                    end
                }))
            end
        end
        for i = 1, card.ability.select do
            local card = G.jokers.highlighted[i]
            if card then
                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 0.2,
                    func = function()
                        card:flip()
                        return true
                    end
                }))
            end
        end
        G.GAME.round_resets.discards = G.GAME.round_resets.discards - card.ability.discard
        ease_discard(-card.ability.discard)
    end,
    can_use = function(self, card)
        return G.jokers and #G.jokers.highlighted <= card.ability.select and #G.jokers.highlighted > 0
	end,
    loc_vars = function(self, q, card)
        q[#q+1] = {key = "cry_absolute", set="Other"}
        q[#q+1] = {key = "e_negative", set="Edition", config = {extra = 1}}
        return {
            vars = {
                card.ability.select,
                -card.ability.discard
            }
        }
    end,
})
SMODS.Rank {
    key = 'nilrank',
    card_key = 'nilrank',
    pos = {x = 99},
    nominal = 1,
    face_nominal = 1,
    shorthand = "nil",
    in_pool = function(self, args)
        return false
    end
}
SMODS.Suit {
    key = 'nilsuit',
    card_key = 'nilsuit',
    pos = { y = 99 },
    ui_pos = {x=99,y=99},
    in_pool = function(self, args)
        return false
    end
}
local is_suitref = Card.is_suit
function Card:is_suit(suit, bypass_debuff, flush_calc)
    --unified usually never shows up, support for life and other mods
    if self.base.suit == "entr_nilsuit" then
        return false
    else
       return is_suitref(self, suit, bypass_debuff, flush_calc)
    end
end
function Card:get_id()
    if (self.ability.effect == 'Stone Card' and not self.vampired) or self.base.value == "entr_nilrank" then
        return -math.random(100, 1000000)
    end
    return self.base.id
end
SMODS.Consumable({
    key = "cleanse",
    set = "RSpectral",
    unlocked = true,
    discovered = true,
    atlas = "miscc",
    config = {
        dollarpc = 1
    },
	pos = {x=7,y=7},
    --soul_pos = { x = 5, y = 0},
    use = function(self, card2, area, copier)
        local total = 0
        for i, card in pairs(G.hand.cards) do
            if card.ability and card.ability.effect == 'Stone Card' then
                total = total + (10 + card.ability.perma_bonus) * card2.ability.dollarpc 
                card:set_ability(G.P_CENTERS.c_base, true, nil)
            else
                total = total + (card.base.nominal-1 + card.ability.perma_bonus) * card2.ability.dollarpc 
            end
            card.ability.perma_bonus = 0
        end
        Entropy.FlipThen(G.hand.cards, function(card, area)
            total = total + (card.base.nominal-1) * card2.ability.dollarpc
            SMODS.change_base(card, "entr_nilsuit", "entr_nilrank")
        end)
        delay(1)
        ease_dollars(total)
    end,
    can_use = function(self, card)
        return G.hand and #G.hand.cards > 0
	end,
    loc_vars = function(self, q, card)
        return {
            vars = {
                card.ability.dollarpc
            }
        }
    end,
})

Entropy.SealSpectral("downpour", {x=12,y=7}, "entr_cerulean")
Entropy.SealSpectral("script", {x=6,y=8}, "entr_verdant")

SMODS.Consumable({
    key = "pulsar",
    set = "RSpectral",
    unlocked = true,
    discovered = true,
    atlas = "miscc",
    config = {
        level = 4
    },
    soul_rate = 0,
    hidden = true, 
	pos = {x=6,y=3},
    --soul_pos = { x = 5, y = 0},
    use = function(self, card, area, copier,amt)
        local amt = amt or 1
        local used_consumable = copier or card
        delay(0.4)
        update_hand_text(
          { sound = "button", volume = 0.7, pitch = 0.8, delay = 0.3 },
          { handname = localize('k_all_hands'), chips = "...", mult = "...", level = "" }
        )
        for i, v in pairs(G.GAME.hands) do
            v.AscensionPower = (v.AscensionPower or 0) + card.ability.level*amt
            v.visible = true
        end
        delay(1.0)
        G.E_MANAGER:add_event(Event({
          trigger = "after",
          delay = 0.2,
          func = function()
            play_sound("tarot1")
            ease_colour(G.C.UI_CHIPS, copy_table(G.C.GOLD), 0.1)
            ease_colour(G.C.UI_MULT, copy_table(G.C.GOLD), 0.1)
            Cryptid.pulse_flame(0.01, sunlevel)
            used_consumable:juice_up(0.8, 0.5)
            G.E_MANAGER:add_event(Event({
              trigger = "after",
              blockable = false,
              blocking = false,
              delay = 1.2,
              func = function()
                ease_colour(G.C.UI_CHIPS, G.C.BLUE, 1)
                ease_colour(G.C.UI_MULT, G.C.RED, 1)
                return true
              end,
            }))
            return true
          end,
        }))
        update_hand_text({ sound = "button", volume = 0.7, pitch = 0.9, delay = 0 }, { level = "+"..card.ability.level*amt })
        delay(2.6)
        update_hand_text(
          { sound = "button", volume = 0.7, pitch = 1.1, delay = 0 },
          { mult = 0, chips = 0, handname = "", level = "" }
        )
    end,
    bulk_use = function(self,card,area,copier,amt)
        self.use(self,card,area,copier,amt)
    end,
    can_use = function(self, card)
        return true
	end,
    loc_vars = function(self, q, card)
        return {
            vars = {
                card.ability.level
            }
        }
    end,
})

SMODS.Consumable({
    key = "define",
    set = "RSpectral",
    unlocked = true,
    discovered = true,
    atlas = "miscc",
    config = {

    },
    soul_rate = 0,
    name = "entr-Define",
    hidden = true,
    pos = {x=4,y=4},
    --soul_pos = { x = 2, y = 0, extra = { x = 1, y = 0 } },
    use = function(self, card, area, copier)
        if area == G.pack_cards and G.pack_cards then
            G.GAME.pack_choices = G.GAME.pack_choices + 1
            G.GAME.define_in_pack = true
        end
        if not G.GAME.DefineKeys then
            G.GAME.DefineKeys = {}
        end

        G.GAME.USING_CODE = true
		G.GAME.USING_DEFINE = true
		G.ENTERED_CARD = ""
		G.CHOOSE_CARD = UIBox({
			definition = G.FUNCS.create_UIBox_define(card),
			config = {
				align = "cm",
				offset = { x = 0, y = 10 },
				major = G.ROOM_ATTACH,
				bond = "Weak",
				instance_type = "POPUP",
			},
		})
		G.CHOOSE_CARD.alignment.offset.y = 0
		G.ROOM.jiggle = G.ROOM.jiggle + 1
		G.CHOOSE_CARD:align_to_major()
    end,
    can_use = function(self, card)
        return GetSelectedCards() > 1 and GetSelectedCards() < 3 and GetSelectedCard() and GetSelectedCard().config.center.key ~= "j_entr_ruby"
	end,
    loc_vars = function(self, q, card)
        return {
            vars = {
                "#",
                colours = {
                    HEX("ff00c4")
                }
            }
        }
    end,
})

SMODS.Consumable({
    key = "beyond",
    set = "RSpectral",
    unlocked = true,
    discovered = true,
    atlas = "miscc",
    config = {

    },
    name = "entr-Beyond",
    soul_rate = 0, --probably only obtainable from flipsiding a gateway
    hidden = true, 
    --soul_pos = { x = 2, y = 0, extra = { x = 1, y = 0 } },
    use = function(self, card, area, copier)
        if not G.GAME.banned_keys then
			G.GAME.banned_keys = {}
		end
        for i, v in pairs(G.jokers.cards) do
            G.GAME.banned_keys[v.config.center.key] = true
            G.E_MANAGER:add_event(Event({
				trigger = "before",
				delay = 0.75,
				func = function()
                    if v.config.center.rarity ~= "entr_hyper_exotic" or G.GAME.selected_back.effect.center.original_key ~= "doc" then
                        if not v.ability.cry_absolute then
                            if v.config.center.rarity == "cry_exotic" then
                                check_for_unlock({ type = "what_have_you_done" })
                            end
                            v:start_dissolve(nil, _first_dissolve)
                        end
                    end
                    return true
				end,
			}))
        end
        G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.4,
			func = function()
				play_sound("timpani")
				local card = create_card("Joker", G.jokers, nil, "entr_hyper_exotic", nil, nil, nil, "entr_beyond")
				card:add_to_deck()
				G.jokers:emplace(card)
				card:juice_up(0.3, 0.5)
				return true
			end,
		}))
		delay(0.6)
    end,
    can_use = function(self, card)
        return true
	end,
    loc_vars = function(self, q, card)
        return {
            vars = {
                colours = {
                    {2,2,2,2}
                }
            }
        }
    end
})