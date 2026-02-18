local lwps = {}
local module_path = (...):match("(.-)[^%.]+$")

lwps.Codec        = require(module_path .. "codec")
lwps.Registry     = require(module_path .. "registry")
lwps.Serializer   = require(module_path .. "serializer")
lwps.Deserializer = require(module_path .. "deserializer")
lwps.StringWriter = require(module_path .. "string_writer")
lwps.StringReader = require(module_path .. "string_reader")

return lwps
