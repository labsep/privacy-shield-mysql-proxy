local function trim(str)
    return string.match(str, "^%s*(.-)%s*$")
end

return trim