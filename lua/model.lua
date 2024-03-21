local setreadonly = function(table)
    return setmetatable({}, {
        __index = function(_, key) return table[key] end,
        __newindex = function(_, _, _)
            error("Read only table")
        end,
        __metatable = false
    })
end


local model = {
    enabled = false,
    speed = nil,
    pitches = { content = 60, meta = 10 },
    old_cursor_position = { 0, 0 },
    current_cursor_position = { 0, 0 },
}


local get_current_cursor_position = function()
    return model.current_cursor_position[1], model.current_cursor_position[2]
end

local get_old_cursor_position = function()
    return model.old_cursor_position[1], model.old_cursor_position[2]
end


model.enable = function()
    model.enabled = true
end

model.disable = function()
    model.enabled = false
end

model.cursor_position = function()
    return model.current_cursor_position[1], model.current_cursor_position[2]
end

model.did_line_change = function()
    local old_row, _ = get_old_cursor_position()
    local current_row, _ = get_current_cursor_position()
    return current_row ~= old_row
end

model.setup = function(options)
    if options.autostart == true then
        model.enable()
    end

    if type(options.speed) == "number" then
        model.speed = options.speed
    end

    model.pitches = { content = 50, meta = 20 }
    if type(options.pitches) == "table" then
        if type(options.pitches.content) == "number" then
            model.pitches.content = options.pitches.content
        end
        if type(options.pitches.meta) == "number" then
            model.pitches.meta = options.pitches.meta
        end
    end
end

model.update_cursor_position = function(row, column)
    model.old_cursor_position = model.current_cursor_position
    model.current_cursor_position = { row, column }
end


return setreadonly(model)
