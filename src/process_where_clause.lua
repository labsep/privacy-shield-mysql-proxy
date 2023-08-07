package.path = package.path .. ";src/?.lua"

local trim = require("utils.trim")
local split_sql_by_space = require("utils.split_sql_by_space")
local map = require("utils.map")
local find = require("utils.find")
local encrypt = require("encrypt")

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
        condition_data.value = encrypt(
            condition_data.value,
            column_configuration
        )
    end
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

return process_where_clause