<div align="center">

![LuaRT Studio][title] 

[![Lua VM 5.4.4](https://badgen.net/badge/Lua%20VM/5.4.4/yellow)](https://www.lua.org/)
![Windows](https://badgen.net/badge/Windows/Vista%20and%20later/blue?icon=windows)
[![LuaRT Studio license](https://badgen.net/badge/License/MIT/green)](#license)

![Demo][demo] 

**Lua IDE for Windows**
  
[Features](#features) |
[Installation](#installation) |
[Documentation](#documentation) |
[Usage](#usage) |
[Author](#author) |
[License](#license) |
[Links](#links)


</div>

## Features

LuaRT Studio is a Windows IDE to develop Lua desktop or console applications, based on the LuaRT interpreter. LuaRT Studio can also be used to develop standard Lua applications based on latest Lua 5.4.4 VM seamlessly.

* Small and portable Lua 5.4.4 IDE for Windows
* Based on ZeroBrane Studio, from Paul Kulchenko 
* Bundled with a specific LuaRT interpreter, compatible with standard Lua
* Automatic switch between Lua console or desktop application based on file extension (.lua and .wlua respectively)
* Updated UI, using current Windows UI theme, icons for files, tabs, and panels.
* Rework of the "Outline" tab, now called "Symbols" (displays local and global variables, new icons, table expansion...)
* Icons for Watch panel, Stack panel and a new Symbol tab
* Support for using ttf font files
* LuaCheck updated to 0.26
* Updated mobdebug to support LuaRT objects.
* New project option to Show/Hide console window.
* Local Lua 5.4.4 console 

## Installation

The IDE can be **installed into and run from any directory**. There are two options to install it:

* Download [snapshot of the repository for each of the releases](https://github.com/samyeyo/LuaRT-Studio/).
* Clone the repository to access the current development version.

**No compilation is needed** for any of the installation options, although the script to compile "LuaRT Studio.exe" executable is available in the build\ directory.

## Documentation

* No specific documentation available for now, as most of the original ZeroBrane Studio documentation should apply for LuaRT Studio.

## Usage

The IDE can be launched by clicking `LuaRT Studio.exe` from the directory that the IDE is installed to. You can also create a shortcut to this executable.

The general command for launching is the following: `"LuaRT Studio.exe" [option] [<project directory>] [<filename>...]`.

* **Open files**: `"LuaRT Studio.exe" <filename> [<filename>...]`.
* **Set project directory** (and optionally open files): `"LuaRT Studio.exe" <project directory> [<filename>...]`.
* **Overwrite default configuration**: `"LuaRT Studio.exe" -cfg "string with configuration settings"`, for example: `zbstudio -cfg "editor.fontsize=12; editor.usetabs=true"`.
* **Load custom configuration file**: `"LuaRT Studio.exe" -cfg <filename>`, for example: `"LuaRT Studio.exe" -cfg cfg/xcode-keys.lua`.

All configuration changes applied from the command line are only effective for the current session.

If you are loading a file, you can also **set the cursor** on a specific line or at a specific position by using `filename:<line>` and `filename:p<pos>` syntax.

In all cases only one instance of the IDE will be allowed to launch by default:
if one instance is already running, the other one won't launch, but the directory and file parameters
passed to the second instance will trigger opening of that directory and file(s) in the already started instance.

## Author

### LuaRT studio

  **LuaRT:** Samir Tine (samir.tine@luart.org)

### ZeroBrane Studio and MobDebug

  **ZeroBrane LLC:** Paul Kulchenko (paul@zerobrane.com)
 
## License

See [LICENSE](LICENSE).

## Links
  
- [LuaRT Homepage](http://www.luart.org/)
- [LuaRT Community](http://community.luart.org/)
- [LuaRT Documentation](http://www.luart.org/doc)

[title]: studio/res/studio.png
[demo]: studio.luart.org/img/ide.png