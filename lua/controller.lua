local vim = vim
local uv = vim.loop
local log = require("log")
local Adtype = require("adt")

local ESPEAK = "espeak"

-- Singleton to avoid multiple instances
local controller = {
    model = nil,
    hooks = {},
    process = nil,
    next_message = nil
}

local Message = Adtype {
    Content = { "msg" },
    Meta = { "msg" },
}

return function(model)
    controller.model = model

    local speak_message = function(message, on_exit)
        if message == nil then
            return
        end

        local args = { "--punct" }
        if model.speed ~= nil then
            table.insert(args, "-s")
            table.insert(args, tostring(model.speed))
        end
        table.insert(args, "-p")

        message.match {
            Content = function(msg)
                table.insert(args, tostring(model.pitches.content))
                table.insert(args, msg)
            end,
            Meta = function(msg)
                table.insert(args, tostring(model.pitches.meta))
                table.insert(args, msg)
            end,
        }

        local handle, _ = uv.spawn(ESPEAK, { args = args }, on_exit)

        return handle
    end

    local push_message = function(message, keep)
        if message == nil then
            return
        end

        local speak_next = nil
        speak_next = function(code, signal)
            if controller.next_message ~= nil then
                local next = controller.next_message
                controller.next_message = nil
                controller.process = {
                    handle = speak_message(next, speak_next),
                    keep = false,
                }
            end
        end

        if controller.process ~= nil and controller.process.keep == true then
            -- Leave the current process alive and replace the following sequence
            controller.process.keep = false; -- Only keep once
            controller.next_message = message
        else
            if controller.process ~= nil then
                -- Kill the current process and delete the sequence
                local handle = controller.process.handle
                uv.process_kill(handle)
                controller.process = nil
            end
            controller.next_message = nil

            -- Proceed
            controller.process = {
                handle = speak_message(message, speak_next),
                keep = keep,
            }
        end
    end

    local speak_content = function(sentence)
        if sentence ~= nil then
            push_message(Message.Content(sentence))
        end
    end

    local speak_meta = function(sentence, keep)
        if sentence ~= nil then
            push_message(Message.Meta(sentence), keep)
        end
    end

    controller.speak_line = function()
        speak_content(vim.api.nvim_get_current_line())
    end

    controller.enable = function()
        speak_meta("Reader enabled")
        model.enable()
    end

    controller.disable = function()
        speak_meta("Reader disabled")
        model.disable()
    end

    controller.speak_buffer_name = function(keep)
        local buffer_name = vim.api.nvim_buf_get_name(0)
        local basename = string.gsub(buffer_name, "(.*/)(.*)", "%2")
        speak_meta(basename, keep)
    end

    controller.speak_completion_list = function()
        local info = vim.fn.complete_info()
        log(info.pum_visible)
        for _, el in ipairs(info.items) do
            log(el)
        end
    end

    controller.hooks.buffer_changed = function()
        if model.enabled then
            controller.speak_buffer_name(true)
        end
    end

    controller.hooks.cursor_moved = function(options)
        options = options or {}

        local curpos = vim.api.nvim_win_get_cursor(0)
        local old_row, old_col = controller.model.cursor_position()
        local row = curpos[1]
        local col = curpos[2]

        controller.model.update_cursor_position(row, col)

        if controller.model.enabled == true then
            if controller.model.did_line_change() then
                controller.speak_line()
            elseif col ~= old_col then
                local line = vim.api.nvim_get_current_line()
                local start = ((col < old_col) and col or old_col) + 1
                local finish = (col < old_col) and old_col or col

                local to_speak = string.sub(line, start, finish)

                if finish == start and options.insert then -- single character
                    local char = to_speak
                    -- In case of whitespace say the preceeding word
                    if char == " " or char == "\t" then
                        local previous_line = string.sub(line, 0, finish)
                        to_speak = previous_line:match("[%w_]+%s?$")
                    end
                elseif finish - start > 0 then -- longer words
                    to_speak = string.sub(line, start, finish + 1)
                end

                speak_content(to_speak)
            end
        end
    end


    return controller
end
