local vim = vim
local log = require("log")

local create_user_command = vim.api.nvim_create_user_command --- @type function
local create_autocmd = vim.api.nvim_create_autocmd           --- @type function


local speak = { api = {} }

speak.setup = function(options)
    local model = require("model")
    model.setup(options)
    local controller = require("controller")(model)

    create_user_command("ReaderEnable", controller.enable, { desc = "Enable reader.nvim" })
    create_user_command("ReaderDisable", controller.disable, { desc = "Enable reader.nvim" })
    create_user_command("ReadLine", controller.speak_line, { desc = "Read the current line" })
    create_user_command("ReadName", controller.speak_buffer_name, { desc = "Say the current buffer name" })
    create_user_command("ReadCompletion", controller.speak_completion_list, { desc = "Say the contents of the completion list" })

    speak.api.enable = controller.enable
    speak.api.disable = controller.disable
    speak.api.speak_line = controller.speak_line
    speak.api.speak_buffer_name = controller.speak_buffer_name
    speak.api.speak_completion_list = controller.speak_completion_list

    create_autocmd("User", {
        pattern = "CocOpenFloat",
        callback = function(_)
            log("new window")
        end
    })
    create_autocmd({ "CursorMoved" }, {
        callback = function(_)
            --log("cursor moved")
            controller.hooks.cursor_moved({})
        end
    })
    create_autocmd({ "CursorMovedI" }, {
        callback = function(_)
            controller.hooks.cursor_moved({ insert = true })
        end
    })
    create_autocmd({ "BufEnter" }, {
        callback = function(_)
            --log("buf enter")
            controller.hooks.buffer_changed()
        end
    })
end


return speak
