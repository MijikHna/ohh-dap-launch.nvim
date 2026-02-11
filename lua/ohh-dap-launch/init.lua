local Config = require("ohh-dap-launch.config")

local OhhDapLaunch = {}

OhhDapLaunch.setup = function(partial_config)
  OhhDapLaunch.config = Config:new(partial_config)
end

--[[
    Copies predefined debug configurations to default data folder ~/state/ohh-dap-launch

    predefined debug configs are located at plugin's /data folder
 ]] --
OhhDapLaunch.install = function(config_template_location)
  local uv = vim.loop

  -- Find the plugin root directory
  local plugin_config_path = vim.api.nvim_get_runtime_file("lua/ohh-dap-launch/init.lua", false)[1]
  local plugin_root = plugin_config_path:match("(.+)/lua/ohh%-dap%-launch/init.lua")
  local source_dir = plugin_root .. "/data"
  local target_dir = vim.fn.stdpath("state") .. "/ohh-dap-launch/data"

  -- Check if the target directory exists
  local target_stat = uv.fs_stat(target_dir)

  if target_stat == nil then
    target_dir_created = vim.fn.mkdir(target_dir, 'p')
  end

  if (target_stat and target_stat.type == "directory") or target_dir_created then
    -- Check if the directory contains files
    local handle = uv.fs_scandir(target_dir)
    if handle and not uv.fs_scandir_next(handle) then
      -- Create the target directory
      uv.fs_mkdir(target_dir, 493) -- 493 is octal 0755

      -- Copy files from source_dir to target_dir
      local source_handle = uv.fs_scandir(source_dir)
      if not source_handle then
        print("Source directory does not exist or cannot be read.")
        return
      end

      for name in function() return uv.fs_scandir_next(source_handle) end do
        local source_path = source_dir .. "/" .. name
        local target_path = target_dir .. "/" .. name

        local source_file = uv.fs_open(source_path, "r", 438) -- 438 is octal 0666
        local target_file = uv.fs_open(target_path, "w", 438)

        if source_file and target_file then
          local stat = uv.fs_fstat(source_file)
          local data = uv.fs_read(source_file, stat.size, 0)
          uv.fs_write(target_file, data, 0)
          uv.fs_close(source_file)
          uv.fs_close(target_file)
        end
      end
    end
  end
end

return OhhDapLaunch
