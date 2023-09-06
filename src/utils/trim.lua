--- @param str string The string to trim.
--- @return string
local function trim(str)
    return string.match(str, "^%s*(.-)%s*$")
end

return trim