local function decrypt(sql_value, encryption_configuration)
    return
        "CAST(AES_DECRYPT("
        .. sql_value
        .. ", '12345') AS "
        .. encryption_configuration.type
        .. ")"
end


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

local function trim(str)
    return string.match(str, "^%s*(.-)%s*$")
end

local function split(str, separator)
    separator = separator or "%s"

    local words = {}

    for word in string.gmatch(str, "([^" .. separator .. "]+)") do
        table.insert(words, trim(word))
    end

    return words
end

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

local function map(t, callback)
    local result = {}

    for index, value in ipairs(t) do
        table.insert(result, callback(value, index))
    end

    return result
end

local function indexof(t, value)
    for index, other_value in ipairs(t) do
        if other_value == value then
            return index
        end
    end

    return -1
end

local function find(t, filter)
    for _, other_value in ipairs(t) do
        if filter(other_value) then
            return other_value
        end
    end
end

local function filter(t, callback)
    local result = {}

    for index, value in ipairs(t) do
        if callback(value, index) then
            table.insert(result, value)
        end
    end

    return result
end

local function split_where_clause_by_operator(sql)
    local split_sql = {}
    local current_fragment = ""

    for word in sql:gmatch("[^%s]+") do
        current_fragment = trim(current_fragment .. " " .. word)

        if word == "AND" or word == "OR" then
            table.insert(split_sql, current_fragment)
            current_fragment = ""
        end
    end

    if current_fragment ~= "" then
        table.insert(split_sql, current_fragment)
    end

    return split_sql
end

local function parse_condition_data(sql)
    local words = split_sql_by_space(sql)

    local condition_data = {
        negated = false
    }

    if words[1] == "NOT" then
        condition_data.negated = true
        condition_data.column = words[2]
    else
        condition_data.column = words[1]
    end

    if condition_data.negated then
        condition_data.comparison = words[3]
        condition_data.value = words[4]
    else
        condition_data.comparison = words[2]
        condition_data.value = words[3]
    end

    if #words == 5 then
        condition_data.operator = words[5]
    end

    return condition_data
end

local function encrypt_condition_data(condition_data, column_configurations)
    local column_configuration = find(
        column_configurations,
        function(configuration)
            return configuration.name == condition_data.column
        end
    )

    if column_configuration.encrypt then
        condition_data.column= decrypt(
            condition_data.column,
            column_configuration
        )
    end
end

local function compile_where_clause_data(conditions_data)
    local sql = "WHERE "

    for _, condition_data in ipairs(conditions_data) do
        if condition_data.negated then
            sql = sql .. "NOT "
        end

        sql = sql
            .. condition_data.column
            .. " "
            .. condition_data.comparison
            .. " "
            .. condition_data.value

        if condition_data.operator then
            sql = sql .. " " .. condition_data.operator
        end
    end

    return sql
end

local function process_where_clause(sql, column_configurations)
    return map(
        split_where_clause_by_operator(sql),
        function(condition_sql)
            local condition_data = parse_condition_data(condition_sql)

            encrypt_condition_data(condition_data, column_configurations)

            return condition_data
        end
    )
end

local function compile_delete_query_data(query_data)
    local sql = "DELETE FROM " .. query_data.table

    if query_data.where then
        sql = sql .. " " .. compile_where_clause_data(query_data.where)
    end

    sql = sql .. ";"

    return sql
end

local function process_delete_query(sql, table_configurations)
    local split_sql = split(sql)
    local table_name = split_sql[3]
    local table_configuration = find(
        table_configurations,
        function(table_configuration)
            return table_configuration.name == table_name
        end
    )

    local query_data = {
        table = table_name,
    }

    local where_sql = string.match(sql, "WHERE%s(.+)")

    if where_sql then
        query_data.where = process_where_clause(
            where_sql,
            table_configuration.columns
        )
    end

    return compile_delete_query_data(query_data)
end

local function parse_insert_query_data(sql, table_configuration)
    local query_data = {
        table = table_configuration.name
    }

    local sql_between_parentheses = {}

    for sql_in_parentheses in string.gmatch(sql, "%((.-)%)") do
        table.insert(
            sql_between_parentheses,
            split_sql_by_comma(sql_in_parentheses)
        )
    end

    local columns_specified = #sql_between_parentheses == 2

    if columns_specified then
        local columns = sql_between_parentheses[1]
        local values = sql_between_parentheses[2]

        query_data.columns = map(
            columns,
            function(column_name, index)
                return {
                    name = column_name,
                    value = values[index]
                }
            end
        )
    else
        local values = sql_between_parentheses[1]

        query_data.columns = map(
            table_configuration.columns,
            function(column_configuration, index)
                return {
                    name = column_configuration.name,
                    value = values[index]
                }
            end
        )
    end

    return query_data
end

local function encrypt_insert_query_data(query_data, column_configurations)
    for _, column in ipairs(query_data.columns) do
        local column_configuration = find(
            column_configurations,
            function(column_configuration)
                return column_configuration.name == column.name
            end
        )

        if column_configuration.encrypt then
           column.value = encrypt(column.value, column_configuration)
        end
    end
end

local function compile_insert_query_data(query_data)
    local sql = "INSERT INTO " .. query_data.table

    local columns = "("
    local values = "("

    for index, column in ipairs(query_data.columns) do
        columns = columns ..  column.name
        values = values .. column.value

        if index ~= #query_data.columns then
            columns = columns .. ", "
            values = values .. ", "
        end
    end

    columns = columns .. ")"
    values = values .. ")"

    sql = sql .. " " .. columns .. " VALUES " .. values .. ";"

    return sql
end

