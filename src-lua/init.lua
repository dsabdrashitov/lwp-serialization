local lwp = {}
local module_path = (...):match("(.-)[^%.]+$")

local dll_loader, err = package.loadlib(module_path:gsub("%.", "\\") .. "lua_win_pipe_v2.dll", "luaopen_lua_win_pipe_v2")
if not dll_loader then
    error("Failed to load lua_win_pipe_v2.dll: " .. tostring(err))
end
local dll = dll_loader()

--- Create new client pipe
-- @param name string Pipe name [[\\.\pipe\my_pipe]]
-- @param mode string|nil (optional) "r", "w", or "rw" (default "rw")
-- @return userdata|(nil, string) Pipe object or (nil + error message)
lwp.client_pipe = function(name, mode)
    return dll.client_pipe(name, mode or "rw")
end

--- Create new server pipe
-- @param name string Pipe name
-- @param opts table Options table:
--   mode: "r", "w", "rw" (default: "rw")
--   message_mode: boolean (default: false)
--   first_instance: boolean (default: true)
--   max_instances: integer (default: 1)
--   output_buffer_size: integer (default: 4096)
--   input_buffer_size: integer (default: 4096)
lwp.server_pipe = function(name, opts)
    opts = opts or {}
    
    local mode           = opts.mode or "rw"
    local message_mode   = opts.message_mode or false
    local first_instance = true
    if opts.first_instance ~= nil then first_instance = opts.first_instance end
    
    local max_instances  = opts.max_instances or 1
    local out_buf        = opts.output_buffer_size or 4096
    local in_buf         = opts.input_buffer_size or 4096

    return dll.server_pipe(
        name,
        mode,
        message_mode,
        first_instance,
        max_instances,
        out_buf,
        in_buf
    )
end

return lwp
