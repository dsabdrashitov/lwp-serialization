local Deserializer = {}
local module_path = (...):match("(.-)[^%.]+$")
local Constants = require(module_path .. "constants")

Deserializer.__index = Deserializer

function Deserializer:new(registry)
    local obj = setmetatable({}, self)
    obj.registry = registry
    obj.dispatch = obj:_create_dispatch_table()
    return obj
end

function Deserializer:_create_dispatch_table()
    local d = {}

    -- 0x00: NIL / Terminator
    d[Constants.NIL] = function() return nil end

    -- Specials
    d[Constants.FALSE]   = function() return false end
    d[Constants.TRUE]    = function() return true end
    d[Constants.FLOAT64] = function(r) return string.unpack("<d", r:read(8)) end

    -- Fixed Integers
    d[Constants.I8]  = function(r) return string.unpack("<i1", r:read(1)) end
    d[Constants.I16] = function(r) return string.unpack("<i2", r:read(2)) end
    d[Constants.I32] = function(r) return string.unpack("<i4", r:read(4)) end
    d[Constants.I64] = function(r) return string.unpack("<i8", r:read(8)) end

    -- Fixed Strings: Read length, then read raw bytes.
    d[Constants.STR_I1] = function(r) return r:read(string.unpack("<I1", r:read(1))) end
    d[Constants.STR_I2] = function(r) return r:read(string.unpack("<I2", r:read(2))) end
    d[Constants.STR_I4] = function(r) return r:read(string.unpack("<I4", r:read(4))) end
    d[Constants.STR_I8] = function(r) return r:read(string.unpack("<I8", r:read(8))) end

    -- Links (Registry >= 0, Seen < 0)
    d[Constants.LNK_I1] = function(r, ctx) return self:_resolve_link(string.unpack("<i1", r:read(1)), ctx) end
    d[Constants.LNK_I2] = function(r, ctx) return self:_resolve_link(string.unpack("<i2", r:read(2)), ctx) end
    d[Constants.LNK_I4] = function(r, ctx) return self:_resolve_link(string.unpack("<i4", r:read(4)), ctx) end
    d[Constants.LNK_I8] = function(r, ctx) return self:_resolve_link(string.unpack("<i8", r:read(8)), ctx) end

    -- Small Strings (0x10 - 0x4F)
    for i = 0, Constants.MAX_SMALL_STR do
        d[Constants.SMALL_STR_START + i] = function(r) return r:read(i) end
    end

    -- Small Links (Registry 0..63)
    for i = 0, Constants.MAX_SMALL_LNK do
        d[Constants.SMALL_LNK_START + i] = function(_, ctx)
            return self:_resolve_link(i, ctx)
        end
    end

    -- Small Integers (0..110)
    for i = 0, Constants.MAX_SMALL_INT do
        d[Constants.SMALL_INT_START + i] = function() return i end
    end

    -- 0xFF: Table Start
    d[Constants.TABLE_START] = function(r, ctx) return self:_read_table(r, ctx) end

    return d
end

--- Public API: entry point that ensures a clean context.
function Deserializer:read(reader)
    local ctx = { seen = {} }
    return self:_deserialize(reader, ctx)
end

--- Internal recursive engine.
function Deserializer:_deserialize(reader, ctx)
    local header = string.unpack("<B", reader:read(1))
    local func = self.dispatch[header]
    if not func then 
        error(string.format("Invalid header: 0x%02X at pos %d", header, reader.pos - 1))
    end
    return func(reader, ctx)
end

function Deserializer:_resolve_link(id, ctx)
    if id >= 0 then
        local obj = self.registry:get_obj(id)
        if obj == nil then error("Broken link: Registry ID " .. id) end
        return obj
    else
        local obj = ctx.seen[-id]
        if obj == nil then error("Broken link: Session ID " .. id) end
        return obj
    end
end

function Deserializer:_read_table(reader, ctx)
    local result = {}
    ctx.seen[#ctx.seen + 1] = result

    while true do
        local key = self:_deserialize(reader, ctx)
        if key == nil then
            break
        end
        local value = self:_deserialize(reader, ctx)
        result[key] = value
    end
    return result
end

return Deserializer
