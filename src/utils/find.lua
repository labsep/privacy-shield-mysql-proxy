--- @param t table The table to search.
--- @param filter function The filter function use.
local function find(t, filter)
    for _, other_value in ipairs(t) do
        if filter(other_value) then
            return other_value
        end
    end
end

return find