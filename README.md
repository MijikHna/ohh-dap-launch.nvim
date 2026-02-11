# Launch Config

## Description

Small plugin to be able to add configuration for debugging to `.nvim/launch.json` as I don't use set `adapters` in `nvim-dap` configuration.

I don't want to use `adapters` in `nvim-dap` configuration as I some parameters of the adapter can vary and I also don't want to overload 

## Installation

## Default Setup

```lua
{
  custom_configs_location = vim.fn.stdpath("state") .. "/ohh-dap-launch/data",
  use_default_configs = true,
  vertical = true,
  dap_folder = ".nvim",
}
```

### LazyVim

```lua
return {
  "mijikhna/ohh-dap-launch.nvim",
  build = function() require("ohh-dap-launch").install() end,
  dependencies = { "L3MON4D3/LuaSnip" },
}
```


> [!WARN]
> I haven't tested installation with other plugin manager.
> I would be grateful for the feedback about installation with other plugin managers

### Vim Plug

`Plug 'MijikHna/launch-config.nvim'`

### Packer

`use 'MijikHna/launch-config.nvim'`

## Usage

The plugin provides 4 commands to use and maintain the debug configurations

1. `OhhDapLaunch` - select one from an existing configuration
2. `OhhDapLaunch addTemplate <NAME>` - add new debug configuration template to existing templates
3. `OhhDapLaunch deleteTemplate` - delete a template from existing templates
4. `OhhDapLaunch editTempate` - edit one of the existing templates

## Others

I am pretty new to lua and neovim api. I would appreciate a valuable feedback. Don't hesitate to open an issue regarding the main functionality and UI. As this plugin does cover my simple needs I may not have thoroughly reasoned about all possible use cases.
