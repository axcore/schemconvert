---------------------------------------------------------------------------------------------------
-- schemconvert mod by A S Lewis
-- Licence: LGPL 2.1
---------------------------------------------------------------------------------------------------

local S = minetest.get_translator(minetest.get_current_modname())

schemconvert = {}
schemconvert.name = "schemconvert"
schemconvert.ver_max = 1
schemconvert.ver_min = 5
schemconvert.ver_rev = 0

local mod_path = minetest.get_modpath(minetest.get_current_modname())

local file_list = {}
schemconvert.schem_table = {}
local convert_table = {}
local check_table = {}
local converted_table = {}
local not_converted_table = {}

local mts_count = 0
local schem_count = 0
local error_count = 0

-- If enabled, show info/error messages in the chat window and debug file
local show_msg_flag = true

-- If enabled, the original .mts file is converted to a new .mts file, in which certain nodes
--      have been swapped for other nodes
local do_convert_flag = true

-- If enabled, the original .mts file is written as lua, so it can be compared with the converted
--      file
local write_original_lua_flag = false
-- If enabled, the converted .mts file is also written as lua, so it can be checked
local write_converted_lua_flag = false

-- If enabled, the original .mts file is displayed (as lua) in the chat window
local show_original_lua_flag = false
-- If enabled, the converted .mts file is displayed (as lua) in the chat window
local show_converted_lua_flag = false

-- If enabled, show a complete list of nodes that were convertd, and a complete list of nodes that
--      were not converted
local show_summary_flag = true

---------------------------------------------------------------------------------------------------
-- Handle messages
---------------------------------------------------------------------------------------------------

local function show_info(msg)

    if show_msg_flag then
        minetest.log("[SCHEMCONVERT] " .. msg)
    end

end

local function show_error(msg)

    if show_msg_flag then
        minetest.log("[SCHEMCONVERT] [ERROR] " .. msg)
    end

end

---------------------------------------------------------------------------------------------------
-- Helper functions
---------------------------------------------------------------------------------------------------

-- See if the file exists
local function file_exists(path)

    -- Adapted from https://stackoverflow.com/questions/11201262/how-to-read-data-from-a-file-in-lua

    local f = io.open(path, "rb")
    if f then
        f:close()
    end

    return f ~= nil

end

