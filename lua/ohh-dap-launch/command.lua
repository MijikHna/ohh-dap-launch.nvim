local UI = require("ohh-dap-launch.ui")
local Buffer = require("ohh-dap-launch.buffer")

local ls = require("luasnip")

local Command = {}

--[[
    Retrieves all debug configuration files from the specified directory.

    @param custom_configs_location string: Path to the directory containing custom debug configurations.
    @return table: List of configuration file names.
]] --
function Command:_get_all_configs(custom_configs_location)
  local configs = {}
  local handle = vim.loop.fs_scandir(custom_configs_location)

  if handle then
    while true do
      local name, typ = vim.loop.fs_scandir_next(handle)

      if not name then break end

      if typ == "file" then
        table.insert(configs, name)
      end
    end
  else
    vim.notify("Could not open directory: " .. custom_configs_location, vim.log.levels.ERROR)
  end
  return configs
end

--[[
    Gets the path to the launch.json file for the given config.
    Ensures the target directory exists, creating it if necessary.

    @param config table: Configuration object containing dap_folder.
    @return string: Path to launch.json.
]] --
function Command:_get_launch_json_location(config)
  local nvim_dir = vim.uv.cwd() .. "/" .. config.dap_folder
  local launch_path = nvim_dir .. "/launch.json"

  -- Ensure .nvim directory exists
  if vim.fn.isdirectory(nvim_dir) == 0 then
    vim.fn.mkdir(nvim_dir, "p")
  end

  return launch_path
end

--[[
    Displays available debug configuration templates in a selection UI.

    @param config table: Configuration object containing custom_configs_location.
    @param title string: Title for the selection UI.
    @param callback function: Function to call when a template is selected.
]] --
function Command:show_templates(config, title, callback)
  local config_names = self:_get_all_configs(config.custom_configs_location)

  if #config_names == 0 then
    vim.notify("No config snippets found in: " .. config.custom_configs_location, vim.log.levels.INFO)
    return {}
  end

  UI:show_select_ui(config_names, title, callback)
end

-- THINK-ABOUT-IT: maybe place callbacks somewhere else
-- callbacks

