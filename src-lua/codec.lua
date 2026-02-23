local Codec = {}
local module_path = (...):match("(.-)[^%.]+$")

local Serializer = require(module_path .. "serializer")
local Deserializer = require(module_path .. "deserializer")
local Registry = require(module_path .. "registry")
local StringWriter = require(module_path .. "string_writer")
local StringReader = require(module_path .. "string_reader")

Codec.__index = Codec

--- Creates a new Codec instance.
-- @param registry (optional) A shared Registry object.
function Codec:new(registry)
    registry = registry or Registry:new()
    
    local obj = setmetatable({}, self)
    obj.serializer = Serializer:new(registry)
    obj.deserializer = Deserializer:new(registry)
    return obj
end

-- --- Stream API ---

--- Serializes data into a provided writer.
-- @return true or nil, error_object
function Codec:write(data, writer)
    return self.serializer:write(data, writer)
end

--- Deserializes data from a provided reader.
-- @return data or nil, error_object
function Codec:read(reader)
    return self.deserializer:read(reader)
end

-- --- High-level String API ---

--- Encodes an object into a binary string.
-- @return string or nil, error_object
function Codec:encode(object)
    local writer = StringWriter:new()
    local ok, err = self.serializer:write(object, writer)
    if ok then
        return writer:to_string()
    else
        return nil, err
    end
end

--- Decodes an object from a binary string.
-- @return data or nil, error_object
function Codec:decode(byte_array)
    if type(byte_array) ~= "string" then
        return nil, "Codec:decode expects a string"
    end

    local reader = StringReader:new(byte_array)
    return self.deserializer:read(reader)
end

return Codec
