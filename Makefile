# =========================================================================

LINUX_PATH := export/test
WIN_PATH := export/windows
BASE_BIN := bloodlust

.PHONY: linux win clean

linux: $(LINUX_PATH)/bin/$(BASE_BIN)
win: $(WIN_PATH)/bin/$(BASE_BIN).exe

# target-specific variables only work in rules,
# so they can't be used to determine which files will be compiled,
# nor on which path, for each target.
linux: CXX := g++
linux: LDLIBS := -lpthread -ldl

win: CXX := x86_64-w64-mingw32-g++
win: LDFLAGS := -mwindows -lmingw32
win: LDLIBS := -lpthread -lws2_32 -static

ifeq ($(filter linux win clean,$(MAKECMDGOALS)),)
    $(error The target must be one of: linux win clean)
endif
ifeq ($(MAKECMDGOALS), linux)
    OUTPUT_DIR := $(LINUX_PATH)
    HX_OSFLAG := -DHX_LINUX
endif
ifeq ($(MAKECMDGOALS), win)
    OUTPUT_DIR := $(WIN_PATH)
    HX_OSFLAG := -DHX_WINDOWS -I /usr/share/mingw-w64/include -I /game/.docker/fix-win-headers
endif

# =========================================================================

BASE_PATH := export/linux

LIME_PATH := /home/builder/haxelib/lime
HXCPP_PATH := /home/builder/haxelib/hxcpp/4,2,1
PCRE_PATH := $(HXCPP_PATH)/project/thirdparty/pcre-8.42
REGEX_PATH := $(HXCPP_PATH)/src/hx/libs/regexp
STD_PATH := $(HXCPP_PATH)/src/hx/libs/std

# =========================================================================

CFLAGS := \
	-fvisibility=hidden \
	-O2 \
	-fpic \
	-fPIC \
	-Wno-overflow \
	-m64 \
	-DHXCPP_M64 \
	-DHX_SMART_STRINGS \
	-DHXCPP_API_LEVEL=400 \
	-DHXCPP_VISIT_ALLOCS \
	$(HX_OSFLAG) \
	-I$(HXCPP_PATH)/include

CXXFLAGS := \
	$(CFLAGS) \
	-std=c++11 \
	-frtti \
	-Wno-invalid-offsetof

# =========================================================================

# Recursive wildcard from https://stackoverflow.com/a/18258352
#
# To find every .c file in src:
#   FILES := $(call rwildcard, , *.c)
# To find all the .c and .h files in src:
#   FILES := $(call rwildcard, src/, *.c *.h)
rwildcard=$(foreach d,$(wildcard $1*), \
	$(call rwildcard,$d/,$2) \
	$(filter $(subst *,%,$2),$d))

# $(call filter_pattern,pattern, list)
#
# Find every value that match pattern in list.
# Be careful with spaces in pattern,
# as Make assume that to be part of the pattern!
filter_pattern=$(foreach name, \
	$(2), \
	$(if \
		$(findstring $(1),$(name)), \
		$(name), \
	) \
)

# =========================================================================

BASE_SOURCE := $(call rwildcard, $(BASE_PATH)/obj/, *.cpp)
HXCPP_SOURCE := $(call rwildcard, $(HXCPP_PATH)/src/, *.cpp)

PCRE_SOURCE := $(call rwildcard, $(PCRE_PATH), *.c)
PCRE_SOURCE := $(filter $(PCRE_PATH)/pcre_%.c,$(PCRE_SOURCE))
PCRE_SOURCE := $(filter-out %_printint.c %_jit_test.c ,$(PCRE_SOURCE))
PCREXX_SOURCE := $(REGEX_PATH)/RegExp.cpp

PCRE16_SOURCE := $(call rwildcard, $(PCRE_PATH), *.c)
PCRE16_SOURCE := $(filter $(PCRE_PATH)/pcre16_%.c,$(PCRE16_SOURCE))
PCRE16_SOURCE := $(filter-out %_printint.c %_utf16_utils.c ,$(PCRE16_SOURCE))

RES_SOURCE := $(call filter_pattern,src/resources/, $(BASE_SOURCE))
BASE_SOURCE := $(filter-out $(RES_SOURCE), $(BASE_SOURCE))

RUNTIME_LIST := Array.cpp \
	hx/Anon.cpp \
	hx/Date.cpp \
	hx/Interface.cpp \
	hx/Boot.cpp \
	Enum.cpp \
	hx/CFFI.cpp \
	hx/Object.cpp \
	hx/Class.cpp \
	Dynamic.cpp \
	hx/gc/GcRegCapture.cpp \
	Math.cpp \
	hx/Hash.cpp \
	hx/Thread.cpp \
	hx/gc/Immix.cpp \
	hx/Lib.cpp \
	hx/StdLibs.cpp \
	hx/Debug.cpp \
	hx/gc/GcCommon.cpp \
	String.cpp

RUNTIME_LIST := $(foreach name,$(RUNTIME_LIST),%/$(name))
RUNTIME_SOURCE := $(filter $(RUNTIME_LIST),$(HXCPP_SOURCE))
HXCPP_SOURCE := $(filter-out $(RUNTIME_SOURCE), $(HXCPP_SOURCE))

