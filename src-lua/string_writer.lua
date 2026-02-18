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
function StringWriter:write(data)
    self.buffer[#self.buffer + 1] = data
end

--- Concatenates and returns the final string.
-- @return string
function StringWriter:to_string()
    return table.concat(self.buffer)
end

return StringWriter
