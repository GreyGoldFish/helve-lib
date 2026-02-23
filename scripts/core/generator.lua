local GENERATOR = {}
local schemas <const> = require("core.schemas")

--- Add a simple token if value exists.
-- @param lines table: Lines table to append to
-- @param token string: Token name
-- @param value any: Token value (optional)
local function add_token(lines, token, value)
   if not value then return end
   local num_value = tonumber(value)
   lines[#lines + 1] = num_value and string.format("[%s:%d]", token, num_value) or string.format("[%s:%s]", token, tostring(value))
end

--- Generate weapon raw data.
-- @param weapon_id string: Weapon identifier
-- @param weapon_data table: Weapon configuration
-- @param is_ranged boolean: Whether this is a ranged weapon
-- @return string: Generated raw data
function GENERATOR.generate_weapon_raw(weapon_id, weapon_data, is_ranged)
   local lines <const> = {}

   -- Header
   lines[#lines + 1] = string.format("[ITEM_WEAPON:%s]", weapon_id)
   add_generated_info(lines)

   -- Required tokens
   lines[#lines + 1] = string.format("[NAME:%s:%s]", weapon_data.name, weapon_data.name_plural)
   lines[#lines + 1] = string.format("[MATERIAL_SIZE:%d]", assert(tonumber(weapon_data.material_size), "material_size must be a number"))

   add_token(lines, "ADJECTIVE", weapon_data.adjective)
   add_token(lines, "SIZE", weapon_data.size)
   
   if weapon_data.skill and not is_ranged then
      add_token(lines, "SKILL", weapon_data.skill)
   end
   
   add_token(lines, "TWO_HANDED", weapon_data.two_handed)
   add_token(lines, "MINIMUM_SIZE", weapon_data.minimum_size)
   if weapon_data.can_stone then
      lines[#lines + 1] = "[CAN_STONE]"
   end
   if weapon_data.training then
      lines[#lines + 1] = "[TRAINING]"
   end

   -- Ranged specific tokens
   if is_ranged then
      lines[#lines + 1] = string.format("[RANGED:%s:%s]", weapon_data.skill, weapon_data.ammo_class)
      add_token(lines, "SHOOT_FORCE", weapon_data.shoot_force)
      add_token(lines, "SHOOT_MAXVEL", weapon_data.shoot_max_vel)
      add_token(lines, "AIM_DIFFICULTY", weapon_data.aim_difficulty)
      add_token(lines, "INITIATE_SHOT_TIME", weapon_data.initiate_shot_time)
      add_token(lines, "SHOT_RECOVERY_TIME", weapon_data.shot_recovery_time)
      
      if weapon_data.shoot_force_requires then
         local sfr <const> = weapon_data.shoot_force_requires
         lines[#lines + 1] = string.format("[SHOT_FORCE_REQUIRES:%s:%d]", sfr.attribute_or_skill, assert(tonumber(sfr.value), "value must be a number"))
      end
      
      if weapon_data.loaded_nocked then
         local ln <const> = weapon_data.loaded_nocked
         lines[#lines + 1] = string.format("[%s:%d:%d]", ln.ammo_handling, assert(tonumber(ln.maximum_ticks), "maximum_ticks must be a number"), assert(tonumber(ln.minimum_ticks), "minimum_ticks must be a number"))
      end
   end

   -- Attacks
   if weapon_data.attacks then
      local attacks = weapon_data.attacks or {}
      if type(attacks) ~= "table" then attacks = {attacks} end
      
      for _, attack in ipairs(attacks) do
         lines[#lines + 1] = string.format("[ATTACK:%s:%d:%d:%s:%s:%s:%d]",
            attack.attack_type,
            assert(tonumber(attack.contact_area), "contact_area must be a number"),
            assert(tonumber(attack.penetration_size), "penetration_size must be a number"),
            attack.verb_2nd,
            attack.verb_3rd,
            attack.noun,
            assert(tonumber(attack.velocity_multiplier), "velocity_multiplier must be a number")
         )
         
         if attack.attack_prepare_and_recover then
            local prep_rec <const> = attack.attack_prepare_and_recover
            lines[#lines + 1] = string.format("[ATTACK_PREPARE_AND_RECOVER:%d:%d]",
               assert(tonumber(prep_rec.preparation_time), "preparation_time must be a number"), 
               assert(tonumber(prep_rec.recovery_time), "recovery_time must be a number"))
         end
         
         if attack.multiattack_flag then
            lines[#lines + 1] = string.format("[%s]", attack.multiattack_flag)
         end
      end
   end

   print_table(lines)
   return table.concat(lines, "\n")
end

--- Generate melee weapon raw data.
-- @param weapon_id string: Weapon identifier
-- @param weapon_data table: Weapon configuration
-- @return string: Generated raw data
function GENERATOR.generate_melee_weapon_raw(weapon_id, weapon_data)
   return GENERATOR.generate_weapon_raw(weapon_id, weapon_data, false)
end

--- Generate ranged weapon raw data.
-- @param weapon_id string: Weapon identifier
-- @param weapon_data table: Weapon configuration
-- @return string: Generated raw data
function GENERATOR.generate_ranged_weapon_raw(weapon_id, weapon_data)
   return GENERATOR.generate_weapon_raw(weapon_id, weapon_data, true)
end

--- Validate and generate weapon raw with error handling.
-- @param weapon_id string: Weapon identifier
-- @param weapon_data table: Weapon configuration
-- @param schema table: Validation schema
-- @return string|nil, string|nil: Generated raw data or nil, error message or nil
local function generate_safe(weapon_id, weapon_data, schema)
   local ok, err = schemas.validate(weapon_data, schema, "weapon_data")
   if not ok then
      return nil, err
   end
   
   local is_ranged = schema == schemas.RANGED_WEAPON
   return GENERATOR.generate_weapon_raw(weapon_id, weapon_data, is_ranged)
end

--- Validate and generate melee weapon raw.
-- @param weapon_id string: Weapon identifier
-- @param weapon_data table: Weapon configuration
-- @return string|nil, string|nil: Generated raw data or nil, error message or nil
function GENERATOR.generate_melee_weapon_raw_safe(weapon_id, weapon_data)
   return generate_safe(weapon_id, weapon_data, schemas.WEAPON)
end

--- Validate and generate ranged weapon raw.
-- @param weapon_id string: Weapon identifier
-- @param weapon_data table: Weapon configuration
-- @return string|nil, string|nil: Generated raw data or nil, error message or nil
function GENERATOR.generate_ranged_weapon_raw_safe(weapon_id, weapon_data)
   return generate_safe(weapon_id, weapon_data, schemas.RANGED_WEAPON)
end

return GENERATOR