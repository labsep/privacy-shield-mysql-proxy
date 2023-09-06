--- @param t table The table to filter.
--- @param callback function The callback to filter the table with.
local function filter(t, callback)
    local result = {}

    for index, value in ipairs(t) do
        if callback(value, index) then
            table.insert(result, value)
        end
    end

    return result
end

return filter