---------------------------------------------------------------------------------------------------
-- schemconvert mod by A S Lewis
-- License: LGPL 2.1
---------------------------------------------------------------------------------------------------

local S = minetest.get_translator(minetest.get_current_modname())

schemconvert = {}
schemconvert.name = "schemconvert"
schemconvert.ver_max = 1
schemconvert.ver_min = 8
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

-- Convert an original schematic into a modified schematic, swapping specified nodes
local do_convert_flag = minetest.settings:get_bool("schemconvert_do_convert_flag", true)

-- Write the original schematic as a Lua file
local write_original_lua_flag =
        minetest.settings:get_bool("schemconvert_write_original_lua_flag", false)
-- Write the converted schematic as a Lua file
local write_converted_lua_flag =
        minetest.settings:get_bool("schemconvert_write_converted_lua_flag", false)

-- Show original schematic as Lua in the chat window
local show_original_lua_flag =
    minetest.settings:get_bool("schemconvert_show_original_lua_flag", false)
-- Show converted schematic as Lua in the chat window
local show_converted_lua_flag =
        minetest.settings:get_bool("schemconvert_show_converted_lua_flag", false)
-- Show a complete list of converted/unconverted nodes in the chat window
local show_summary_flag = minetest.settings:get_bool("schemconvert_show_summary_flag", false)
-- Show debug messages in the debug file and the chat window
local show_debug_flag = minetest.settings:get_bool("schemconvert_show_debug_flag", true)

-- Override settings in code because LOL minetest
--do_convert_flag = true
--write_original_lua_flag = false
--write_converted_lua_flag = false
--show_original_lua_flag = false
--show_converted_lua_flag = false
--show_summary_flag = false
--show_debug_flag = true

---------------------------------------------------------------------------------------------------
-- Local functions (debug messages)
---------------------------------------------------------------------------------------------------

local function show_info(msg)

    -- Show information, if allowed
    
    if show_debug_flag then
        minetest.log("[SCHEMCONVERT] " .. msg)
    end

end

local function show_error(msg)

    -- Show an error message, if allowed
    
    if show_debug_flag then
        minetest.log("[SCHEMCONVERT] [ERROR] " .. msg)
    end

end

---------------------------------------------------------------------------------------------------
-- Local functions (file handling)
---------------------------------------------------------------------------------------------------

local function file_exists(path)

    -- Adapted from https://stackoverflow.com/questions/11201262/how-to-read-data-from-a-file-in-lua
    -- Check the specified file exists

    local f = io.open(path, "rb")
    if f then
        f:close()
    end

    return f ~= nil

end

local function read_csv(local_path)

    -- Read a CSV file, which we assume has two columns, returning its contents as a table
    -- Return an empty table if the file does not exist or if it is empty
    -- Ignore empty lines, and lines beginning with the # character

    if not file_exists(local_path) then
        return {}
    end
    
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

---------------------------------------------------------------------------------------------------
-- Local functions (handle display of tables)
---------------------------------------------------------------------------------------------------

local function tprint(t, indent)

    -- Adapted from https://stackoverflow.com/questions/41942289/display-contents-of-tables-in-lua
    -- Format a table for display in minetest's debug.txt file and/or chat window

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
    -- Display a table in minetest's debug.txt file and/or chat window

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

local function sort_table(t)

    -- Return a list of keys in a table, sorted alphabetically

    local list = {}
    for key in pairs(t) do
        table.insert(list, key)
    end

    table.sort(list)

    return list

end

---------------------------------------------------------------------------------------------------
-- Local functions (handle schematics)
---------------------------------------------------------------------------------------------------

local function convert_nodes(schem_table)

    -- Convert old nodes in a schematic table to new nodes
    
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

local function save_mts(schem_table, output_path)

    -- Save a schematic as .mts

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

local function save_lua(schem_table, output_path)

    -- Save a schematic as .lua

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
-- Local functions (schematic conversion)
---------------------------------------------------------------------------------------------------

local function convert_mts()

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
            if schem_table ~= nil then
            
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

    end

end

local function convert_lua()

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

end

---------------------------------------------------------------------------------------------------
-- Local functions (setup)
---------------------------------------------------------------------------------------------------

local function read_schematics()

    -- Read the .mts file list, ignoring anything that isn't an .mts file
    local this_list = minetest.get_dir_list(mod_path .. "/input", false)
    for _, path in ipairs(this_list) do

        if string.match(path, "^.+(%..+)$") == ".mts" then
            table.insert(file_list, path)
        end

    end

    show_info(S("Number of .mts files found: @1", #file_list))

    -- Read Lua schematics into a table
    dofile(mod_path .. "/schematics.lua")

    local count = 0
    for k, v in pairs(schemconvert.schem_table) do
        count = count + 1
    end

    show_info(S("Number of Lua schematics read from schematics.lua: @1", count))

end

local function read_convert_nodes()

    -- Read the node conversion table. Every line in the CSV file should be in the form
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

end

local function show_results()

    -- After all conversion is complete, show full results (if allowed)
    
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

end

---------------------------------------------------------------------------------------------------
-- Shared functions (import schematics directly from Lua)
---------------------------------------------------------------------------------------------------

function schemconvert.add_schem(name, schem_table)

    -- Called from schematics.lua to add a Lua schematic to our table of schematics,
    --      schemconvert.schem_table
    -- The code there could easily add a key/value pair to the table, but usually it's simpler just
    --      to call this function
    -- (Specifically, the list of schematics in minetest-game, schematic_tables.txt, uses calls to
    --      that modpack's mts_save(), so it is convenient to copy paste schematics from that file
    --      into our schematics.lua, with all mts_save() calls replaced with
    --      schemconvert.add_schem() calls)

    schemconvert.schem_table[name] = schem_table

end

---------------------------------------------------------------------------------------------------
-- Main code
---------------------------------------------------------------------------------------------------

-- Read the file list, files.txt
read_schematics()
-- Read the node conversion list, convert.csv
read_convert_nodes()

-- Convert each .mts schematic
convert_mts()
-- Convert each Lua schematic
convert_lua()

-- Show results
show_info(S("Number of .mts files converted: @1", mts_count))
show_info(S("Number of Lua schematics converted: @1", schem_count))
show_info(S("Number of conversion errors: @1", error_count))
show_results()
