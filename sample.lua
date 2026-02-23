local lwps = require("build.lib.lwp_serialization_v_2_4")

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
-- Returns: string or nil, error_object
local bytes, err = codec:encode(data)
if not bytes then
    print("Serialization failed: " .. tostring(err))
    return
end
print("Encoded size: " .. #bytes .. " bytes")

-- 5. Deserialization (Decoding)
-- Returns: object or nil, error_object
local decoded, derr = codec:decode(bytes)
if not decoded then
    print("Deserialization failed: " .. tostring(derr))
    return
end

-- 6. Verification
-- Ensure the registry link is preserved and points to the same object
assert(decoded.ref_to_config == config, "Registry reference mismatch")

-- Ensure the cyclic reference is correctly restored
assert(decoded.sub.parent == decoded, "Cyclic reference mismatch")

-- Check standard data integrity
assert(decoded.title == "Main", "String data mismatch")

print("Test passed successfully!")

-- 7. Error Handling Example
print("\nError handling example:")
local corrupted_bytes = bytes:sub(1, #bytes - 10) -- Simulate truncated data
local result, decode_err = codec:decode(corrupted_bytes)

if decode_err then
    -- We can check the error type using the SerializationError class
    if lwps.SerializationError:defines(decode_err) then
        print("Expected Protocol/Transport error caught:")
        print("-> Message: " .. decode_err.message)
        print("-> Type: " .. decode_err.type)
    else
        print("Unknown error: " .. tostring(decode_err))
    end
end
