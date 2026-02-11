require("plenary")
require("plenary.busted")

package.loaded["blink.cmp"] = {
  get_lsp_capabilities = function() return {} end
}

local test_data_dir = vim.uv.cwd() .. "/tests/data/"

local defaults = {
  custom_configs_location = test_data_dir,
  use_default_configs = true,
  vertical = true,
  dap_folder = "tests/.nvim",
}

local function create_launch_configs()
  -- Ensure test_data_dir exists
  if vim.fn.isdirectory(test_data_dir) == 0 then
    vim.fn.mkdir(test_data_dir, "p")
  end

  -- Simple debug configs
  local cpp_config =
  '{\n  "name": "C++ Launch",\n  "type": "cppdbg",\n  "request": "launch",\n  "program": "${file}",\n  "args": []\n}'
  local python_config =
  '{\n  "name": "Python Launch",\n  "type": "python",\n  "request": "launch",\n  "program": "${file}",\n  "args": []\n}'

  -- Write cpp.json
  local cpp_file = io.open(test_data_dir .. "cpp.json", "w")

  if cpp_file then
    cpp_file:write(cpp_config)
    cpp_file:close()
  end

  -- Write python.json
  local python_file = io.open(test_data_dir .. "python.json", "w")
  if python_file then
    python_file:write(python_config)
    python_file:close()
  end
end

local function delete_temp_test_data_dir()
  -- Remove cpp.json and python.json if they exist
  local cpp_path = test_data_dir .. "cpp.json"
  local python_path = test_data_dir .. "python.json"

  if vim.fn.filereadable(cpp_path) == 1 then
    os.remove(cpp_path)
  end

  if vim.fn.filereadable(python_path) == 1 then
    os.remove(python_path)
  end

  -- Remove test_data_dir if it exists
  if vim.fn.isdirectory(test_data_dir) == 1 then
    vim.fn.delete(test_data_dir, "rf")
  end
end

local function delete_launch_folder()
  local launch_dir_path = vim.uv.cwd() .. "/" .. defaults.dap_folder

  -- Remove launch_dir
  if vim.fn.isdirectory(launch_dir_path) == 1 then
    vim.fn.delete(launch_dir_path, "rf")
  end
end


local uv = vim.uv or vim.loop
local home = os.getenv("HOME")
local pack_opt_dir = home .. "/.local/share/nvim/site/pack/test/opt/"
local luasnip_src = home .. "/.local/share/nvim/lazy/LuaSnip" -- adjust if your luasnip is elsewhere
local luasnip_dest = pack_opt_dir .. "luasnip"

local function symlink_luasnip()
  if vim.fn.isdirectory(pack_opt_dir) == 0 then
    vim.fn.mkdir(pack_opt_dir, "p")
  end
  if vim.fn.isdirectory(luasnip_dest) == 0 then
    uv.fs_symlink(luasnip_src, luasnip_dest, { dir = true })
  end
end

local function remove_luasnip_symlink()
  if vim.fn.isdirectory(luasnip_dest) == 1 then
    vim.fn.delete(luasnip_dest, "rf")
  end
  package.loaded["luasnip"] = nil
end


describe("OhhDapLaunch Testing", function()
  before_each(function()
    create_launch_configs()

    -- Ensure launch configs exist for selection
    create_launch_configs()
    symlink_luasnip()

    vim.cmd("packadd luasnip")
    local luasnip = require("luasnip")
  end)

  after_each(function()
    vim.ui.select = nil
    vim.ui.input = nil

    delete_temp_test_data_dir()
    delete_launch_folder()
    remove_luasnip_symlink()
  end)

  describe("Select Logic", function()
    it("Select existing template", function()
      -- Arrange
      require("ohh-dap-launch").setup(defaults)

      -- Simulate selection of the first template ("cpp.json")
      vim.ui.select = function(items, opts, callback)
        callback(items[1])
      end

      -- Act
      vim.cmd("OhhDapLaunch")

      -- Assert
      local dap_folder = vim.uv.cwd() .. "/" .. defaults.dap_folder
      local launch_path = dap_folder .. "/launch.json"
      assert.equals(vim.fn.isdirectory(dap_folder), 1)
      assert.equals(vim.fn.filereadable(launch_path), 1)
    end)
  end)

  describe("AddTemlate Logic", function()
    it("Add new empty Template", function()
      -- Arrange
      require("ohh-dap-launch").setup(defaults)

      -- Simulate selection of the first template ("cpp.json")
      vim.ui.select = function(items, opts, callback)
        callback(items[1])
      end

      new_template_name = "test"
      -- Act
      vim.cmd("OhhDapLaunch addTemplate " .. new_template_name)

      -- Assert
      local new_template_file = defaults.custom_configs_location .. "/" .. new_template_name .. ".json"
      assert.equals(vim.fn.filereadable(new_template_file), 1)
    end)
    -- it("Add new Template from existing Templates", function() end)
  end)

  describe("DeleteTemplate Logic", function()
    it("Delete existing Template", function()
      -- Arrange
      require("ohh-dap-launch").setup(defaults)

      -- Simulate selection of the first template ("cpp.json")
      vim.ui.select = function(items, opts, callback)
        callback(items[1])
      end

      -- Act
      vim.cmd("OhhDapLaunch deleteTemplate")

      -- Assert
      local template_file = defaults.custom_configs_location .. "/" .. "cpp.json"
      assert.equals(vim.fn.filereadable(launch_path), 0)
    end)
  end)

  describe("EditTemplate Logic", function()
    it("Edit existing Template", function()
      -- Arrange
      require("ohh-dap-launch").setup(defaults)

      -- Simulate selection of the first template ("cpp.json")
      vim.ui.select = function(items, opts, callback)
        callback(items[1])
      end

      -- Act
      vim.cmd("OhhDapLaunch editTemplate")

      -- Assert
      local float_win = nil
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local config = vim.api.nvim_win_get_config(win)
        if config.relative ~= "" then
          float_win = win
          break
        end
      end

      local buf = vim.api.nvim_win_get_buf(float_win)
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      -- Check if the first item (template) name is present in the lines

      assert(float_win, "No floating window found")

      cpp_line = '"name": "C++ Launch"'
      local found = false
      for _, line in ipairs(lines) do
        if line:match('"name":%s*"C%+%+ Launch"') then
          found = true
          break
        end
      end
      assert(found, 'Floating window does not contain the "name" line')
    end)
  end)
end)
