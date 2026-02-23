# lwp-serialization (v.2.4)

A lightweight, high-performance binary serialization library for **Lua 5.4**. Designed for efficient data transmission with native support for cyclic references (graphs), predefined object registries, and robust error handling.

## Key Features

- **Pure Lua 5.4**: Uses native bitwise operators and `string.pack/unpack`. No C-extensions or FFI required.
- **Graph Support**: Naturally handles cyclic references and multiple pointers to the same table.
- **Predefined Registry**: Map complex objects (functions, userdata, or common tables) to short, efficient IDs.
- **Advanced Error Handling**: Distinguishes between `PROTOCOL` (format) and `TRANSPORT` (I/O) errors with full stack traces.
- **Compact Format**:
  - **Small Integers** (0-110) in 1 byte.
  - **Small Strings** (up to 63 bytes) in 1 byte + body.
  - **Small Links** (Registry IDs 0-63) in 1 byte.
- **Streaming-Friendly**: Uses an "Anchor" (sentinel byte `0x00`) for tables, allowing single-pass encoding without pre-calculating sizes.

## Installation

1. Download the library (e.g., [`lib.zip`][binary] from releases).
2. Extract into your project. The structure should be:
   - `lwp_serialization_v_2_4.lua` (Proxy loader)
   - `lwp_serialization_v_2_4/` (Module directory)
3. Use `require` to load the library:
```lua
local lwps = require("lwp_serialization_v_2_4")
```

## Quick Start
```lua
local lwps = require("lwp_serialization_v_2_4")

-- 1. Setup Registry for shared objects or non-serializable types
local reg = lwps.Registry:new()
local shared_api = { version = "2.4", status = "stable" }
reg:register(shared_api)

-- 2. Initialize Codec
local codec = lwps.Codec:new(reg)

-- 3. Prepare complex data (with cycles)
local data = {
    api = shared_api,
    tags = {"lua", "binary", "fast"},
    node = {}
}
data.node.parent = data -- Cyclic reference

-- 4. Encode to string
local bytes, err = codec:encode(data)
if not bytes then 
    print("Error:", err)
    return 
end

-- 5. Decode with error checking
local decoded, derr = codec:decode(bytes)
if derr then
    if lwps.SerializationError:defines(derr) then
        print(string.format("Caught %s error: %s", derr.type, derr.message))
    end
    return
end

assert(decoded.api == shared_api)
assert(decoded.node.parent == decoded)
```

## Binary Protocol Overview (v.2.4)

The protocol uses a single-byte header to determine the data type and value for optimized "small" types.

| Header Range | Type | Description |
| :--- | :--- | :--- |
| `0x00` | **NIL** | Also acts as Table Terminator (Anchor) |
| `0x01 - 0x02` | **BOOL** | False (`0x01`), True (`0x02`) |
| `0x03` | **FLOAT** | IEEE 754 Double (8 bytes) |
| `0x04 - 0x07` | **INT** | Signed Integers: i8, i16, i32, i64 |
| `0x08 - 0x0B` | **STR** | Length-prefixed strings: uint8, 16, 32, 64 |
| `0x0C - 0x0F` | **LNK** | Signed ID Links: Positive (Registry), Negative (Session) |
| `0x10 - 0x4F` | **S-STR** | Small String: Length 0–63 (Header - 0x10) |
| `0x50 - 0x8F` | **S-LNK** | Small Link: Registry ID 0–63 (Header - 0x50) |
| `0x90 - 0xFE` | **S-INT** | Small Integer: Value 0–110 (Header - 0x90) |
| `0xFF` | **TABLE** | Table Start Marker |

## Component API

### `Codec`
High-level interface for most tasks.
- `encode(object)`: Returns binary string or `nil, error`.
- `decode(string)`: Returns Lua object or `nil, error`.

### `Registry`
Manages objects that should be referenced rather than serialized.
- `register(obj)`: Assigns a persistent ID to an object.
- Supports `function`, `userdata`, and `thread` types (must be registered on both sides).

### `SerializationError`
Rich error objects with:
- `.type`: `PROTOCOL` (format violation) or `TRANSPORT` (buffer/stream issue).
- `.message`: Description.
- `.cause`: Original error (if any).
- `.traceback`: Lua stack trace.

## Development Note

This project is **AI-assisted**. The architecture and implementation were developed through a collaborative process between a human engineer and Artificial Intelligence to ensure high code quality, efficiency, and adherence to Lua 5.4 standards.

[binary]:https://github.com/dsabdrashitov/lwp-serialization/releases/download/v.2.4/lib.zip
