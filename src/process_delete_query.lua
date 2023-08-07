package.path = package.path .. ";src/?.lua"

local split = require("utils.split")
local find = require("utils.find")
local process_where_clause = require("process_where_clause")
local compile_where_clause_data = require("compile_where_clause_data")

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

return process_delete_query