MAIN_SOURCE := $(filter %__main__.cpp,$(BASE_SOURCE))
BASE_SOURCE := $(filter-out $(MAIN_SOURCE), $(BASE_SOURCE))

STD_SOURCE := $(call rwildcard, $(STD_PATH), *.cpp)
HXCPP_SOURCE := $(filter-out $(STD_SOURCE), $(HXCPP_SOURCE))

APP_SOURCE := $(filter-out %__files__.cpp %__lib__.cpp, $(BASE_SOURCE))
APP_SOURCE := $(APP_SOURCE) $(filter %NoFiles.cpp,$(HXCPP_SOURCE))

NDLL_FILES := $(call rwildcard,$(LIME_PATH),*.ndll)
LINUX_LIME := $(call filter_pattern,/Linux64/, $(NDLL_FILES))
WINDOWS_LIME := $(call filter_pattern,/Windows64/, $(NDLL_FILES))

# =========================================================================

OBJECTS := \
	$(PCRE_SOURCE:%.c=$(OUTPUT_DIR)/%.pcre.o) \
	$(PCREXX_SOURCE:%.cpp=$(OUTPUT_DIR)/%.pcre.o) \
	$(PCRE16_SOURCE:%.c=$(OUTPUT_DIR)/%.pcre16.o) \
	$(RES_SOURCE:%.cpp=$(OUTPUT_DIR)/%.res.o) \
	$(RUNTIME_SOURCE:%.cpp=$(OUTPUT_DIR)/%.runtime.o) \
	$(MAIN_SOURCE:%.cpp=$(OUTPUT_DIR)/%.main.o) \
	$(STD_SOURCE:%.cpp=$(OUTPUT_DIR)/%.std.o) \
	$(APP_SOURCE:%.cpp=$(OUTPUT_DIR)/%.app.o)

# =========================================================================

# Create directories as needed
%.mkdir:
	@ if [ ! -d $(@D) ]; then echo "Creating dir $(@D)..."; fi
	@ mkdir -p $(@D)
	@ touch $@

# Compiling group: haxe
$(OUTPUT_DIR)/%.app.o: %.cpp | $(OUTPUT_DIR)/%.mkdir
	$(CXX) -I $(BASE_PATH)/obj/include $(CXXFLAGS) -o $@ -c $<

# Compiling group: __main__
$(OUTPUT_DIR)/%.main.o: %.cpp | $(OUTPUT_DIR)/%.mkdir
	$(CXX) -DHX_DECLARE_MAIN -I $(BASE_PATH)/obj/include $(CXXFLAGS) -o $@ -c $<

# Compiling group: __resources__
$(OUTPUT_DIR)/%.res.o: %.cpp | $(OUTPUT_DIR)/%.mkdir
	$(CXX) -I $(BASE_PATH)/obj/include $(CXXFLAGS) -o $@ -c $<

# Compiling group: runtime
$(OUTPUT_DIR)/%.runtime.o: %.cpp | $(OUTPUT_DIR)/%.mkdir
	$(CXX) -D_CRT_SECURE_NO_DEPRECATE -DHX_UNDEFINE_H $(CXXFLAGS) -o $@ -c $<

# Compiling group: hxcpp_regexp
$(OUTPUT_DIR)/%.pcre.o: %.cpp | $(OUTPUT_DIR)/%.mkdir
	$(CXX) -I $(PCRE_PATH) -DHAVE_CONFIG_H -DPCRE_STATIC -DSUPPORT_UTF8 -DSUPPORT_UCP -DNO_RECURSE $(CXXFLAGS) -o $@ -c $<

$(OUTPUT_DIR)/%.pcre.o: %.c | $(OUTPUT_DIR)/%.mkdir
	$(CXX) -I $(PCRE_PATH) -DHAVE_CONFIG_H -DPCRE_STATIC -DSUPPORT_UTF8 -DSUPPORT_UCP -DNO_RECURSE $(CFLAGS) -o $@ -x c -c $<

# Compiling group: hxcpp_regexp16
$(OUTPUT_DIR)/%.pcre16.o: %.c | $(OUTPUT_DIR)/%.mkdir
	$(CXX) -I $(PCRE_PATH) -DHAVE_CONFIG_H -DPCRE_STATIC -DSUPPORT_UTF16 -DSUPPORT_UCP $(CFLAGS) -o $@ -x c -c $<

# Compiling group: hxcpp_std
$(OUTPUT_DIR)/%.std.o: %.cpp | $(OUTPUT_DIR)/%.mkdir
	$(CXX) $(CXXFLAGS) -o $@ -c $<

# =========================================================================

%/bin/$(BASE_BIN): $(OBJECTS) | %/bin/$(BASE_BIN).mkdir
	$(CXX) -m64 -o $@ $^ $(LDFLAGS) $(LDLIBS)
	cp $(LINUX_LIME) $(@D)/

# This target must have a rule,
# even though mingw's g++ automatically adds the .exe extension.
%/bin/$(BASE_BIN).exe: %/bin/$(BASE_BIN)
	cp $(WINDOWS_LIME) $(@D)/

clean:
	rm -rf $(LINUX_PATH) $(WIN_PATH)
