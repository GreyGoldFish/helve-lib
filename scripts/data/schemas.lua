local schemas = {}
local weapon_schemas = require("data.schemas.weapon")

-- Weapon schemas
schemas.WEAPON = weapon_schemas.weapon()
schemas.ATTACK = weapon_schemas.attack()
schemas.ATTACK_PREPARE_AND_RECOVER = weapon_schemas.attack_prepare_and_recover()
schemas.RANGED_WEAPON = weapon_schemas.ranged_weapon()
schemas.SHOOT_FORCE_REQUIRES = weapon_schemas.shoot_force_requires()
schemas.LOADED_NOCKED = weapon_schemas.loaded_nocked()

-- TODO: Add unit tests for schema validation, and consider adding a way to validate data without throwing errors (e.g. returning a list of validation errors instead).

-- Validate data against a schema
-- @param data table: Data to validate
-- @param schema table: Schema to validate against  
-- @param context string: Context for error messages
-- @return boolean: True if valid, throws error if invalid
function schemas.validate(data, schema, context)
    context = context or "data"
    
    -- Basic type check
    if type(data) ~= "table" then
        error(string.format("Validation Error: %s must be a table, got %s", context, type(data)))
    end
    
    -- Handle schema extension
    local effective_schema = schema
    if schema.extends then
        local parent_schema = schemas[schema.extends]
        if not parent_schema then
            error(string.format("Validation Error: %s extends unknown schema '%s'", context, schema.extends))
        end
        
        -- Merge: copy parent, then override with child
        effective_schema = {
            fields = parent_schema.fields and shallow_copy(parent_schema.fields) or {},
            required = parent_schema.required and shallow_copy(parent_schema.required) or {},
            enums = parent_schema.enums and shallow_copy(parent_schema.enums) or {}
        }
        
        if schema.fields then
            for k, v in pairs(schema.fields) do
                effective_schema.fields[k] = v
            end
        end
        if schema.enums then
            for k, v in pairs(schema.enums) do
                effective_schema.enums[k] = v
            end
        end
        if schema.required then
            for _, field in ipairs(schema.required) do
                table.insert(effective_schema.required, field)
            end
        end
    end
    
    -- Validate required fields
    if effective_schema.required then
        for _, field in ipairs(effective_schema.required) do
            if data[field] == nil then
                error(string.format("Validation Error: %s missing required field '%s'", context, field))
            end
        end
    end
    
    -- Validate fields
    if effective_schema.fields then
        for field_name, field_type in pairs(effective_schema.fields) do
            local value = data[field_name]
            if value ~= nil then
                local field_context = string.format("%s.%s", context, field_name)
                
                -- Type validation
                if type(value) ~= field_type then
                    error(string.format("Validation Error: %s must be %s, got %s", field_context, field_type, type(value)))
                end
                
                -- Enum validation
                if effective_schema.enums and effective_schema.enums[field_name] then
                    local valid_values = effective_schema.enums[field_name]
                    local is_valid = false
                    for _, enum_value in pairs(valid_values) do
                        if value == enum_value then
                            is_valid = true
                            break
                        end
                    end
                    if not is_valid then
                        local valid_list = {}
                        for _, enum_value in pairs(valid_values) do
                            table.insert(valid_list, tostring(enum_value))
                        end
                        error(string.format("Validation Error: %s must be one of [%s], got '%s'", 
                            field_context, table.concat(valid_list, ", "), tostring(value)))
                    end
                end
                
                -- Nested validation
                if field_type == "table" then
                    if field_name == "attacks" then
                        -- Array of attacks
                        for i, attack in ipairs(value) do
                            schemas.validate(attack, schemas.ATTACK, string.format("%s[%d]", field_context, i))
                        end
                    elseif field_name == "attack_prepare_and_recover" then
                        schemas.validate(value, schemas.ATTACK_PREPARE_AND_RECOVER, field_context)
                    elseif field_name == "shoot_force_requires" then
                        schemas.validate(value, schemas.SHOOT_FORCE_REQUIRES, field_context)
                    elseif field_name == "loaded_nocked" then
                        schemas.validate(value, schemas.LOADED_NOCKED, field_context)
                    end
                end
            end
        end
    end
    
    return true
end
    
return schemas