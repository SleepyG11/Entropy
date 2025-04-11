G.FUNCS.flame_handler = function(e)
    G.C.UI_CHIPLICK = G.C.UI_CHIPLICK or {1, 1, 1, 1}
    G.C.UI_MULTLICK = G.C.UI_MULTLICK or {1, 1, 1, 1}
    for i=1, 3 do
      G.C.UI_CHIPLICK[i] = math.min(math.max(((G.C.UI_CHIPS[i]*0.5+G.C.YELLOW[i]*0.5) + 0.1)^2, 0.1), 1)
      G.C.UI_MULTLICK[i] = math.min(math.max(((G.C.UI_MULT[i]*0.5+G.C.YELLOW[i]*0.5) + 0.1)^2, 0.1), 1)
    end
  
    G.ARGS.flame_handler = G.ARGS.flame_handler or {
      chips = {
        id = 'flame_chips', 
        arg_tab = 'chip_flames',
        colour = G.C.UI_CHIPS,
        accent = G.C.UI_CHIPLICK
      },
      mult = {
        id = 'flame_mult', 
        arg_tab = 'mult_flames',
        colour = G.C.UI_MULT,
        accent = G.C.UI_MULTLICK
      }
    }
    for k, v in pairs(G.ARGS.flame_handler) do
      if e.config.id == v.id then 
        if not e.config.object:is(Sprite) or e.config.object.ID ~= v.ID then 
          e.config.object:remove()
          e.config.object = Sprite(0, 0, 2.5, 2.5, G.ASSET_ATLAS["ui_1"], {x = 2, y = 0})
          v.ID = e.config.object.ID
          G.ARGS[v.arg_tab] = {
              intensity = 0,
              real_intensity = 0,
              intensity_vel = 0,
              colour_1 = v.colour,
              colour_2 = v.accent,
              timer = G.TIMERS.REAL
          }      
          e.config.object:set_alignment({
              major = e.parent,
              type = 'bmi',
              offset = {x=0,y=0},
              xy_bond = 'Weak'
          })
          e.config.object:define_draw_steps({{
            shader = 'flame',
            send = {
                {name = 'time', ref_table = G.ARGS[v.arg_tab], ref_value = 'timer'},
                {name = 'amount', ref_table = G.ARGS[v.arg_tab], ref_value = 'real_intensity'},
                {name = 'image_details', ref_table = e.config.object, ref_value = 'image_dims'},
                {name = 'texture_details', ref_table = e.config.object.RETS, ref_value = 'get_pos_pixel'},
                {name = 'colour_1', ref_table =  G.ARGS[v.arg_tab], ref_value = 'colour_1'},
                {name = 'colour_2', ref_table =  G.ARGS[v.arg_tab], ref_value = 'colour_2'},
                {name = 'id', val =  e.config.object.ID},
            }}})
            e.config.object:get_pos_pixel()
        end
        local _F = G.ARGS[v.arg_tab]
        local exptime = math.exp(-0.4*G.real_dt)
        if to_big(G.ARGS.score_intensity.earned_score) >= to_big(G.ARGS.score_intensity.required_score) and to_big(G.ARGS.score_intensity.required_score) > to_big(0) then
          _F.intensity = ((G.pack_cards and not G.pack_cards.REMOVED) or (G.TAROT_INTERRUPT)) and 0 or math.max(0., math.log(G.ARGS.score_intensity.earned_score, 5)-2)
            if type(_F.intensity) == "table" then
                if _F.intensity > to_big(85) then
                    _F.intensity = 85
                else
                    _F.intensity = _F.intensity:to_number()
                end
            elseif _F.intensity > 85 then
                _F.intensity = 85
            end
        else
          _F.intensity = 0
        end
        if G.GAME.Ruby and G.hand and #G.hand.highlighted > 0 and not G.pack_cards then
            _F.intensity = 85
        end
        _F.timer = _F.timer + G.real_dt*(1 + _F.intensity*0.2)
        if _F.intensity_vel < 0 then _F.intensity_vel = _F.intensity_vel*(1 - 10*G.real_dt) end
        _F.intensity_vel = (1-exptime)*(_F.intensity - _F.real_intensity)*G.real_dt*25 + exptime*_F.intensity_vel
        _F.real_intensity = math.max(0, _F.real_intensity + _F.intensity_vel)
        
        _F.real_intensity = (G.cry_flame_override and G.cry_flame_override['duration'] > 0) and ((_F.real_intensity + G.cry_flame_override['intensity'])/2) or _F.real_intensity
        if to_big(_F.real_intensity) > to_big(85) then
            _F.real_intensity = 85
        end
        if G.GAME.Ruby and G.hand and #G.hand.highlighted > 0 and not G.pack_cards then
            _F.real_intensity = 85
        end
        _F.change = (_F.change or 0)*(1 - 4.*G.real_dt) + ( 4.*G.real_dt)*(_F.real_intensity < _F.intensity - 0.0 and 1 or 0)*_F.real_intensity
        _F.change = (G.cry_flame_override and G.cry_flame_override['duration'] > 0) and ((_F.change + G.cry_flame_override['intensity'])/2) or _F.change
      end
    end
  end


  SMODS.Joker:take_ownership('cry_Scalae', -- object key (class prefix not required)
    { -- table of properties to change from the existing object
        cry_scale_mod = function(self, card, joker, orig_scale_scale, true_base, orig_scale_base, new_scale_base)
            if joker.ability.name ~= "cry-Scalae" then
                local new_scale = lenient_bignum(
                    to_big(true_base)
                        * (
                            (
                                1
                                + (
                                    (to_big(orig_scale_scale) / to_big(true_base))
                                    ^ (to_big(1) / to_big(card.ability.extra.scale))
                                )
                            ) ^ to_big(card.ability.extra.scale)
                        )
                )
                if not Cryptid.is_card_big(joker) and to_big(new_scale) >= to_big(1e300) then
                    new_scale = 1e300
                end
                return new_scale
            end
        end
    },
    true -- silent | suppresses mod badge
)

