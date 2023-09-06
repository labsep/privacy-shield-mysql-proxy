package.path = package.path .. ";src/?.lua"

local split = require("utils.split")
local find = require("utils.find")
local map = require("utils.map")
local split_sql_by_comma = require("utils.split_sql_by_comma")
local process_where_clause = require("process_where_clause")
local encrypt = require("encrypt")
local compile_where_clause_data = require("compile_where_clause_data")

--- Parse an SQL WHERE query into a table containing its data.
--- @param sql string The SQL query.
--- @param table_configuration table The encryption configuration for the SQL table.
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

--- Add encryption SQL syntax to an UPDATE query's data.
--- @param query_data table The table containing the data of the SQL query.
--- @param column_configurations table A table of encryption configurations for each column in the table.
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

--- Compile parsed SQL WHERE query data back into an SQL query.
--- @param query_data table The table containing the data of the SQL query.
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

--- Process an SQL WHERE query and return a modified query with encryption/decryption syntax.
--- @param sql string The SQL query.
--- @param table_configurations table The encryption configurations for each SQL table in the database.
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

return process_update_query