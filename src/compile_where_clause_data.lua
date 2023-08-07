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

return compile_where_clause_data