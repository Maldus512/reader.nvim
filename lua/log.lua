local log_fh = io.open("/tmp/nvim." .. os.getenv("USER") .. "/speaker.nvim.log", "w")

local start = os.clock()

local log = function(...)
    local objects = {}
    for i = 1, select('#', ...) do
        local v = select(i, ...)
        table.insert(objects, vim.inspect(v))
    end

    local now = os.clock()

    log_fh:write("[" .. tostring(now - start) .. "] " .. table.concat(objects, ' ') .. '\n')
    log_fh:flush()
end

return log
