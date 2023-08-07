package.path = package.path .. ";src/utils/?.lua"

local trim = require("trim")

local function split(str, separator)
    separator = separator or "%s"

    local words = {}

    for word in string.gmatch(str, "([^" .. separator .. "]+)") do
        table.insert(words, trim(word))
    end

    return words
end

return split