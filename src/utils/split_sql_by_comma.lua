local trim = require("trim")

--- Split an SQL string by comma.
--- Takes into consideration not to split SQL strings that contain commas.
--- @param sql string The SQL string to split.
local function split_sql_by_comma(sql)
    local result = {}
    local current = ""
    local in_single_quotes = false
    local in_double_quotes = false

    for i = 1, #sql do
        local char = sql:sub(i, i)

        if char == "'" and not in_double_quotes then
            in_single_quotes = not in_single_quotes
        elseif char == '"' and not in_single_quotes then
            in_double_quotes = not in_double_quotes
        end

        if char == "," and not in_single_quotes and not in_double_quotes then
            table.insert(result, trim(current))
            current = ""
        else
            current = current .. char
        end
    end

    table.insert(result, trim(current))

    return result
end

return split_sql_by_comma