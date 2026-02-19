local lwps = require("build.lib.lwp_serialization_v_2_3")

-- 1. Create a registry and register a predefined table
local reg = lwps.Registry:new()
local config = { version = "1.0", api = "stable" }
reg:register(config)

-- 2. Initialize the codec with the shared registry
local codec = lwps.Codec:new(reg)

-- 3. Create a complex data structure with a cyclic reference 
-- and an object already present in the registry
local data = {
    title = "Main",
    ref_to_config = config,
    sub = {}
}
data.sub.parent = data -- Cyclic reference

-- 4. Serialization (Encoding)
local bytes = codec:encode(data)
print("Encoded size: " .. #bytes .. " bytes")

-- 5. Deserialization (Decoding)
local decoded = codec:decode(bytes)

-- 6. Verification
-- Ensure the registry link is preserved and points to the same object
assert(decoded.ref_to_config == config, "Registry reference mismatch")

-- Ensure the cyclic reference is correctly restored
assert(decoded.sub.parent == decoded, "Cyclic reference mismatch")

-- Check standard data integrity
assert(decoded.title == "Main", "String data mismatch")

print("Test passed successfully!")
