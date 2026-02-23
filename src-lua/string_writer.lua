local StringWriter = {}

StringWriter.__index = StringWriter

function StringWriter:new()
    local obj = setmetatable({}, self)
    obj.buffer = {}
    return obj
end

--- Resets the internal buffer. 
-- Useful for reusing the object and reducing GC pressure.
function StringWriter:reset()
    self.buffer = {}
end

--- Appends binary data to the buffer.
-- @param data string (binary)
-- @return true or nil, error_message
function StringWriter:write(data)
    -- if there_is_some_error then
    --     return nil, "error description"
    -- end
    self.buffer[#self.buffer + 1] = data
    return true
end

--- Concatenates and returns the final string.
-- @return string
function StringWriter:to_string()
    return table.concat(self.buffer)
end

return StringWriter