Cryptid.big_num_blacklist["j_credit_card"] = true

function getDollarNum(num)
    if type(num) == "number" then return tostring(num) end
    if to_big(num) > to_big(1e10) then
        return BalaNotation:format(num, 10)
    else
        return tostring(num:to_number())
    end
end

function add_round_eval_row(config)
    local config = config or {}
    local width = G.round_eval.T.w - 0.51
    local num_dollars = config.dollars or 1
    local scale = 0.9

    if config.name ~= 'bottom' then
        total_cashout_rows = (total_cashout_rows or 0) + 1
        if total_cashout_rows > 7 then
            return
        end
        if config.name ~= 'blind1' then
            if not G.round_eval.divider_added then 
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',delay = 0.25,
                    func = function() 
                        local spacer = {n=G.UIT.R, config={align = "cm", minw = width}, nodes={
                            {n=G.UIT.O, config={object = DynaText({string = {'......................................'}, colours = {G.C.WHITE},shadow = true, float = true, y_offset = -30, scale = 0.45, spacing = 13.5, font = G.LANGUAGES['en-us'].font, pop_in = 0})}}
                        }}
                        G.round_eval:add_child(spacer,G.round_eval:get_UIE_by_ID(config.bonus and 'bonus_round_eval' or 'base_round_eval'))
                        return true
                    end
                }))
                delay(0.6)
                G.round_eval.divider_added = true
            end
        else
            delay(0.2)
        end

        delay(0.2)

        G.E_MANAGER:add_event(Event({
            trigger = 'before',delay = 0.5,
            func = function()
                --Add the far left text and context first:
                local left_text = {}
                if config.name == 'blind1' then
                    local stake_sprite = get_stake_sprite(G.GAME.stake or 1, 0.5)
                    local obj = G.GAME.blind.config.blind
                    local blind_sprite = AnimatedSprite(0, 0, 1.2, 1.2, G.ANIMATION_ATLAS[obj.atlas] or G.ANIMATION_ATLAS['blind_chips'], copy_table(G.GAME.blind.pos))
                    blind_sprite:define_draw_steps({
                        {shader = 'dissolve', shadow_height = 0.05},
                        {shader = 'dissolve'}
                    })
                    table.insert(left_text, {n=G.UIT.O, config={w=1.2,h=1.2 , object = blind_sprite, hover = true, can_collide = false}})
  
                    table.insert(left_text,                  
                    config.saved and 
                    {n=G.UIT.C, config={padding = 0.05, align = 'cm'}, nodes={
                        {n=G.UIT.R, config={align = 'cm'}, nodes={
                            {n=G.UIT.O, config={object = DynaText({string = {' '..(G.GAME.Ruby and localize(pseudorandom_element(Entropy.RubySaves, pseudoseed("hope"))) or localize('ph_mr_bones'))..' '}, colours = {G.C.FILTER}, shadow = true, pop_in = 0, scale = 0.5*scale*(1), silent = true, maxw = 5})}}
                        }}
                    }}
                    or {n=G.UIT.C, config={padding = 0.05, align = 'cm'}, nodes={
                        {n=G.UIT.R, config={align = 'cm'}, nodes={
                            {n=G.UIT.O, config={object = DynaText({string = {' '..localize('ph_score_at_least')..' '}, colours = {G.C.UI.TEXT_LIGHT}, shadow = true, pop_in = 0, scale = 0.4*scale, silent = true})}}
                        }},
                        {n=G.UIT.R, config={align = 'cm', minh = 0.8}, nodes={
                            {n=G.UIT.O, config={w=0.5,h=0.5 , object = stake_sprite, hover = true, can_collide = false}},
                            {n=G.UIT.T, config={text = G.GAME.blind.chip_text, scale = scale_number(G.GAME.blind.chips, scale, 100000), colour = G.C.RED, shadow = true}}
                        }}
                    }}) 
                elseif string.find(config.name, 'tag') then
                    local blind_sprite = Sprite(0, 0, 0.7,0.7, G.ASSET_ATLAS['tags'], copy_table(config.pos))
                    blind_sprite:define_draw_steps({
                        {shader = 'dissolve', shadow_height = 0.05},
                        {shader = 'dissolve'}
                    })
                    blind_sprite:juice_up()
                    table.insert(left_text, {n=G.UIT.O, config={w=0.7,h=0.7 , object = blind_sprite, hover = true, can_collide = false}})
                    table.insert(left_text, {n=G.UIT.O, config={object = DynaText({string = {config.condition}, colours = {G.C.UI.TEXT_LIGHT}, shadow = true, pop_in = 0, scale = 0.4*scale, silent = true})}})                   
                elseif config.name == 'hands' and G.GAME.RootKit then
                table.insert(left_text, {n=G.UIT.T, config={text = config.disp or config.dollars, scale = 0.8*scale, colour = G.C.RED, shadow = true, juice = true}})
                table.insert(left_text, {n=G.UIT.O, config={object = DynaText({string = {" "..localize{type = 'variable', key = 'remaining_hand_money', vars = {(G.GAME.modifiers.money_per_hand or 1)*G.GAME.RootKit}}}, colours = {G.C.UI.TEXT_LIGHT}, shadow = true, pop_in = 0, scale = 0.4*scale, silent = true})}})
                G.GAME.RootKit = nil
                elseif config.name == 'hands' then
                    table.insert(left_text, {n=G.UIT.T, config={text = config.disp or config.dollars, scale = 0.8*scale, colour = G.C.BLUE, shadow = true, juice = true}})
                    table.insert(left_text, {n=G.UIT.O, config={object = DynaText({string = {" "..localize{type = 'variable', key = 'remaining_hand_money', vars = {G.GAME.modifiers.money_per_hand or 1}}}, colours = {G.C.UI.TEXT_LIGHT}, shadow = true, pop_in = 0, scale = 0.4*scale, silent = true})}})
                elseif config.name == 'discards' then
                    table.insert(left_text, {n=G.UIT.T, config={text = config.disp or config.dollars, scale = 0.8*scale, colour = G.C.RED, shadow = true, juice = true}})
                    table.insert(left_text, {n=G.UIT.O, config={object = DynaText({string = {" "..localize{type = 'variable', key = 'remaining_discard_money', vars = {G.GAME.modifiers.money_per_discard or 0}}}, colours = {G.C.UI.TEXT_LIGHT}, shadow = true, pop_in = 0, scale = 0.4*scale, silent = true})}})
                elseif string.find(config.name, 'joker') then
                    table.insert(left_text, {n=G.UIT.O, config={object = DynaText({string = localize{type = 'name_text', set = config.card.config.center.set, key = config.card.config.center.key}, colours = {G.C.FILTER}, shadow = true, pop_in = 0, scale = 0.6*scale, silent = true})}})
                elseif config.name == 'interest_payload' then
                table.insert(left_text, {n=G.UIT.T, config={text = num_dollars, scale = 0.8*scale, colour = G.C.SECONDARY_SET.Code, shadow = true, juice = true}})
                table.insert(left_text,{n=G.UIT.O, config={object = DynaText({string = {" "..localize{type = 'variable', key = 'interest', vars = {G.GAME.interest_amount*config.payload, 5, G.GAME.interest_amount*config.payload*G.GAME.interest_cap/5}}}, colours = {G.C.SECONDARY_SET.Code}, shadow = true, pop_in = 0, scale = 0.4*scale, silent = true})}})
                elseif config.name == 'interest' then
                    table.insert(left_text, {n=G.UIT.T, config={text = getDollarNum(num_dollars), scale = 0.8*scale, colour = G.C.MONEY, shadow = true, juice = true}})
                    table.insert(left_text,{n=G.UIT.O, config={object = DynaText({string = {" "..localize{type = 'variable', key = 'interest', vars = {getDollarNum(G.GAME.interest_amount), 5, getDollarNum(G.GAME.interest_amount*G.GAME.interest_cap/5)}}}, colours = {G.C.UI.TEXT_LIGHT}, shadow = true, pop_in = 0, scale = 0.4*scale, silent = true})}})
                end
                local full_row = {n=G.UIT.R, config={align = "cm", minw = 5}, nodes={
                    {n=G.UIT.C, config={padding = 0.05, minw = width*0.55, minh = 0.61, align = "cl"}, nodes=left_text},
                    {n=G.UIT.C, config={padding = 0.05,minw = width*0.45, align = "cr"}, nodes={{n=G.UIT.C, config={align = "cm", id = 'dollar_'..config.name},nodes={}}}}
                }}
        
                if config.name == 'blind1' then
                    G.GAME.blind:juice_up()
                end
                G.round_eval:add_child(full_row,G.round_eval:get_UIE_by_ID(getDollarNum(num_dollars) and 'bonus_round_eval' or 'base_round_eval'))
                play_sound('cancel', config.pitch or 1)
                play_sound('highlight1',( 1.5*config.pitch) or 1, 0.2)
                if config.card then config.card:juice_up(0.7, 0.46) end
                return true
            end
        }))
        local dollar_row = 0
        num_dollars = num_dollars; 
        if math.abs(to_big(num_dollars):to_number()) > 60 then
            if to_big(num_dollars) < to_big(0) then --if negative
                G.E_MANAGER:add_event(Event({
                    trigger = 'before',delay = 0.38,
                    func = function()
                        G.round_eval:add_child(
                            {n=G.UIT.R, config={align = "cm", id = 'dollar_row_'..(dollar_row+1)..'_'..config.name}, nodes={
                                {n=G.UIT.O, config={object = DynaText({string = {localize('$')..getDollarNum(num_dollars)}, colours = {G.C.RED}, shadow = true, pop_in = 0, scale = 0.65, float = true})}}
                            }},
                            G.round_eval:get_UIE_by_ID('dollar_'..config.name))
                        play_sound('coin3', 0.9+0.2*math.random(), 0.7)
                        play_sound('coin6', 1.3, 0.8)
                        return true
                    end
                }))
            else --if positive
            G.E_MANAGER:add_event(Event({
                trigger = 'before',delay = 0.38,
                func = function()
                    G.round_eval:add_child(
                            {n=G.UIT.R, config={align = "cm", id = 'dollar_row_'..(dollar_row+1)..'_'..config.name}, nodes={
                                {n=G.UIT.O, config={object = DynaText({string = {localize('$')..getDollarNum(num_dollars)}, colours = {G.C.MONEY}, shadow = true, pop_in = 0, scale = 0.65, float = true})}}
                            }},
                            G.round_eval:get_UIE_by_ID('dollar_'..config.name))

                    play_sound('coin3', 0.9+0.2*math.random(), 0.7)
                    play_sound('coin6', 1.3, 0.8)
                    return true
                end
            }))
            end
        else
            local dollars_to_loop
            num_dollars = to_big(num_dollars):to_number()
            if num_dollars < 0 then dollars_to_loop = (num_dollars*-1)+1 else dollars_to_loop = num_dollars end
            for i = 1, dollars_to_loop do
                G.E_MANAGER:add_event(Event({
                    trigger = 'before',delay = 0.18 - ((num_dollars > 20 and 0.13) or (num_dollars > 9 and 0.1) or 0),
                    func = function()
                        if i%30 == 1 then 
                            G.round_eval:add_child(
                                {n=G.UIT.R, config={align = "cm", id = 'dollar_row_'..(dollar_row+1)..'_'..config.name}, nodes={}},
                                G.round_eval:get_UIE_by_ID('dollar_'..config.name))
                                dollar_row = dollar_row+1
                        end

                        local r
                        if i == 1 and num_dollars < 0 then
                            r = {n=G.UIT.T, config={text = '-', colour = G.C.RED, scale = ((num_dollars < -20 and 0.28) or (num_dollars < -9 and 0.43) or 0.58), shadow = true, hover = true, can_collide = false, juice = true}}
                            play_sound('coin3', 0.9+0.2*math.random(), 0.7 - (num_dollars < -20 and 0.2 or 0))
                        else
                            if num_dollars < 0 then r = {n=G.UIT.T, config={text = localize('$'), colour = G.C.RED, scale = ((num_dollars > 20 and 0.28) or (num_dollars > 9 and 0.43) or 0.58), shadow = true, hover = true, can_collide = false, juice = true}}
                            else r = {n=G.UIT.T, config={text = localize('$'), colour = G.C.MONEY, scale = ((num_dollars > 20 and 0.28) or (num_dollars > 9 and 0.43) or 0.58), shadow = true, hover = true, can_collide = false, juice = true}} end
                        end
                        play_sound('coin3', 0.9+0.2*math.random(), 0.7 - (num_dollars > 20 and 0.2 or 0))
                        
                        if config.name == 'blind1' then 
                            G.GAME.current_round.dollars_to_be_earned = G.GAME.current_round.dollars_to_be_earned:sub(2)
                        end

                        G.round_eval:add_child(r,G.round_eval:get_UIE_by_ID('dollar_row_'..(dollar_row)..'_'..config.name))
                        G.VIBRATION = G.VIBRATION + 0.4
                        return true
                    end
                }))
            end
        end
    else
        delay(0.4)
        G.E_MANAGER:add_event(Event({
            trigger = 'before',delay = 0.5,
            func = function()
                UIBox{
                    definition = {n=G.UIT.ROOT, config={align = 'cm', colour = G.C.CLEAR}, nodes={
                        {n=G.UIT.R, config={id = 'cash_out_button', align = "cm", padding = 0.1, minw = 7, r = 0.15, colour = G.GAME.current_round.semicolon and G.C.SET.Code or G.C.ORANGE, shadow = true, hover = true, one_press = true, button = 'cash_out', focus_args = {snap_to = true}}, nodes={
                            {n=G.UIT.T, config={text = G.GAME.current_round.semicolon and localize('k_end_blind') or (localize('b_cash_out')..": "), scale = 1, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
                            {n=G.UIT.T, config={text = localize('$')..format_ui_value(config.dollars), scale = 1.2*scale, colour = G.C.WHITE, shadow = true, juice = true}}
                    }},}},
                    config = {
                      align = 'tmi',
                      offset ={x=0,y=0.4},
                      major = G.round_eval}
                }

                --local left_text = {n=G.UIT.R, config={id = 'cash_out_button', align = "cm", padding = 0.1, minw = 2, r = 0.15, colour = G.C.ORANGE, shadow = true, hover = true, one_press = true, button = 'cash_out', focus_args = {snap_to = true}}, nodes={
                --    {n=G.UIT.T, config={text = localize('b_cash_out')..": ", scale = 1, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
                --    {n=G.UIT.T, config={text = localize('$')..format_ui_value(config.dollars), scale = 1.3*scale, colour = G.C.WHITE, shadow = true, juice = true}}
                --}}
                --G.round_eval:add_child(left_text,G.round_eval:get_UIE_by_ID('eval_bottom'))

                G.GAME.current_round.dollars = config.dollars
                
                play_sound('coin6', config.pitch or 1)
                G.VIBRATION = G.VIBRATION + 1
                return true
            end
        }))
    end
end
SMODS.Joker:take_ownership('cry_oil_lamp',
{
    rarity = "cry_epic"
},
true)

--local xhips = card.ability.x_chips


local set_editionref = Card.set_edition

function Card:set_edition(edition, immediate, silent)
    local xchips = to_big(self.ability.x_chips):to_number()
    set_editionref(self, edition, immediate, silent)
    if edition and (edition == "e_cry_glitched" or edition.cry_glitched) and math.abs(xchips - 1) < 0.01 then
        self.ability.x_chips = 1
        self.ability.h_x_chips = 1
    end
end

function GetArrowString(arrows, size)
    if arrows > 5 then return "{"..arrows.."}"..size end
    local str = ""
    for i = 1, arrows do str = str.."^" end
    return str..size
end
local load_ref = Blind.load
function Blind:load(blindTable)
    if blindTable then
        load_ref(self, blindTable)
    end 
end

function SMODS.find_card(key, count_debuffed)
    local results = {}
    if not G.jokers or not G.jokers.cards then return {} end
    for _, area in ipairs(SMODS.get_card_areas('jokers')) do
        if area and area.cards then
            for _, v in pairs(area.cards) do
                if v and type(v) == 'table' and v.config.center.key == key and (count_debuffed or not v.debuff) then
                    table.insert(results, v)
                end
            end
        end
    end
    return results
end

create_UIBox_your_collection_seals = function()
    return SMODS.card_collection_UIBox(G.P_CENTER_POOLS.Seal, {6,6}, {
        snap_back = true,
        infotip = localize('ml_edition_seal_enhancement_explanation'),
        hide_single_page = true,
        collapse_single_page = true,
        center = 'c_base',
        h_mod = 1.03,
        modify_card = function(card, center)
           card:set_seal(center.key, true)
        end,
    })
end
