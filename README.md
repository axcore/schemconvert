# schemconvert

Authors: A S lewis

Contributors: [Gael-de-Sailly](https://github.com/Gael-de-Sailly)

License: LGPL 2.1

This mod reads one or more minetest schematics (.mts files). It also accepts schematics as Lua
tables.

Then, it does any or all of the following things:

* Displays the contents of the schematic in the chat window/debug file
* Swaps nodes in the schematic (e.g. swaps **default:stone** for **mymod:rock**)
* Saves the schematic as a .mts and/or .lua file

Thus, this mod is useful for the following purposes:

* Updating nodes, when .mts schematics are copied from one mod to another
* A general-purpose Lua > .mts > Lua schematic converter

This mod has no gameplay value, and is only useful for developers. It has been tested on Minetest
5.4.1. It has not been tested on MS Windows.

# Importing schematics

Open the the **init.lua** file in your preferred text editor. There are some flags there that can be
modified to change the mod's behaviour. (Since this mod is for developers, we assume you don't need
the crutch of reading from a **settingtypes.txt** file).

There are two ways to import schematics.

Firstly, .mts schematics should be copied into the folder called **input**. Files in this folder are
never modified or overwritten.

Unfortunately, there is no easy way for Lua to get a list of files from a folder; therefore we have
to write the list ourselves in **files.txt**. This should contain one file per line. Empty lines
and lines starting with the # character are ignored.

There is a shortcut: if a file called **test.mts** exists, it will be loaded, regardless of whether
it is mentioned in **files.txt**.

Secondly, Lua tables can be copy-pasted into the **schematics.lua** file.

You can find some examples of schematics in the form of Lua tables in **minetest-game**, in the file
**schematic-tables.txt**. If you like, you could copy-paste the whole of that file into
**schematics.lua**. Don't forget to change the function calls from **mts_save()** to
**schemconvert.add_schem()**.

# Setting up node conversion

Next, the **convert.csv** file provides a list of nodes to convert. Once again, empty lines and
lines starting with the # character are ignored.

Lines should be in the format:

        original_node_name|converted_node_name

For example

        default:stone|mymod:rock
        default:cobble|othermod:rubble

It is not necessary for either mod to be loaded; **schemconvert** deals with simple strings, it does
not check whether the nodes **default:stone** or **mymod:rock** actually exist in the game.

# How to use

Start the game (with **schemconvert** enabled). Converted files are written to the **output**
folder.

You can check the results of your work by changing the flags (as described above) to
write the orginal and/or converted files as .lua files, so the changes can be inspected visually.

# Comparable mods

[saveschems, by paramat and sofar](https://github.com/minetest-mods/saveschems)

Converts lua tables to .mts files

[schemedit, by Wuzzy](https://repo.or.cz/minetest_schemedit.git)

Allows players to edit and export schematics in-game

[mtsedit, by bzt](https://gitlab.com/bztsrc/mtsedit)

An interactive MTS editor with GUI, and batch mode capabilities