-- Get all lines from a file, return an empty list/table if the file does not exist
-- Ignore empty lines, and lines beginning with the # character
-- If a pattern is specified, ignore non-matching lines
local function lines_from(local_path, match_pattern)

    -- Adapted from https://stackoverflow.com/questions/11201262/how-to-read-data-from-a-file-in-lua

    if not file_exists(local_path) then return {} end

    local lines = {}
    for line in io.lines(local_path) do

        if string.match(line, "%a") and
                line:sub(1,1) ~= "#" and
                (match_pattern == nil or string.match(line, match_pattern)) then

            lines[#lines + 1] = line

        end

    end

    return lines

end

-- Read a CSV file, returning its contents as a table. Ignore empty lines, and lines beginning with
--      the # character
local function read_csv(local_path)

    -- Adapted from lib_materials/csv.lua

    local file = io.open(local_path, "r")
    local return_table = {}
    local separator = "|"

    for line in file:lines() do

        if line:sub(1,1) ~= "#" and line:find("[^%" .. separator .. "% ]") then

            local mini_table = line:split(separator, true)
            return_table[mini_table[1]] = mini_table[2]

        end

    end

    return return_table

end

-- Format a table for display in minetest's debug.txt file
local function tprint(t, indent)

    -- Adapted from https://stackoverflow.com/questions/41942289/display-contents-of-tables-in-lua

    if not indent then indent = 0 end

    local toprint = "{\r\n"
    indent = indent + 4
    for k, v in pairs(t) do

        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            toprint = toprint .. k ..  " = "
        end

        if (type(v) == "number") then
            toprint = toprint .. v .. ",\r\n"
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. v .. "\",\r\n"
        elseif (type(v) == "table") then
            toprint = toprint .. tprint(v, indent) .. ",\r\n"
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
        end

    end

    toprint = toprint .. string.rep(" ", indent - 4) .. "}"
    return toprint

end

local function print_table(t, optional_title)

    -- Adapted from https://stackoverflow.com/questions/41942289/display-contents-of-tables-in-lua

    -- Basic checks
    if t == nil then

        show_error(S("Cannot print an unspecified table"))
        return

    elseif type(t) == "string" then

        show_error(S("Cannot print a string as a table"))
        return

    else

        -- Print the table
        local output = "\r\n"
        if optional_title then
            output = output .. optional_title .. "\r\n"
        end

        output = output .. tprint(t)

        minetest.log(output)

    end

end

-- Return a list of keys in a table, sorted alphabetically

local function sort_table(t)

    local list = {}
    for key in pairs(t) do
        table.insert(list, key)
    end

    table.sort(list)

    return list

end

-- Add a Lua schematic
function schemconvert.add_schem(name, schem_table)

    -- Called from schematics.lua
    -- The code there could easily add a key/value pair to schemconvert.schem_table, but usually
    --      it's preferable to use a function call
    -- (Specifically, the official minetest-game schematic list uses mts_save(), so that code could
    --      be copy-pasted into our schematics.lua, with just the function name changed)

    schemconvert.schem_table[name] = schem_table

end

-- Convert old nodes in a schematic table to new nodes
local function convert_nodes(schem_table)

    for i, mini_table in ipairs(schem_table.data) do

        if convert_table[mini_table.name] ~= nil then

            -- (Keep track of which convertable nodes have been found at least once)
            check_table[mini_table.name] = nil

            -- Convert this node
            mini_table.name = convert_table[mini_table.name]
            schem_table.data[i] = mini_table

            -- (Show converted nodes at the end, if required)
            if converted_table[mini_table.name] == nil then
                converted_table[mini_table.name] = 1
            else
                converted_table[mini_table.name] = converted_table[mini_table.name] + 1
            end

            else

            if not_converted_table[mini_table.name] == nil then
                not_converted_table[mini_table.name] = 1
            else
                not_converted_table[mini_table.name] = not_converted_table[mini_table.name] + 1
            end

        end

    end

end

-- Save a schematic as .mts
local function save_mts(schem_table, output_path)

    local mts_data = minetest.serialize_schematic(schem_table, "mts", {})
    local mts_output = io.open(output_path, "w")
    if not mts_data or not mts_output then

        show_error(S("Unable to save .mts file @1", output_path))
        return false

    else

        mts_output:write(mts_data)
        mts_output:flush()
        mts_output:close()
        return true

    end

end

-- Save a schematic as .lua
local function save_lua(schem_table, output_path)

    local lua_data = minetest.serialize_schematic(schem_table, "lua", {})
    local lua_output = io.open(output_path, "w")
    if not lua_data or not lua_output then

        show_error(S("Unable to save .lua file @1", output_path))
        return false

    else

        lua_output:write(lua_data)
        lua_output:flush()
        lua_output:close()

    end

end

---------------------------------------------------------------------------------------------------
-- Read schematics
---------------------------------------------------------------------------------------------------

-- Read the file list, ignoring anything that isn't an .mts file
file_list = lines_from(mod_path .. "/files.txt", ".mts$")
-- Shortcut: if a file called "test.mts" exists, add it to the list
if file_exists(mod_path .. "/input/test.mts") then

    local match_flag = false
    for _, value in ipairs(file_list) do

        if value == "test.mts" then

            match_flag = true
            break

        end

    end

    if not match_flag then
        table.insert(file_list, "test.mts")
    end

end

show_info(S("Number of .mts files specified: @1", #file_list))

-- Read Lua schematics into a table
dofile(mod_path .. "/schematics.lua")

local count = 0
for k, v in pairs(schemconvert.schem_table) do
    count = count + 1
end

show_info(S("Number of Lua schematics specified: @1", count))

---------------------------------------------------------------------------------------------------
-- Read conversion table
---------------------------------------------------------------------------------------------------

-- Read the conversion table. Every line in the CSV file should be in the form
--      original_node|replacement_node
-- For example
--      default:stone|mymod:rock
-- This produces a table in the form
--      convert_table["default:stone"] = "mymod:rock"
convert_table = read_csv(mod_path .. "/convert.csv")
-- (Every time a convertable not is found, remove it from this table)
check_table = table.copy(convert_table)

local count = 0
for k, v in pairs(convert_table) do
    count = count + 1
end

show_info(S("Number of convertable nodes specified: @1", tostring(count)))

---------------------------------------------------------------------------------------------------
-- Convert schematics
---------------------------------------------------------------------------------------------------

-- Convert each MTS schematic, one at a time
for _, local_path in ipairs(file_list) do

    local input_path = mod_path .. "/input/" .. local_path
    local output_path = mod_path .. "/output/" .. local_path
    local input_lua_path = mod_path .. "/output/" .. local_path .. ".input.lua"
    local output_lua_path = mod_path .. "/output/" .. local_path .. ".output.lua"

    if not file_exists(input_path) then

        show_info(S("Missing file: @1", input_path))
        error_count = error_count + 1

    else

        -- Read the original .mts file
        local schem_table = minetest.read_schematic(input_path, {})
        -- Write/display the original .mts file as lua, if required
        if write_original_lua_flag then
            save_lua(schem_table, input_lua_path)
        end
        if show_original_lua_flag then
            print_table(schem_table, S("Contents of file @1", input_path))
        end

        -- Convert old nodes to new
        convert_nodes(schem_table)

        -- Save the converted .mts file
        if do_convert_flag then

            if not save_mts(schem_table, output_path) then
                error_count = error_count + 1
            else
                mts_count = mts_count + 1
            end

        end

        -- Write/display the converted .mts file as lua, if required
        if write_converted_lua_flag then
            save_lua(schem_table, output_lua_path)
        end
        if show_converted_lua_flag then
            print_table(schem_table, S("Contents of file @1", output_path))
        end

    end

end

-- Convert each Lua schematic, one at a time
for name, schem_table in pairs(schemconvert.schem_table) do

    local output_path = mod_path .. "/output/" .. name .. ".mts"
    local input_lua_path = mod_path .. "/output/" .. name .. ".input.lua"
    local output_lua_path = mod_path .. "/output/" .. name .. ".output.lua"

    -- Write/display the original .lua schematic, if required
    if write_converted_lua_flag then
        save_lua(schem_table, input_lua_path)
    end
    if show_original_lua_flag then
        print_table(schem_table, S("Contents of schematic @1", name))
    end

    -- Convert old nodes to new
    convert_nodes(schem_table)

    -- Save the converted .mts file
    if do_convert_flag then

        if not save_mts(schem_table, output_path) then
            error_count = error_count + 1
        else
            schem_count = schem_count + 1
        end

    end

    -- Write/display the converted .mts file as lua, if required
    if write_converted_lua_flag then
        save_lua(schem_table, output_lua_path)
    end
    if show_converted_lua_flag then
        print_table(schem_table, S("Contents of schematic @1", name))
    end

end

---------------------------------------------------------------------------------------------------
-- Show results
---------------------------------------------------------------------------------------------------

show_info(S("Number of .mts files converted: @1", mts_count))
show_info(S("Number of Lua schematics converted: @1", schem_count))
show_info(S("Number of conversion errors: @1", error_count))

if show_summary_flag then

    if not next(converted_table) then

        show_info(S("Converted nodes: none"))

    else

        show_info(S("Converted nodes:"))

        for _, k in pairs(sort_table(converted_table)) do
            show_info("   " .. k .. ": " .. converted_table[k])
        end

    end

    if not next(not_converted_table) then

        show_info(S("Non-converted nodes: none"))

    else

        show_info(S("Non-converted nodes:"))

        for _, k in pairs(sort_table(not_converted_table)) do
            show_info("   " .. k .. ": " .. not_converted_table[k])
        end

    end

    if not next(check_table) then

        show_info(S("Convertable nodes not found: none"))

    else

        show_info(S("Convertable nodes not found:"))

        for _, k in pairs(sort_table(check_table)) do
            show_info("   " .. check_table[k])
        end

    end

end