local function process_insert_query(sql, table_configurations)
    local split_sql = split(sql)
    local table_name = split_sql[3]
    local table_configuration = find(
        table_configurations,
        function(table_configuration)
            return table_configuration.name == table_name
        end
    )

    local query_data = parse_insert_query_data(
        sql,
        table_configuration
    )

    encrypt_insert_query_data(query_data, table_configuration.columns)

    return compile_insert_query_data(query_data)
end

local function parse_update_query_data(sql, table_configuration)
    local query_data = {
        table = table_configuration.name
    }

    local set_sql =
        string.match(sql, "SET%s+(.-)%sWHERE")
        or string.match(sql, "SET%s(.+)")

    query_data.columns = map(
        map(
            split_sql_by_comma(set_sql),
            function(column_assignment_sql)
                return split(column_assignment_sql, "=")
            end
        ),
        function(split_column_assignment)
            return {
                name = split_column_assignment[1],
                value = split_column_assignment[2]
            }
        end
    )

    local where_sql = string.match(sql, "WHERE%s(.+)")

    if where_sql then
        query_data.where = process_where_clause(
            where_sql,
            table_configuration.columns
        )
    end

    return query_data
end

local function encrypt_update_query_data(query_data, column_configurations)
    for _, column in ipairs(query_data.columns) do
        local column_configuration = find(
            column_configurations,
            function(configuration)
                return configuration.name == column.name
            end
        )

        if column_configuration.encrypt then
            column.value = encrypt(column.value, column_configuration)
        end
    end
end

local function compile_update_query_data(query_data)
    local sql = "UPDATE " .. query_data.table .. " SET "

    for index, column in ipairs(query_data.columns) do
        sql = sql .. column.name .. " = " .. column.value

        if index ~= #query_data.columns then
            sql = sql .. ", "
        end
    end

    if query_data.where then
        sql = sql .. " " .. compile_where_clause_data(query_data.where)
    end

    sql = sql .. ";"

    return sql
end

local function process_update_query(sql, table_configurations)
    local split_sql = split(sql)
    local table_name = split_sql[2]
    local table_configuration = find(
        table_configurations,
        function(table_configuration)
            return table_configuration.name == table_name
        end
    )

    local query_data = parse_update_query_data(sql, table_configuration)

    encrypt_update_query_data(query_data, table_configuration.columns)

    return compile_update_query_data(query_data)
end

local function parse_select_query_data(sql, table_configuration)
    local query_data = {
        table = table_configuration.name,
        distinct = split_sql_by_space(sql)[2] == "DISTINCT"
    }

    local from_sql

    if query_data.distinct then
       from_sql = string.match(sql, "SELECT DISTINCT%s(.-)%sFROM")
    else
        from_sql = string.match(sql, "SELECT%s(.-)%sFROM")
    end

    if from_sql == "*" then
        query_data.columns = map(
            table_configuration.columns,
            function(configuration)
                return configuration.name
            end
        )
    else
        query_data.columns = split_sql_by_comma(from_sql)
    end

    local where_sql = string.match(sql, "WHERE%s(.+)")

    if where_sql then
        query_data.where = process_where_clause(
            where_sql,
            table_configuration.columns
        )
    end

    return query_data
end

local function decrypt_select_query_data(query_data, column_configurations)
    for index, column_name in ipairs(query_data.columns) do
        local column_configuration = find(
            column_configurations,
            function(configuration)
                return configuration.name == column_name
            end
        )

        if column_configuration.encrypt then
            query_data.columns[index] = decrypt(
                column_name,
                column_configuration
            )
        end
    end
end

local function compile_select_query_data(query_data)
    local sql = "SELECT "

    if query_data.distinct then
        sql = sql .. "DISTINCT "
    end

    for index, column in ipairs(query_data.columns) do
        sql = sql .. column

        if index ~= #query_data.columns then
            sql = sql .. ", "
        end
    end

    sql = sql .. " FROM " .. query_data.table

    if query_data.where then
        sql = sql .. " " .. compile_where_clause_data(query_data.where)
    end

    return sql
end

local function process_select_query(sql, table_configurations)
    local split_sql = split_sql_by_space(sql)
    local table_name_index = indexof(split_sql, "FROM") + 1
    local table_name = split_sql[table_name_index]

    local table_configuration = find(
        table_configurations,
        function(table_configuration)
            return table_configuration.name == table_name
        end
    )

    local query_data = parse_select_query_data(sql, table_configuration)

    decrypt_select_query_data(query_data, table_configuration.columns)

    return compile_select_query_data(query_data)
end

local function process_query(sql, table_configurations)
    local split_sql = split(sql)
    local command_name = split_sql[1]

    local accepted_commands = {
        INSERT = process_insert_query,
        UPDATE = process_update_query,
        DELETE = process_delete_query,
        SELECT = process_select_query
    }

    local query_processor_function = accepted_commands[command_name]

    if not process_query then
        error("Processing function not found for SQL command: " .. command_name)
    end

    local processed_query = query_processor_function(sql, table_configurations)

    return processed_query
end

local DATABASE_CONFIGURATION = {
    name = "teste",
    tables = {
        {
            name = "pacientes",
            columns = {
                {
                    name = "nome",
                    type = "VARCHAR(255)",
                    encrypt = true
                },
                {
                    name = "cpf",
                    type = "CHAR(11)",
                    encrypt = true
                },
                {
                    name = "idade",
                    type = "INT",
                    encrypt = true
                },
                {
                    name = "data_nascimento",
                    type = "DATE",
                    encrypt = true
                }
            }
        }
    }
}

function read_query(packet)
    local query = string.sub(packet, 2)
    local processed_query = process_query(query, DATABASE_CONFIGURATION.tables)
    proxy.queries:append(1, string.char(proxy.COM_QUERY) .. processed_query)
    return proxy.PROXY_SEND_QUERY
end