--[[
    Allows the user to select and add a debug configuration template to launch.json.
    Opens the template in a floating buffer for review and editing.

    @param debug_config_name string: Name of the template file to select.
    @param config table: Configuration object containing custom_configs_location and dap_folder.
]] --
function Command:select_template(debug_config_name, config)
  local template_path = config.custom_configs_location .. "/" .. debug_config_name
  local launch_json_path = self:_get_launch_json_location(config)

  -- If launch.json doesn't exist, create it with default content
  if vim.fn.filereadable(launch_json_path) == 0 then
    local launch_json_init_content = '{\n\t"version": "0.2.0",\n\t"configurations": []\n}'
    local ok, launch_json_file_handler = pcall(io.open, launch_json_path, "w")

    if not ok or not launch_json_file_handler then
      vim.notify("Couln't open 'launch.json' at " .. template_path, vim.log.levels.ERROR)
      return
    end

    launch_json_file_handler:write(launch_json_init_content)
    launch_json_file_handler:close()
  end

  -- Read template config
  local ok, template_file_handler = pcall(io.open, template_path, "r")

  if not ok or not template_file_handler then
    vim.notify("Could not open template file: " .. template_path, vim.log.levels.ERROR)
    return
  end

  local template_content = template_file_handler:read("*a")
  template_file_handler:close()

  local float_window_opts = { width = math.floor(vim.o.columns * 0.7), height = math.floor(vim.o.lines * 0.9) }

  -- Show Snippet Buffer in Float
  local header = { "Commands: oa - Accept    od - Decline" }

  local win, buf = Buffer:create_floating_buffer(config, float_window_opts, header)

  vim.api.nvim_win_set_cursor(win, { #header, 0 })
  ls.snip_expand(ls.parser.parse_snippet("debug_config", template_content))

  vim.api.nvim_buf_set_keymap(buf, "n", "oa", "", {
    noremap = true,
    callback = function()
      -- Read launch.json and Serialize
      local ok, launch_json_content_obj = pcall(vim.fn.json_decode, table.concat(vim.fn.readfile(launch_json_path)))

      if not ok then
        vim.notify("Couldn't decode 'launch.json'", vim.log.levels.ERROR)
        vim.api.nvim_win_close(win, true)
        return
      end

      -- Add template content to serialized launch.json
      local template_content = table.concat(vim.api.nvim_buf_get_lines(buf, #header - 1, -1, false), "\n")
      local ok, template_content_obj = pcall(vim.fn.json_decode, template_content)

      if not ok then
        vim.notify(
          "Syntax error while decoding new debug configuration: " .. vim.inspect(template_content_obj),
          vim.log.levels.WARN
        )
        return
      end

      table.insert(launch_json_content_obj.configurations, template_content_obj)

      vim.api.nvim_win_close(win, true)

      -- Write new content to launch.json, use jq if exists for formatting
      command = "edit " .. launch_json_path
      if config.vertical then
        command = "vertical edit " .. launch_json_path
      end

      vim.cmd(command)

      buf = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {}) -- remove all lines
      local content_str = vim.fn.json_encode(launch_json_content_obj)

      local json_lines = {}
      if vim.fn.executable("jq") == 1 then
        local formatted = vim.fn.system({ "jq", "." }, content_str)
        json_lines = vim.split(formatted, "\n")
      else
        json_lines = { content_str }
      end

      if #json_lines == 0 then
        vim.notify("Failed to attach new debug configuration", vim.log.levels.ERROR)
        return
      end

      ok = pcall(vim.api.nvim_buf_set_lines, buf, 0, 0, false, json_lines)
      if not ok then vim.notify("Failed to attach new debug configuration", vim.log.levels.ERROR) end
    end,
    desc = "Accept new Debug Configuration"
  })

  vim.api.nvim_buf_set_keymap(buf, "n", "od", "", {
    noremap = true,
    callback = function() vim.api.nvim_win_close(win, true) end,
    desc = "Decline new Debug Configuration",
  })
end

--[[
    Creates a new debug configuration template file.
    Optionally copies content from an existing template.

    @param debug_config_name string|nil: Name of an existing template to base the new template on.
    @param config table: Configuration object containing custom_configs_location.
]] --
function Command:add_template(debug_config_name, new_template_name, config)
  -- input a name for new template
  local ok, template_obj = nil, nil

  -- select a template content if debug_config_name provided
  if debug_config_name ~= nil then
    local template_path = config.custom_configs_location .. debug_config_name
    local template_file = io.open(template_path, "r")

    if not template_file then
      vim.notify("Could not open template file: " .. template_path, vim.log.levels.ERROR)
      return
    end

    local template_content = template_file:read("*a")
    template_file:close()

    ok, template_obj = pcall(vim.fn.json_decode, template_content)

    if not ok then
      vim.notify("Failed to decode template JSON: " .. template_path, vim.log.levels.ERROR)
      return
    end
  end

  -- open a buffer with
  local new_template_file = config.custom_configs_location .. "/" .. new_template_name .. ".json"

  local command = "edit " .. new_template_file
  if config.vertical then command = "vertical edit " .. new_template_file end

  if template_obj ~= nil then
    local file_handler = io.open(new_template_file, "w")
    local ok, content = vim.fn.json_encode(template_obj)

    if not ok then vim.notify("Coulnd't write into template file - " .. new_template_file) end

    local json_str = vim.fn.json_encode(template_obj)

    if vim.fn.executable("jq") == 1 then json_str = vim.fn.system({ "jq", "." }, json_str) end

    file_handler:write(json_str)
    file_handler:close()
  end

  vim.cmd("edit " .. new_template_file)
end

--[[
    Deletes a debug configuration template file.

    @param debug_config_name string: Name of the template file to delete.
    @param config table: Configuration object containing custom_configs_location.
]] --
function Command:delete_template(debug_config_name, config)
  -- get the template location
  local template = config.custom_configs_location .. "/" .. debug_config_name

  if not vim.fn.filereadable(template) then return end

  local ok = pcall(os.remove, template)

  if not ok then
    vim.notify("Couldn't delete template: " .. template)
    return
  end

  vim.notify("Template " .. template .. "has been deleted", vim.log.levels.INFO)
end

--[[
    Opens a debug configuration template file for editing.

    @param debug_config_name string: Name of the template file to edit.
    @param config table: Configuration object containing custom_configs_location.
]] --
function Command:edit_template(debug_config_name, config)
  local template = config.custom_configs_location .. "/" .. debug_config_name

  if not vim.fn.filereadable(template) then
    vim.notify("Template " .. template .. "doesn't exists")
    return
  end

  local command = "edit " .. template
  if config.vertical then command = "vertical edit " .. template end

  vim.cmd(command)
end

return Command
