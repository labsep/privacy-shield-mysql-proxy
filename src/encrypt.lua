local function encrypt(sql_value, encryption_configuration)
    if
        encryption_configuration.type ~= "VARCHAR"
        and encryption_configuration.type ~= "CHAR"
    then
        sql_value = "CAST(" .. sql_value .. " AS CHAR)"
    end

    return "AES_ENCRYPT(" .. sql_value .. ", '12345')"
end

return encrypt