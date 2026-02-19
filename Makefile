# Library settings
LIB_NAME := lwp_serialization_v_2_3

# Paths
BUILD_DIR := ./build
LIB_DEST_DIR := $(BUILD_DIR)/lib
# Folder: build/lib/lwp_serialization_v_2_3/
MODULE_DIR := $(LIB_DEST_DIR)/$(LIB_NAME)
# Proxy: build/lib/lwp_serialization_v_2_3.lua
PROXY_FILE := $(LIB_DEST_DIR)/$(LIB_NAME).lua

# Archive settings
ZIP_NAME := lib.zip
OUTPUT_ZIP := $(BUILD_DIR)/$(ZIP_NAME)

SRC_LUA_PREFIX := ./src-lua

# Source files logic
LUAS := $(wildcard $(SRC_LUA_PREFIX)/*.lua)
LUAB := $(patsubst $(SRC_LUA_PREFIX)/%.lua,$(MODULE_DIR)/%.lua,$(LUAS))

# Targets that are not files
.PHONY: all clean tree zip

# "all" now includes the zip archive creation
all: $(PROXY_FILE) $(LUAB) zip

# Rule to create the dynamic proxy loader
$(PROXY_FILE):
	@mkdir -p $(LIB_DEST_DIR)
	@echo "local path = ..." > $@
	@echo "return require(path .. '.init')" >> $@
	@echo "Generated proxy: $@"

# Rule to copy source files
$(MODULE_DIR)/%.lua: $(SRC_LUA_PREFIX)/%.lua
	@mkdir -p $(dir $@)
	@cp $< $@
	@echo "Copied: $< -> $@"

# Rule to create the ZIP archive
zip: $(PROXY_FILE) $(LUAB)
	@echo "Creating ZIP archive using tar: $(ZIP_NAME)..."
	@cd $(LIB_DEST_DIR) && tar -a -c -f ../$(ZIP_NAME) *
	@echo "Archive created: $(OUTPUT_ZIP)"

tree:
	@mkdir -p $(BUILD_DIR)
	@git ls-files --others --cached --exclude-standard > $(BUILD_DIR)/project_structure.txt

clean:
	@if [ -d "$(BUILD_DIR)" ]; then rm -r $(BUILD_DIR); fi
	@echo "Cleaned $(BUILD_DIR)"
