local test_model = function()
    local model = require "lua.model"

    assert(model.enabled == false)
end

local tests = { { name = "model", fun = test_model } }

local successful = 0
local total = 0
for _, test in pairs(tests) do
    local status, err = pcall(test.fun)
    total = total+1

    if (status) then
        print("[" .. total .. "] " .. test.name .. " successful...")
        successful = successful + 1
    else
        print("[" .. total .. "] " .. test.name .. " failed: " .. err)
    end
end

print("[" .. successful .. "/" .. total .. "]")
if (successful == total) then
    print("Everything ok")
else
    print("Some tests failed!")
end
