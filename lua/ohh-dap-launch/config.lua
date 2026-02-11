local command = require("ohh-dap-launch.command")

local Config = {}

local defaults = {
  custom_configs_location = vim.fn.stdpath("state") .. "/ohh-dap-launch/data",
  use_default_configs = true,
  vertical = true,
  dap_folder = ".nvim",
}

--[[
  Defines Plugins Commands
  1. OhhDapLaunch - select one debug configuration template
  2. OhhDapLaunch addTemplate - add new debug configuration template
  3. OhhDapLaunch addTemplate - edit existing debug configuration template
  4. OhhDapLaunch addTemplate - delete existing debug configuration template
]] --
function Config:new(partial_config)
  vim.api.nvim_create_user_command(
    'OhhDapLaunch',
    function(opts)
      local args = vim.split(opts.args, " ")

      local subcommand = args[1]

      if not subcommand or subcommand == "" then
        -- Listing configs logic here
        command:show_templates(
          self.config,
          "Select a Template",
          function(selected_debug_config)
            command:select_template(selected_debug_config, self.config)
          end
        )
      elseif subcommand == "addTemplate" then
        -- Adding config logic here
        if args[2] == nil then
          vim.notify("Please Add a name for new debug template")
          return
        end

        local new_template_name = args[2]

        command:show_templates(
          self.config,
          "Select a Template",
          function(selected_debug_config)
            command:add_template(selected_debug_config, new_template_name, self.config)
          end
        )
      elseif subcommand == "editTemplate" then
        command:show_templates(
          self.config,
          "Select a Template",
          function(selected_debug_config)
            command:edit_template(selected_debug_config, self.config)
          end
        )
        -- Editing config logic here
      elseif subcommand == "deleteTemplate" then
        -- Deleting config logic here
        command:show_templates(
          self.config,
          "Select a Template",
          function(selected_debug_config)
            command:delete_template(selected_debug_config, self.config)
          end
        )
      else
        -- Unknown subcommand logic here
        vim.notify(subcommand .. "isn't know")
      end
    end,
    {
      nargs = "*",
      complete = function(arg_lead, cmd_line, cursor_pos)
        return { "addTemplate", "editTemplate", "deleteTemplate" }
      end,
      desc = "DAP Launch command with subcommands"
    }
  )

  self.config = vim.tbl_deep_extend("force", defaults, partial_config or {})
  return self
end

return Config
