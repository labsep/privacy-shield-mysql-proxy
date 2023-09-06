--- @param t table The table to execute the map on.
--- @param callback function The callback to execute the map with.
local function map(t, callback)
    local result = {}

    for index, value in ipairs(t) do
        table.insert(result, callback(value, index))
    end

    return result
end

return map