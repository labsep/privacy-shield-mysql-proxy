--- @param t table The table to search.
--- @param value any The value to find the index of.
local function indexof(t, value)
    for index, other_value in ipairs(t) do
        if other_value == value then
            return index
        end
    end

    return -1
end

return indexof