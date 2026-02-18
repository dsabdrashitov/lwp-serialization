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
-- If nil, a new Registry is created and shared between Serializer and Deserializer.
function Codec:new(registry)
    registry = registry or Registry:new()
    
    local obj = setmetatable({}, self)
    obj.serializer = Serializer:new(registry)
    obj.deserializer = Deserializer:new(registry)
    return obj
end

-- --- Stream API ---

function Codec:write(data, writer)
    return self.serializer:write(data, writer)
end

function Codec:read(reader)
    return self.deserializer:read(reader)
end

-- --- High-level String API ---

function Codec:encode(object)
    local writer = StringWriter:new()
    local ok, err = self.serializer:write(object, writer)
    if ok then
        return writer:to_string()
    else
        return nil, err
    end
end

function Codec:decode(byte_array)
    local reader = StringReader:new(byte_array)
    return self.deserializer:read(reader)
end

return Codec