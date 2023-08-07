package.path = package.path .. ";src/utils/?.lua"

local trim = require("trim")

local function split_sql_by_space(sql)
    local result = {}
    local in_quotes = false
    local current_word = ""

    for index = 1, #sql do
        local char = sql:sub(index, index)

        if char == "'" or char == '"' then
            in_quotes = not in_quotes
        end

        if char == " " and not in_quotes then
            if #current_word > 0 then
                table.insert(result, trim(current_word))
                current_word = ""
            end
        else
            current_word = current_word .. char
        end
    end

    if #current_word > 0 then
        table.insert(result, trim(current_word))
    end

    return result
end

return split_sql_by_space