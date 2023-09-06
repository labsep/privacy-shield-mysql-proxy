local EXAMPLE_ENCRYPTION_KEY = "'12345'"

--- Wrap a value with SQL decryption syntax.
--- @param sql_value string The value to decrypt.
--- @param encryption_configuration table The encryption configuration for this column.
local function decrypt(sql_value, encryption_configuration)
    return
        "CAST(AES_DECRYPT("
        .. sql_value
        .. "," .. EXAMPLE_ENCRYPTION_KEY .. ") AS "
        .. encryption_configuration.type
        .. ")"
end

return decrypt