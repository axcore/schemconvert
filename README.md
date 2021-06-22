# schemconvert

Authors: A S lewis

Contributors: [Gael-de-Sailly](https://github.com/Gael-de-Sailly)

License: LGPL 2.1

This mod reads minetest schematics (.mts files), and does any or all of the following things:

* Displays the contents of the schematic in the chat window/debug file
* Converts the contents of the schematic to a .lua file
* Swaps nodes in the schematic (e.g. swaps **default:stone** for **mymod:rock**), and saves the
modified schematic either as .mts or as .lua

This mod has no gameplay value, and is only useful for developers.

This mod has been tested on Minetest 5.4.1. It has not been tested on MS Windows.

# How to use

Firstly, open the the **init.lua** file in your preferred text editor. There are some flags there
that can be modified to change the mod's behaviour. (Since this mod is for developers, we assume you
don't need the crutch of reading from a **settingtypes.txt** file).

The default behaviour is to convert original .mts file, but not to write additional .lua files.

Next, there is a folder called **input**. Copy the .mts files into this folder. Ffiles in this
folder are never modified.

Unfortunately, there is no easy way for Lua to get a list of files from a folder; therefore we have
to write the list ourselves in **files.txt**. This should contain one file per line. Empty lines
and lines starting with the # character are ignored.

There is a shortcut: if a file called **test.mts** exists, it will be loaded, regardless of whether
it is mentioend in **files.txt**.

Next, the **convert.csv** file provides a list of nodes to convert. Once again, empty lines and
lines starting with the # character are ignored.

Lines should be in the format:

        original_node_name|converted_node_name

For example

        default:stone|mymod:rock
        default:cobble|othermod:rubble

It is not necessary for either mod to be loaded; **mtsconvert** deals with simple strings, it does
not check whether the nodes **default:stone** or **mymod:rock** actually exist in the game.

Now, start the game (with **mtsconvert** enabled). The converted .mts files are written to the
**output** folder.

Nervous users can check the results of their work by changing the flags (as described above) to
write the orginal and/or converted files as .lua files, so the changes can be inspected visually.
The .lua files are also written to the **output** folder.

# Comparable mods

[saveschems, by paramat and sofar](https://github.com/minetest-mods/saveschems)

Converts lua tables to .mts files

[schemedit, by Wuzzy](https://repo.or.cz/minetest_schemedit.git)

Allows players to edit and export schematics in-game
