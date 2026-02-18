local StringReader = {}
StringReader.__index = StringReader

function StringReader:new(byte_array)
    local obj = setmetatable({}, self)
    obj.data = byte_array
    obj.pos = 1
    obj.size = #byte_array
    return obj
end

--- Reads exactly n bytes or throws an error.
-- @param n number of bytes to read
-- @return string (binary)
function StringReader:read(n)
    local last = self.pos + n - 1
    if last > self.size then
        error("Unexpected end of stream: requested " .. tostring(n) .. " bytes at " .. tostring(self.pos))
    end
    local chunk = self.data:sub(self.pos, last)
    self.pos = last + 1
    return chunk
end

return StringReader
