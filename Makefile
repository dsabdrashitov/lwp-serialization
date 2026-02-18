OUTPUT_NAME := lwp-serialization

BUILD_DIR := ./build
SRC_LUA_PREFIX := ./src-lua

OUTPUT_DIR := $(BUILD_DIR)/$(OUTPUT_NAME)

SRC_LUA_DIRS := $(SRC_LUA_PREFIX)
LUAS := $(foreach dir,$(SRC_LUA_DIRS),$(wildcard $(dir)/*.lua))
LUAB := $(patsubst $(SRC_LUA_PREFIX)/%.lua,$(OUTPUT_DIR)/%.lua,$(LUAS))

all: $(LUAB)

$(OUTPUT_DIR)/%.lua: $(SRC_LUA_PREFIX)/%.lua
	-mkdir -p $(dir $@)
	cp $< $@

tree:
	-mkdir -p build
	git ls-files --others --cached --exclude-standard > ./build/project_structure.txt

clean:
	-if [ -d "$(BUILD_DIR)" ]; then rm -r $(BUILD_DIR); fi
