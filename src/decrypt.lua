local function decrypt(sql_value, encryption_configuration)
    return
        "CAST(AES_DECRYPT("
        .. sql_value
        .. ") AS "
        .. encryption_configuration.type
        .. ", '12345')"
end

return decrypt