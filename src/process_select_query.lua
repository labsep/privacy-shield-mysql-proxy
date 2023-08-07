package.path = package.path .. ";src/?.lua"

local split_sql_by_space = require("split_sql_by_space")
local find = require("utils.find")
local indexof = require("utils.indexof")
local process_where_clause = require("process_where_clause")
local map = require("utils.map")
local split_sql_by_comma = require("split_sql_by_comma")
local decrypt = require("decrypt")
local compile_where_clause_data = require("compile_where_clause_data")

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

return process_select_query