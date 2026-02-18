local lwps = require("build.lwp-serialization.init")

-- 1. Создаем реестр с предопределенной таблицей
local reg = lwps.Registry:new()
local config = { version = "1.0", api = "stable" }
reg:register(config)

-- 2. Инициализируем кодек
local codec = lwps.Codec:new(reg)

-- 3. Создаем данные с циклической ссылкой и объектом из Registry
local data = {
    title = "Main",
    ref_to_config = config,
    sub = {}
}
data.sub.parent = data -- Цикл

-- 4. Сериализация
local bytes = codec:encode(data)
print("Encoded size: " .. #bytes .. " bytes")

-- 5. Десериализация
local decoded = codec:decode(bytes)

assert(decoded.ref_to_config == config) -- Ссылка на реестр сохранена
assert(decoded.sub.parent == decoded)   -- Цикл восстановлен
