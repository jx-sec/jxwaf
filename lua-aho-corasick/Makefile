OS := $(shell uname)

ifeq ($(OS), Darwin)
    SO_EXT := dylib
else
    SO_EXT := so
endif

#############################################################################
#
#           Binaries we are going to build
#
#############################################################################
#
C_SO_NAME = libac.$(SO_EXT)
LUA_SO_NAME = ahocorasick.$(SO_EXT)
AR_NAME = libac.a

#############################################################################
#
#           Compile and link flags
#
#############################################################################
LUA_VERSION := 5.1
PREFIX = /usr
LUA_INCLUDE_DIR := $(PREFIX)/include/lua$(LUA_VERSION)
SO_TARGET_DIR := $(PREFIX)/lib/lua/$(LUA_VERSION)
LUA_TARGET_DIR := $(PREFIX)/share/lua/$(LUA_VERSION)

# Available directives:
# -DDEBUG : Turn on debugging support
# -DVERIFY : To verify if the slow-version and fast-version implementations
#            get exactly the same result. Note -DVERIFY implies -DDEBUG.
#
CFLAGS = -msse2 -msse3 -msse4.1 -O3 #-g -DVERIFY
COMMON_FLAGS = -fvisibility=hidden -Wall $(CFLAGS) $(MY_CFLAGS) $(MY_CXXFLAGS)

SO_CXXFLAGS = $(COMMON_FLAGS) -fPIC
SO_LFLAGS = $(COMMON_FLAGS)
AR_CXXFLAGS = $(COMMON_FLAGS)

# -DVERIFY implies -DDEBUG
ifneq ($(findstring -DVERIFY, $(COMMON_FLAGS)), )
ifeq ($(findstring -DDEBUG, $(COMMON_FLAGS)), )
    COMMON_FLAGS += -DDEBUG
endif
endif

AR = ar
AR_FLAGS = cru

#############################################################################
#
#       Divide source codes and objects into several categories
#
#############################################################################
#
SRC_COMMON := ac_fast.cxx ac_slow.cxx
LIBAC_SO_SRC := $(SRC_COMMON) ac.cxx    # source for libac.so
LUA_SO_SRC := $(SRC_COMMON) ac_lua.cxx  # source for ahocorasick.so
LIBAC_A_SRC := $(LIBAC_SO_SRC)          # source for libac.a

#############################################################################
#
#                   Make rules
#
#############################################################################
#
.PHONY = all clean test benchmark prepare
all : $(C_SO_NAME) $(LUA_SO_NAME) $(AR_NAME)

-include c_so_dep.txt
-include lua_so_dep.txt
-include ar_dep.txt

BUILD_SO_DIR := build_so
BUILD_AR_DIR := build_ar

$(BUILD_SO_DIR) :; mkdir $@
$(BUILD_AR_DIR) :; mkdir $@

$(BUILD_SO_DIR)/%.o : %.cxx | $(BUILD_SO_DIR)
	$(CXX) $< -c $(SO_CXXFLAGS) -I$(LUA_INCLUDE_DIR) -MMD -o $@

$(BUILD_AR_DIR)/%.o : %.cxx | $(BUILD_AR_DIR)
	$(CXX) $< -c $(AR_CXXFLAGS) -I$(LUA_INCLUDE_DIR) -MMD -o $@

ifneq ($(OS), Darwin)
$(C_SO_NAME) : $(addprefix $(BUILD_SO_DIR)/, ${LIBAC_SO_SRC:.cxx=.o})
	$(CXX) $+ -shared -Wl,-soname=$(C_SO_NAME) $(SO_LFLAGS) -o $@
	cat $(addprefix $(BUILD_SO_DIR)/, ${LIBAC_SO_SRC:.cxx=.d}) > c_so_dep.txt

$(LUA_SO_NAME) : $(addprefix $(BUILD_SO_DIR)/, ${LUA_SO_SRC:.cxx=.o})
	$(CXX) $+ -shared -Wl,-soname=$(LUA_SO_NAME) $(SO_LFLAGS) -o $@
	cat $(addprefix $(BUILD_SO_DIR)/, ${LUA_SO_SRC:.cxx=.d}) > lua_so_dep.txt

else
$(C_SO_NAME) : $(addprefix $(BUILD_SO_DIR)/, ${LIBAC_SO_SRC:.cxx=.o})
	$(CXX) $+ -shared $(SO_LFLAGS) -o $@
	cat $(addprefix $(BUILD_SO_DIR)/, ${LIBAC_SO_SRC:.cxx=.d}) > c_so_dep.txt

$(LUA_SO_NAME) : $(addprefix $(BUILD_SO_DIR)/, ${LUA_SO_SRC:.cxx=.o})
	$(CXX) $+ -shared $(SO_LFLAGS) -o $@ -Wl,-undefined,dynamic_lookup
	cat $(addprefix $(BUILD_SO_DIR)/, ${LUA_SO_SRC:.cxx=.d}) > lua_so_dep.txt
endif

$(AR_NAME) : $(addprefix $(BUILD_AR_DIR)/, ${LIBAC_A_SRC:.cxx=.o})
	$(AR) $(AR_FLAGS) $@ $+
	cat $(addprefix $(BUILD_AR_DIR)/, ${LIBAC_A_SRC:.cxx=.d}) > lua_so_dep.txt

#############################################################################
#
#           Misc
#
#############################################################################
#
test : $(C_SO_NAME)
	$(MAKE) -C tests && \
	luajit tests/lua_test.lua && \
	luajit tests/load_ac_test.lua

benchmark: $(C_SO_NAME)
	$(MAKE) benchmark -C tests

clean :
	-rm -rf *.o *.d c_so_dep.txt lua_so_dep.txt ar_dep.txt $(TEST) \
        $(C_SO_NAME) $(LUA_SO_NAME) $(TEST) $(BUILD_SO_DIR) $(BUILD_AR_DIR) \
        $(AR_NAME)
	make clean -C tests

install:
	install -D -m 755 $(C_SO_NAME) $(DESTDIR)/$(SO_TARGET_DIR)/$(C_SO_NAME)
	install -D -m 755 $(LUA_SO_NAME) $(DESTDIR)/$(SO_TARGET_DIR)/$(LUA_SO_NAME)
	install -D -m 664 load_ac.lua $(DESTDIR)/$(LUA_TARGET_DIR)/load_ac.lua
