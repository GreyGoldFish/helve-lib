--@ module=true

function get_subtype_token(item)
    local subtype_id = item:getSubtype()
    if subtype_id == -1 then return nil end

    local def = dfhack.items.getSubtypeDef(item:getType(), subtype_id)
    return def and def.id
end

return {
    get_subtype_token = get_subtype_token
}
