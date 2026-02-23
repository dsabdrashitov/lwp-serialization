local Serializer = {}
local module_path = (...):match("(.-)[^%.]+$")
local Constants = require(module_path .. "constants")
local SerializationError = require(module_path .. "serialization_error")

Serializer.__index = Serializer

--- Bridges Nil+Err writer to Exception-based core.
local function safe_write(writer, data)
    local ok, err = writer:write(data)
    if not ok then
        error(SerializationError:new(
            "write error",
            SerializationError.Type.TRANSPORT,
            err
        ))
    end
end

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
-- @return true on success, or nil, error_object on failure
function Serializer:write(data, writer)
    local ctx = {
        seen = {},
        ref_counter = 1,
        writer = writer
    }

    local ok, res = pcall(self._serialize, self, data, ctx)
    
    if ok then
        return true
    elseif res and SerializationError:defines(res) then
        if res.type == SerializationError.Type.TRANSPORT then
            return nil, res.cause or res
        end
        return nil, res
    else
        error(res) -- Rethrow code bugs
    end
end

function Serializer:_serialize(val, ctx)
    -- 1. Check Registry (Functions, Userdata, or predefined objects)
    local reg_id = self.registry:get_id(val)
    if reg_id then
        self:_write_link_id(reg_id, ctx)
        return
    end
    
    -- 2. Dispatch by type
    local t = type(val)
    local func = self.dispatch[t]
    if not func then
        error(SerializationError:new(
            "Unsupported type: " .. t,
            SerializationError.Type.PROTOCOL
        ))
    end
    func(self, val, ctx)
end

-- --- Type Handlers ---

function Serializer:_write_nil(_, ctx)
    safe_write(ctx.writer, string.pack("<B", Constants.NIL))
end

function Serializer:_write_boolean(val, ctx)
    if val then
        safe_write(ctx.writer, string.pack("<B", Constants.TRUE))
    else
        safe_write(ctx.writer, string.pack("<B", Constants.FALSE))
    end
end

function Serializer:_write_number(val, ctx)
    if math.type(val) == "integer" then
        -- Small Int: 0..110 mapped to 0x90..0xFE
        if val >= 0 and val <= Constants.MAX_SMALL_INT then
            safe_write(ctx.writer, string.pack("<B", Constants.SMALL_INT_START + val))
            return
        end

        -- Fixed Integers
        if val >= -0x80 and val <= 0x7F then
            safe_write(ctx.writer, string.pack("<Bi1", Constants.I8, val))
        elseif val >= -0x8000 and val <= 0x7FFF then
            safe_write(ctx.writer, string.pack("<Bi2", Constants.I16, val))
        elseif val >= -0x80000000 and val <= 0x7FFFFFFF then
            safe_write(ctx.writer, string.pack("<Bi4", Constants.I32, val))
        else
            safe_write(ctx.writer, string.pack("<Bi8", Constants.I64, val))
        end
    else
        -- Float64
        safe_write(ctx.writer, string.pack("<Bd", Constants.FLOAT64, val))
    end
end

function Serializer:_write_string(val, ctx)
    local len = #val
    if len <= Constants.MAX_SMALL_STR then
        safe_write(ctx.writer, string.pack("<B", Constants.SMALL_STR_START + len))
    elseif len <= 0xFF then
        safe_write(ctx.writer, string.pack("<BI1", Constants.STR_I1, len))
    elseif len <= 0xFFFF then
        safe_write(ctx.writer, string.pack("<BI2", Constants.STR_I2, len))
    elseif len <= 0xFFFFFFFF then
        safe_write(ctx.writer, string.pack("<BI4", Constants.STR_I4, len))
    else
        safe_write(ctx.writer, string.pack("<BI8", Constants.STR_I8, len))
    end
    safe_write(ctx.writer, val)
end

function Serializer:_write_registry_only(val, _)
    error(SerializationError:new(
        "Object of type " .. type(val) .. " must be registered before serialization",
        SerializationError.Type.PROTOCOL
    ))
end

function Serializer:_write_link_id(id, ctx)
    if id >= 0 and id <= Constants.MAX_SMALL_LNK then
        safe_write(ctx.writer, string.pack("<B", Constants.SMALL_LNK_START + id))
    elseif id >= -0x80 and id <= 0x7F then
        safe_write(ctx.writer, string.pack("<Bi1", Constants.LNK_I1, id))
    elseif id >= -0x8000 and id <= 0x7FFF then
        safe_write(ctx.writer, string.pack("<Bi2", Constants.LNK_I2, id))
    elseif id >= -0x80000000 and id <= 0x7FFFFFFF then
        safe_write(ctx.writer, string.pack("<Bi4", Constants.LNK_I4, id))
    else
        safe_write(ctx.writer, string.pack("<Bi8", Constants.LNK_I8, id))
    end
end

function Serializer:_write_table(val, ctx)
    -- 1. Check seen (Circular reference)
    if ctx.seen[val] then
        self:_write_link_id(-ctx.seen[val], ctx)
        return
    end

    -- 2. Register table in session context
    local ref_id = ctx.ref_counter
    ctx.ref_counter = ctx.ref_counter + 1
    ctx.seen[val] = ref_id

    -- 3. Write Anchor Byte (0xFF)
    safe_write(ctx.writer, string.pack("<B", Constants.TABLE_START))

    -- 4. Streaming
    for k, v in pairs(val) do
        self:_serialize(k, ctx)
        self:_serialize(v, ctx)
    end

    -- 5. Write key=nil to terminate
    self:_serialize(nil, ctx)
end

return Serializer
