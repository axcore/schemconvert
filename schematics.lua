---------------------------------------------------------------------------------------------------
-- schemconvert mod by A S Lewis
-- License: LGPL 2.1
---------------------------------------------------------------------------------------------------

-- You can add LUA schematics to this file
-- They will be processed together with the .mts files loaded from ../input
--
-- For some examples of LUA schematics, see the schematic_tables.txt file in minetest_game
--
-- Each LUA schematic should be added with a function call in the usual format:
--
--  schemconvert.add_schem("apple_tree", {
--      size = {x = 7, y = 8, z = 7},
--      data = {
--          _, _, _, _, _, _, _,
--          _, _, _, _, _, _, _,
--          _, _, _, _, _, _, _,
--          -- ...and so on
--      },
--  })
--
-- You could also write to the table directly, if you prefer:
--
--  schemconvert.schem_table["apple_tree"] = {
--      size = {x = 7, y = 8, z = 7},
--      data = {
--          _, _, _, _, _, _, _,
--          _, _, _, _, _, _, _,
--          _, _, _, _, _, _, _,
--          -- ...and so on
--      },
--  }
