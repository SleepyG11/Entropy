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
      _F.timer = _F.timer + G.real_dt*(1 + _F.intensity*0.2)
      if _F.intensity_vel < 0 then _F.intensity_vel = _F.intensity_vel*(1 - 10*G.real_dt) end
      _F.intensity_vel = (1-exptime)*(_F.intensity - _F.real_intensity)*G.real_dt*25 + exptime*_F.intensity_vel
      _F.real_intensity = math.max(0, _F.real_intensity + _F.intensity_vel)
      
      _F.real_intensity = (G.cry_flame_override and G.cry_flame_override['duration'] > 0) and ((_F.real_intensity + G.cry_flame_override['intensity'])/2) or _F.real_intensity
      if to_big(_F.real_intensity) > to_big(85) then
          _F.real_intensity = 85
      end
      _F.change = (_F.change or 0)*(1 - 4.*G.real_dt) + ( 4.*G.real_dt)*(_F.real_intensity < _F.intensity - 0.0 and 1 or 0)*_F.real_intensity
      _F.change = (G.cry_flame_override and G.cry_flame_override['duration'] > 0) and ((_F.change + G.cry_flame_override['intensity'])/2) or _F.change
    end
  end
end

  SMODS.Joker:take_ownership("cry_oil_lamp", {
    rarity = "cry_epic"
  }, true)


SMODS.Joker:take_ownership('cry_circus',
{
    config = {
		extra = { Xmult = 1 },
		immutable = {
			rare_mult_mod = 2,
			epic_mult_mod = 3,
			legend_mult_mod = 4,
			exotic_mult_mod = 20,
      entropic_mult_mod = 50,
			rarity_map = {
				[3] = "rare_mult_mod",
				[4] = "legend_mult_mod",
				["cry_epic"] = "epic_mult_mod",
				["cry_exotic"] = "exotic_mult_mod",
        ["entr_entropic"] = "entropic_mult_mod"
			},
		},
	},
    calculate = function(self, card, context)
		local function calculate_xmult(mult_mod)
			if not Talisman.config_file.disable_anims then
				G.E_MANAGER:add_event(Event({
					func = function()
						context.other_joker:juice_up(0.5, 0.5)
						return true
					end,
				}))
			end

			local xmult = lenient_bignum(math.max(1, to_big(card.ability.extra.Xmult)) * to_big(mult_mod))
			return {
				message = localize({
					type = "variable",
					key = "a_xmult",
					vars = { number_format(xmult) },
				}),
				Xmult_mod = xmult,
			}
		end

		if context.other_joker and card ~= context.other_joker then
			local mod_key = card.ability.immutable.rarity_map[context.other_joker.config.center.rarity]
			if mod_key then
				return calculate_xmult(card.ability.immutable[mod_key])
			end
		end
	end,
    loc_vars = function(self, info_queue, center)
		return {
			vars = {
				number_format(math.max(1, center.ability.extra.Xmult) * center.ability.immutable.rare_mult_mod),
				number_format(math.max(1, center.ability.extra.Xmult) * center.ability.immutable.epic_mult_mod),
				number_format(math.max(1, center.ability.extra.Xmult) * center.ability.immutable.legend_mult_mod),
				number_format(math.max(1, center.ability.extra.Xmult) * center.ability.immutable.exotic_mult_mod),
                number_format(math.max(1, center.ability.extra.Xmult) * center.ability.immutable.entropic_mult_mod),
			},
		}
	end,
},
true)