package.path = package.path .. ";src/?.lua"

local split = require("utils.split")
local split_sql_by_comma = require("utils.split_sql_by_comma")
local find = require("utils.find")
local map = require("utils.map")
local encrypt = require("encrypt")

--- Parse an SQL INSERT query into a table containing its data.
--- @param sql string The SQL query.
--- @param table_configuration table The encryption configuration for the SQL table.
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

--- Add encryption SQL syntax to an INSERT query's data.
--- @param query_data table The table containing the data of the SQL query.
--- @param column_configurations table A table of encryption configurations for each column in the table.
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

--- Compile parsed SQL INSERT query data back into an SQL query.
--- @param query_data table The table containing the data of the SQL query.
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

--- Process an SQL INSERT query and return a modified query with encryption/decryption syntax.
--- @param sql string The SQL query.
--- @param table_configurations table The encryption configurations for each SQL table in the database.
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

return process_insert_query
