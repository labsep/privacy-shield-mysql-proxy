local function pprint(value)
    if type(value) == "table" then
        print("{")

        for key, table_value in pairs(value) do
            print("    " .. key .. ":" .. " " .. tostring(table_value))
        end

        print("}")

        return
    end

    print(value)
end

return pprint