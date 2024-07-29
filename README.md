# schemconvert

Authors: A S lewis

License: LGPL 2.1

This mod reads one or more Minetest schematics (expressed as .mts files). It also accepts schematics
expressed as Lua code.

Then, it does any or all of the following things:

* Displays the contents of the schematic in the chat window / Minetest **debug.txt** file
* Swaps nodes in the schematic (e.g. swaps **default:stone** for **mymod:rock**)
* Displays a list of converted/unconverted nodes from all schematics
* Saves the schematic as a .mts and/or .lua file

Thus, this mod is useful for the following purposes:

* Updating nodes, when .mts schematics are copied from one mod to another
* A general-purpose Lua > .mts > Lua schematic converter

This mod has no gameplay value, and is only useful for developers. It has been tested on Minetest
5.4.1 - 5.6.1. It has not been tested on MS Windows.

# Enabling settings

By default, **schemconvert** imports schematics from the **/input** folder, converts nodes, then
exports the converted schematics to the **/output** folder. Other behaviours can be enabled in
Minetest settings.

If you don't enjoy fiddling with settings in Minetest's menus, then you can edit **init.lua** to
enable or disable settings directly. See the section marked **"Override settings in code"**.

The available settings are:

* Convert an original schematic into a modified schematic, swapping specified nodes (enabled by
default)
* Write the original schematic as a Lua file
* Write the converted schematic as a Lua file
* Show original schematic as Lua in the chat window
* Show converted schematic as Lua in the chat window
* Show a complete list of converted/unconverted nodes in the chat window
* Show debug messages in the debug file and the chat window (enabled by default)

# Importing schematics

There are two ways to import schematics.

Firstly, .mts schematics should be copied into the folder called **/input**. All .mts files found in
this folder are read. Files in this folder are never modified or overwritten.

*Change from earlier versions: It is no longer necessary to list all the files in files.txt*

Secondly, schematics expressed as Lua tables can be copy-pasted into the **schematics.lua** file.
The code in that file should add one or more schematics to **schemconvert.schem_table**. The
simplest way to do this is via a call to **schemconvert.add_schem()**.

Some examples of schematics expressed as Lua tables can be found in **minetest_game**, in the file
**schematic-tables.txt**. If you like, you could copy-paste the whole of that file into
schemconvert's **schematics.lua**. Don't forget to change the function calls from **mts_save()** to
**schemconvert.add_schem()**.

# Setting up node conversion

The **convert.csv** file provides a list of nodes to convert. Empty lines and lines starting with
the # character are ignored.

Lines should be in the format:

        original_node_name|converted_node_name

For example

        default:stone|mymod:rock
        default:cobble|othermod:rubble

It is not necessary for any mod besides **schemconvert** to be enabled. **schemconvert** deals with
simple strings, it does not check whether the nodes **default:stone** or **mymod:rock** actually
exist in the game.

# Other useful mods

[saveschems, by paramat and sofar](https://github.com/minetest-mods/saveschems)

Converts lua tables to .mts files

[schemedit, by Wuzzy](https://repo.or.cz/minetest_schemedit.git)

Allows players to edit and export schematics in-game

[mtsedit, by bzt](https://gitlab.com/bztsrc/mtsedit)

An interactive MTS editor with GUI, and batch mode capabilities
