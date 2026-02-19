# lwp-serialization (v.2.3)

A lightweight, high-performance binary serialization library for **Lua 5.4**. Designed for efficient data transmission with native support for cyclic references (graphs) and predefined object registries.

## Key Features

- **Pure Lua 5.4**: Uses native bitwise operators and `string.pack/unpack`. Zero dependencies.
- **Graph Support**: Handles cyclic references and multiple references to the same table.
- **Predefined Registry**: Allows mapping complex objects (functions, userdata, or common tables) to short IDs.
- **Compact Format**:
  - Small Integers (0-110) in 1 byte.
  - Small Strings (up to 63 bytes) in 1 byte + body.
  - Small Links (Registry 0-63) in 1 byte.
- **Streaming-Friendly**: Table serialization uses a sentinel byte (`0x00`) instead of length-prefixing, allowing single-pass encoding.

## Installation

You can download the pre-built library package from the latest release:

**[Download lib.zip](https://github.com/dsabdrashitov/lwp-serialization/releases/download/v.2.3/lib.zip)**

1. Extract the contents into your project's directory.
2. The package includes:
   - `lwp_serialization_v_2_3.lua` (The proxy loader)
   - `lwp_serialization_v_2_3/` (The module folder)
3. Ensure the location is in your `LUA_PATH`.

## Quick Start

```lua
local lwps = require("lwp_serialization_v_2_3")

-- 1. Setup Registry (Optional)
local reg = lwps.Registry:new()
local shared_config = { version = "2.3", mode = "production" }
reg:register(shared_config)

-- 2. Initialize Codec
local codec = lwps.Codec:new(reg)

-- 3. Prepare data with cyclic references
local data = {
    meta = shared_config,
    content = "Hello LWP",
    self_ref = {}
}
data.self_ref.root = data -- Cycle

-- 4. Encode to binary string
local bytes = codec:encode(data)
print(string.format("Encoded size: %d bytes", #bytes))

-- 5. Decode back to Lua object
local decoded = codec:decode(bytes)
assert(decoded.meta == shared_config)
assert(decoded.self_ref.root == decoded)

## Binary Protocol Overview

The protocol uses a single-byte header to determine type and value for small data:

| Header Range | Category | Description |
| :--- | :--- | :--- |
| `0x00` | NIL / Sentinel | Marks end of tables or nil values |
| `0x01 - 0x02` | Boolean | False / True |
| `0x03` | Float | IEEE 754 Double |
| `0x04 - 0x07` | Fixed Int | Signed integers (i8, i16, i32, i64) |
| `0x08 - 0x0B` | Fixed Str | String with length prefix (I1, I2, I4, I8) |
| `0x0C - 0x0F` | Fixed Link | Signed ID (Positive: Registry, Negative: Session) |
| `0x10 - 0x4F` | Small Str | Length = Header - 0x10 (0 to 63 bytes) |
| `0x50 - 0x8F` | Small Link | Registry ID = Header - 0x50 (0 to 63) |
| `0x90 - 0xFE` | Small Int | Value = Header - 0x90 (0 to 110) |
| `0xFF` | Table Start | Marks the beginning of a table stream |

## Development Note

This project is **AI-assisted**. The architecture and implementation were developed through a collaborative process between a human engineer and Artificial Intelligence to ensure high code quality, efficiency, and adherence to Lua 5.4 standards.
