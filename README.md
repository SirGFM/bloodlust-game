# Bloodlust

An action game highly inspired by [255 (by ZahranW)](https://zahranworrell.itch.io/255).

Well...

And also quite based on [Lawn Mower (by Shiru)](https://shiru.untergrund.net/software.shtml) for the NES.

## Lore

After years of searching, you finally found the **legendary mower.**

However, no legend mention the curse that comes alongside it...

Any lawn that is to be mowed by it start growing weird monstruous creatures.

Also, although the mower doesn't use fuel... It yearns for **souls**!

And if it can get souls from the creatures in the lawn, it shal get its fix...

from...

**YOU**!

## Cross compiling on Linux

This section describes my thought process for cross compiling this targeting Windows.

This method should be robust enough to automatically handle changes in the source code.
However, it has a lot of manual things related to the standard library files.

Hopefully, if the game start requiring any other source file from the standard library,
this may describe how to figure out which new files are required
and how to add them to the build system.

### First, some backstory...

I've been chilling Haxe/HaxeFlixel for a long time now,
but I had yet to actually dip my toes into it and try it out...
What a journey... and I haven't even started the game...

My interest in HaxeFlixel came mostly from two facts:

1. Flixel was the first game library I ever used
2. The promise of a cross-platform tool similar to Flixel was really enticing

To be fair, nowhere in either Haxe's nor HaxeFlixel's site there's promise of cross-compilation.
However, if it gets compiled into C++ and if it natively supports the target system,
then obviously cross-compiling is doable.

The catch wasn't whether it was doable, but how hard it was going to be...
I'm not sure whether I configured something incorrectly in my system,
but `lime` wouldn't build a Windows binary on Linux no matter what.

### Cross compiling for Windows

Since HaxeFlixel supports Windows natively,
cross-compiling it should be "as simple" as:

1. Figure out every source used to build the game
2. Figure out the specific compilation flags
3. Use MinGW and swap Linux-specific flags by their Windows-specific counterparts
4. Figure out which libraries the game must be linked with

#### Listing source files and flags

Many of the C++ files required by the game are actually copied to `export/linux/obj`.
Those are the source code for the libraries (e.g., OpenFL and HaxeFlixel),
and the game's source code.
However, the source code for the standard library isn't copied anywhere,
so it must be accessed directly where Haxe was installed.

There may be a smarter and better way to list those files...
but the easy way to do that is by simply overriding `g++` in your system.
(you should obviously do this inside a container, though... just saying...)

Replace `g++` with the following script:

```sh
#!/bin/bash

echo g++ $*
```

Then compile the game with `lime` as usual:

```sh
lime build linux -cpp
```

This will print everything that would be compiled to `stdout`:

```
Compiling group: haxe
g++ -Iinclude -c -fvisibility=hidden -O2 -fpic -fPIC -Wno-overflow -DHX_LINUX -DHXCPP_M64 -DHXCPP_VISIT_ALLOCS(haxe) -DHX_SMART_STRINGS(haxe) -DHXCPP_API_LEVEL=400(haxe) -m64 -DHXCPP_M64 -I/home/builder/haxelib/hxcpp/4,2,1/include ... tags=[haxe,static]
 - src/flixel/system/debug/interaction/tools/Pointer.cpp
 - src/lime/media/openal/ALC.cpp  [haxe,release]
 - src/openfl/display/_internal/Context3DElementType.cpp
 - src/flixel/util/FlxPool_flixel_effects_FlxFlicker.cpp
 - src/lime/_internal/backend/native/TextEventInfo.cpp
 - src/sys/io/_Process/Stdout.cpp
 - src/flixel/tweens/motion/LinearPath.cpp
 - src/openfl/system/SecurityDomain.cpp  [haxe,release]
g++ -I/game/export/linux/obj/obj/linux64/__pch/haxe -Iinclude -c -fvisibility=hidden -O2 -fpic -fPIC -Wno-overflow -DHX_LINUX -DHXCPP_M64 -DHXCPP_VISIT_ALLOCS -DHX_SMART_STRINGS -DHXCPP_API_LEVEL=400 -m64 -DHXCPP_M64 -I/home/builder/haxelib/hxcpp/4,2,1/include -x c++ -frtti -std=c++11 -Wno-invalid-offsetof ./src/flixel/system/debug/interaction/tools/Pointer.cpp -o/game/export/linux/obj/obj/linux64/bae87773_Pointer.o
g++ -I/game/export/linux/obj/obj/linux64/__pch/haxe -Iinclude -c -fvisibility=hidden -O2 -fpic -fPIC -Wno-overflow -DHX_LINUX -DHXCPP_M64 -DHXCPP_VISIT_ALLOCS -DHX_SMART_STRINGS -DHXCPP_API_LEVEL=400 -m64 -DHXCPP_M64 -I/home/builder/haxelib/hxcpp/4,2,1/include -x c++ -frtti -std=c++11 -Wno-invalid-offsetof ./src/flixel/util/FlxPool_flixel_effects_FlxFlicker.cpp -o/game/export/linux/obj/obj/linux64/6736b1e0_FlxPool_flixel_effects_FlxFlicker.o
...
```

Doing so, you may notice a few different groups,
each preceded by `Compiling group: <group>`,
and each with its own set of compilation flags.

Every group has a common set of compilation flags,
but each group also has a few unique ones.

One option to proceed from here would be
to write a simple script that manually compiles each file
and then link everything together.
Although that would work,
it's also possible to use Makefile to find the required files.

#### Compiling from Linux with a Makefile

After listing every source file,
I was able to separate them into three sources:

1. Regex library;
2. Hxcpp's standard library;
3. Application source.

The regex library is inside the hxcpp's source.
Automatically listing the required files may be done by using
a function to [recursively list files](https://stackoverflow.com/a/18258352),
and the built-in `filter` and `filter-out` functions:

```make
HXCPP_PATH := /home/builder/haxelib/hxcpp/4,2,1
PCRE_PATH := $(HXCPP_PATH)/project/thirdparty/pcre-8.42

PCRE16_SOURCE := $(call rwildcard, $(PCRE_PATH), *.c)
PCRE16_SOURCE := $(filter $(PCRE_PATH)/pcre16_%.c,$(PCRE16_SOURCE))
PCRE16_SOURCE := $(filter-out %_printint.c %_utf16_utils.c ,$(PCRE16_SOURCE))
```

This will list every C file within `$(PCRE_PATH)` that starts with `pcre16_`,
except by the files that ends with `_printint.c` or `%_utf16_utils.c`.

I couldn't figure out any way to automatically determine
which files from the standard library are required by the game.
So, instead I simply got the list of files (from tampering with `g++`),
and then got their full path automatically.

The remaining source files are all from the application,
and they can be further divided into:

1. Entry point;
2. Resource files;
3. Unused files;
4. Everything else.

An interesting mild challenge here is that there's no built-in way
to filter files based on part of their path.
However, it's possible to define a function to do that!

After separating each group
and renaming the output object file with a custom extension,
it's possible to use those custom extensions to add custom flags.

Doing all that,
defining the common compilation flags,
and defining the required libraries,
it was possible to manually compile for Linux with:

```sh
make linux
```

I highly recommend testing if this works before compiling for Windows,
because the Windows build won't work unless at least this works.

#### Actually cross compiling

Define MinGW as the compiler and list the required libraries,
then simply run:

```sh
make win
```
