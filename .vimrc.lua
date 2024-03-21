local vim = vim

vim.opt.runtimepath:append(',.')

local reload = function()
    require("speak").setup {
        autostart = true,
        speed = 260,
    }
end

local create_user_command = vim.api.nvim_create_user_command --- @type function
create_user_command("ReloadPlugin", reload, {})

--reload()
