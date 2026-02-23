local SerializationError = {}

SerializationError.__index = SerializationError

SerializationError.Type = {
    PROTOCOL  = "PROTOCOL",
    TRANSPORT = "TRANSPORT"
}

--- Creates a new SerializationError instance.
-- @param message string Human-readable error description.
-- @param error_type string One of SerializationError.Type.
-- @param cause any (optional) The underlying error that caused this.
function SerializationError:new(message, error_type, cause)
    local obj = setmetatable({}, self)
    
    obj.message = tostring(message)
    obj.type = error_type or SerializationError.Type.PROTOCOL
    obj.cause = cause
    obj.traceback = debug.traceback(nil, 2)
    
    return obj
end

--- Checks if an object is an instance of SerializationError.
-- @param obj any The object to check.
-- @return boolean
function SerializationError:defines(obj)
    local mt = getmetatable(obj)
    if not mt then
        return false
    end
    return mt == self
end

--- Returns a formatted string for logs/display.
-- @return string
function SerializationError:__tostring()
    local str = string.format("[%s_ERROR] %s", self.type, self.message)
    if self.cause then
        str = str .. " (Cause: " .. tostring(self.cause) .. ")"
    end
    return str
end

return SerializationError
