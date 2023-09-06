--- Wrap a value with SQL encryption syntax.
--- @param sql_value string The value to encrypt.
--- @param encryption_configuration table The encryption configuration for this column. 
local function encrypt(sql_value, encryption_configuration)
    if
        not string.find(encryption_configuration.type, "VARCHAR")
        and not string.find(encryption_configuration.type, "CHAR")
        and encryption_configuration.type ~= "DATE"
    then
        sql_value = "CAST(" .. sql_value .. " AS CHAR)"
    end

    return "AES_ENCRYPT(" .. sql_value .. ", '12345')"
end

return encrypt