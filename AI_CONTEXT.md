# AI Context: lwp-serialization (v.2.4)

## Project Purpose
A pure Lua 5.4 library for binary serialization (LWP protocol v.2.4). 
Core features: support for cyclic references, object registries, and memory-efficient streaming.

## Core Interface: Reader & Writer
The library is transport-agnostic. Any object passed as a Reader or Writer must implement the following duck-typed interfaces:

### Writer Interface
- `write(data: string): boolean, string?`
  - Must append binary data to the output.
  - Returns `true` on success.
  - Returns `nil, error_message` on failure.

### Reader Interface
- `read(n: integer): string?, string?`
  - Must return exactly `n` bytes from the current position.
  - Returns the `chunk` (string) on success.
  - Returns `nil, error_message` if `n` bytes are not available (EOF or transport error).

## Component: Serializer
Low-level engine for encoding.
- **Constructor**: `Serializer:new(registry: Registry)`
- **Methods**:
  - `write(data: any, writer: Writer): true | nil, SerializationError`
    - Main entry point. Uses a `pcall` wrapper to catch internal exceptions and convert them to `SerializationError` objects.
    - Handles recursion via an internal `ctx` (context) containing a `seen` table for cycle detection.
    - Negative IDs are used for session-local (seen) references.

## Component: Deserializer
Low-level engine for decoding.
- **Constructor**: `Deserializer:new(registry: Registry)`
- **Methods**:
  - `read(reader: Reader): any | nil, SerializationError`
    - Main entry point. Decodes the next object from the stream.
    - Uses a high-performance `dispatch` table mapped to protocol headers (0x00 - 0xFF).
    - Reconstructs tables by streaming key-value pairs until a `NIL` (0x00) terminator is met.
## Error Handling Strategy
The library uses a custom `SerializationError` class to wrap all failures.

### Error Types:
1. `SerializationError.Type.PROTOCOL`: 
   - Logical errors: invalid headers, broken links, unsupported types, or registry mismatches.
   - Indicates data corruption or version incompatibility.
2. `SerializationError.Type.TRANSPORT`:
   - I/O errors: unexpected end of stream or failures returned by the `Reader`/`Writer`.

### Identification:
- Use `SerializationError:defines(err_obj)` to check if a returned error is an instance of the library's error class.
- The error object contains `.message`, `.type`, `.cause` (inner error), and `.traceback`.

## Binary Protocol (v.2.4)
- **Endianness**: Always Little-Endian (`<`).
- **Floats**: IEEE 754 Double Precision (8 bytes).
- **Integers**: Uses `math.type()` to distinguish. Small integers (0-110) are embedded in the header (`0x90 + val`).
- **Tables**:
  - Start with `0xFF`.
  - Followed by `key, value, key, value...`
  - Terminated by a `NIL` (0x00) key.
- **Links/References**:
  - **Registry Links (ID >= 0)**: Reference global objects (pre-shared).
  - **Session Links (ID < 0)**: Reference objects within the current message (cycles/multi-refs).
  - Encoded as `LNK_Ix` or `SMALL_LNK`.

## Integration Notes for AI
- When generating code, prioritize using the `Codec` class for simple `encode/decode` tasks.
- Use `Registry` for objects that cannot be serialized (functions, lightuserdata) or to save space on repetitive strings/tables.
- Ensure `math.tointeger()` is respected; the library distinguishes between `1` (integer) and `1.0` (float).
