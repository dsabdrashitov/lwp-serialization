local Registry = {}

Registry.__index = Registry

--- Creates a new Registry.
-- @param initial_map (optional) Table with predefined [id] = object pairs.
function Registry:new(initial_map)
    local obj = setmetatable({}, self)
    obj.obj_to_id = {}
    obj.id_to_obj = {}
    obj.next_id = 0

    if initial_map then
        for id, item in pairs(initial_map) do
            local int_id = math.tointeger(id)
            if not int_id or int_id < 0 then
                error("Registry error: ID must be a non-negative integer")
            end
            
            obj.obj_to_id[item] = int_id
            obj.id_to_obj[int_id] = item
            -- Ensure next_id is always ahead of any manually assigned IDs
            if int_id >= obj.next_id then
                obj.next_id = int_id + 1
            end
        end
    end

    return obj
end

--- Registers an object using autoincrement ID.
-- @param obj The object to register.
-- @return number The assigned ID.
function Registry:register(obj)
    if obj == nil then
        return nil
    end
    
    if self.obj_to_id[obj] then
        return self.obj_to_id[obj]
    end

    local id = self.next_id
    self.next_id = self.next_id + 1

    self.obj_to_id[obj] = id
    self.id_to_obj[id] = obj
    
    return id
end

--- Removes an object from the registry.
-- @param obj The object to unregister.
function Registry:unregister(obj)
    local id = self.obj_to_id[obj]
    if id ~= nil then
        self.id_to_obj[id] = nil
        self.obj_to_id[obj] = nil
    end
end

--- Returns the ID associated with an object.
-- @return number or nil
function Registry:get_id(obj)
    if obj == nil then
        return nil
    end
    return self.obj_to_id[obj]
end

--- Returns the object associated with an ID.
-- @return any or nil
function Registry:get_obj(id)
    return self.id_to_obj[id]
end

--- Clears the registry.
function Registry:clear()
    self.obj_to_id = {}
    self.id_to_obj = {}
    self.next_id = 0
end

return Registry
