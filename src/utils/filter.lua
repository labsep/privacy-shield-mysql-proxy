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