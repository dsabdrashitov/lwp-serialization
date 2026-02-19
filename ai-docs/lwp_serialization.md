Context for the library I'm using. Adhere to these specs.
AI Context: LWP-Serialization (v2.3)
Purpose
A pure Lua 5.4 binary serialization library. It supports cyclic references (graphs) and a predefined object registry. Optimized for size and speed using a single-byte header map.
Core Logic (The "Ground Truth")
Binary Format: Little-endian (<). Uses string.pack and string.unpack.
Number Handling:
Distinguishes between integer and float (native Lua 5.4).
Floats are always Float64 (d).
Integers use signed packing (i1, i2, i4, i8) or "Small Int" optimization.
Link Resolution (Crucial):
Positive IDs (>= 0): Objects from the Registry (predefined).
Negative IDs (< 0): Objects from the current session seen table (cycles).
Formula: seen_index = -id. (e.g., ID -1 refers to ctx.seen[1]).
Table Streaming:
Uses a "Sentinel" approach. Tables start with 0xFF and end with a nil key (0x00).
No length prefixing for tables.
Header Map Reference
Hex	Type	Payload / Logic
0x00	NIL / TERM	Terminator for tables or literal nil
0x01-0x02	Bool	False / True
0x03	Float64	8 bytes
0x04-0x07	Fixed Int	i1, i2, i4, i8
0x08-0x0B	Fixed Str	s1, s2, s4, s8
0x0C-0x0F	Fixed Link	i1, i2, i4, i8 (Signed ID)
0x10-0x4F	Small Str	Len: Header - 0x10 (0-63)
0x50-0x8F	Small Lnk	Registry ID: Header - 0x50 (0-63)
0x90-0xFE	Small Int	Value: Header - 0x90 (0-110)
0xFF	Table Start	Streaming starts
Architecture for Extension
Registry: Global object IDs. Use registry:register(obj).
Serializer/Deserializer: Stateless dispatch-based engines.
Codec: Use codec:encode(obj) and codec:decode(bytes).
Relocatable: All modules use (...):match("(.-)[^%.]+$") for path-independent imports.
Coding Rules
Use math.type(v) == "integer" for number branching.
Always use table.concat for buffer building in writers.
When adding new types, update both Serializer.dispatch and Deserializer.dispatch tables.
Do not use pairs for serialization if deterministic output (stable hash) is required (though default LWP v2.3 uses pairs for speed).
