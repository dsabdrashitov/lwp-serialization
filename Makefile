# Library settings (must match Lua module naming rules)
LIB_NAME := lwp_serialization_v_2_3

# Paths
BUILD_DIR := ./build
LIB_DEST_DIR := $(BUILD_DIR)/lib
# build/lib/lwp_serialization/
MODULE_DIR := $(LIB_DEST_DIR)/$(LIB_NAME)
# build/lib/lwp_serialization.lua
PROXY_FILE := $(LIB_DEST_DIR)/$(LIB_NAME).lua

SRC_LUA_PREFIX := ./src-lua

# Logic to find all sources and map them to build directory
LUAS := $(wildcard $(SRC_LUA_PREFIX)/*.lua)
LUAB := $(patsubst $(SRC_LUA_PREFIX)/%.lua,$(MODULE_DIR)/%.lua,$(LUAS))

# Targets that are not files
.PHONY: all clean tree

all: $(PROXY_FILE) $(LUAB)

# Creates a relocatable proxy loader
$(PROXY_FILE):
	@mkdir -p $(LIB_DEST_DIR)
	@echo "local path = ..." > $@
	@echo "return require(path .. '.init')" >> $@
	@echo "Generated proxy: $@"

# Rule to copy source files into the module directory
$(MODULE_DIR)/%.lua: $(SRC_LUA_PREFIX)/%.lua
	@mkdir -p $(dir $@)
	@cp $< $@
	@echo "Copied: $< -> $@"

tree:
	@mkdir -p $(BUILD_DIR)
	@git ls-files --others --cached --exclude-standard > $(BUILD_DIR)/project_structure.txt

clean:
	@if [ -d "$(BUILD_DIR)" ]; then rm -r $(BUILD_DIR); fi
	@echo "Cleaned $(BUILD_DIR)"
