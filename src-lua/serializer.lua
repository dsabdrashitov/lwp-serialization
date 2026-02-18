local Serializer = {}
local module_path = (...):match("(.-)[^%.]+$")
local Constants = require(module_path .. "constants")

Serializer.__index = Serializer

function Serializer:new(registry)
    local obj = setmetatable({}, self)
    obj.registry = registry

    -- Routing table for types
    obj.dispatch = {
        ["nil"]      = obj._write_nil,
        ["boolean"]  = obj._write_boolean,
        ["number"]   = obj._write_number,
        ["string"]   = obj._write_string,
        ["table"]    = obj._write_table,
        ["function"] = obj._write_registry_only,
        ["userdata"] = obj._write_registry_only,
        ["thread"]   = obj._write_registry_only,
    }

    return obj
end

--- Public API: Writes data into the writer
-- @return true on success, or nil, error_string on failure
function Serializer:write(data, writer)
    local ctx = {
        seen = {},
        ref_counter = 1,
        writer = writer
    }

    local ok, result = pcall(self._serialize, self, data, ctx)
    if ok then
        return true
    else
        return nil, result
    end
end

function Serializer:_serialize(val, ctx)
    local reg_id = self.registry:get_id(val)
    if reg_id then
        self:_write_link_id(reg_id, ctx)
        return
    end
    
    local t = type(val)
    local func = self.dispatch[t]
    if not func then error("Unsupported type: " .. t) end
    func(self, val, ctx)
end

-- --- Type Handlers ---

function Serializer:_write_nil(_, ctx)
    ctx.writer:write(string.pack("<B", Constants.NIL))
end

function Serializer:_write_boolean(val, ctx)
    if val then
        ctx.writer:write(string.pack("<B", Constants.TRUE))
    else
        ctx.writer:write(string.pack("<B", Constants.FALSE))
    end
    
end

function Serializer:_write_number(val, ctx)
    if math.type(val) == "integer" then
        -- Small Int: 0..110 mapped to 0x90..0xFE
        if val >= 0 and val <= Constants.MAX_SMALL_INT then
            ctx.writer:write(string.pack("<B", Constants.SMALL_INT_START + val))
            return
        end

        -- Fixed Integers
        if val >= -0x80 and val <= 0x7F then
            ctx.writer:write(string.pack("<Bi1", Constants.I8, val))
        elseif val >= -0x8000 and val <= 0x7FFF then
            ctx.writer:write(string.pack("<Bi2", Constants.I16, val))
        elseif val >= -0x80000000 and val <= 0x7FFFFFFF then
            ctx.writer:write(string.pack("<Bi4", Constants.I32, val))
        else
            ctx.writer:write(string.pack("<Bi8", Constants.I64, val))
        end
    else
        -- Float64
        ctx.writer:write(string.pack("<Bd", Constants.FLOAT64, val))
    end
end

function Serializer:_write_string(val, ctx)
    local len = #val
    if len <= Constants.MAX_SMALL_STR then
        ctx.writer:write(string.pack("<B", Constants.SMALL_STR_START + len))
    elseif len <= 0xFF then
        ctx.writer:write(string.pack("<BI1", Constants.STR_I1, len))
    elseif len <= 0xFFFF then
        ctx.writer:write(string.pack("<BI2", Constants.STR_I2, len))
    elseif len <= 0xFFFFFFFF then
        ctx.writer:write(string.pack("<BI4", Constants.STR_I4, len))
    else
        ctx.writer:write(string.pack("<BI8", Constants.STR_I8, len))
    end
    ctx.writer:write(val)
end

function Serializer:_write_registry_only(val, _)
    error("Object of this type can only be predefined in registry: " .. tostring(val))
end

function Serializer:_write_link_id(id, ctx)
    if id >= 0 and id <= Constants.MAX_SMALL_LNK then
        ctx.writer:write(string.pack("<B", Constants.SMALL_LNK_START + id))
    elseif id >= -0x80 and id <= 0x7F then
        ctx.writer:write(string.pack("<Bi1", Constants.LNK_I1, id))
    elseif id >= -0x8000 and id <= 0x7FFF then
        ctx.writer:write(string.pack("<Bi2", Constants.LNK_I2, id))
    elseif id >= -0x80000000 and id <= 0x7FFFFFFF then
        ctx.writer:write(string.pack("<Bi4", Constants.LNK_I4, id))
    else
        ctx.writer:write(string.pack("<Bi8", Constants.LNK_I8, id))
    end
end

function Serializer:_write_table(val, ctx)
    -- 1. Check seen (Link to already serialized table)
    if ctx.seen[val] then
        self:_write_link_id(-ctx.seen[val], ctx)
        return
    end

    -- 2. Register table to handle self-references
    local ref_id = ctx.ref_counter
    ctx.ref_counter = ctx.ref_counter + 1
    ctx.seen[val] = ref_id
    

    -- 3. Write Anchor Byte (0xFF)
    ctx.writer:write(string.pack("<B", Constants.TABLE_START))

    -- 4. Streaming
    for k, v in pairs(val) do
        self:_serialize(k, ctx)
        self:_serialize(v, ctx)
    end

    -- 5. Write key=nil to terminate
    self:_serialize(nil, ctx)
end

return Serializer
