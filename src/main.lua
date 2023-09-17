local process_insert_query = require("process_insert_query")
local process_update_query = require("process_update_query")
local process_delete_query = require("process_delete_query")
local process_select_query = require("process_select_query")
local split = require("utils.split")

local DATABASE_CONFIGURATION = {
    name = "labsep",
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

    if not query_processor_function then
        error("Query processing function not found for SQL command: " .. command_name)
    end

    local processed_query = query_processor_function(sql, table_configurations)

    return processed_query
end

--- MySQL Proxy function that is triggered when queries are received.
function read_query(packet)
    local query = string.sub(packet, 2)

    if
        proxy.connection.client.default_db ~= ""
        and string.byte(packet) == proxy.COM_QUERY
    then
        local processed_query = process_query(query, DATABASE_CONFIGURATION.tables)
        proxy.queries:append(1, string.char(proxy.COM_QUERY) .. processed_query)
        return proxy.PROXY_SEND_QUERY
    end
end
