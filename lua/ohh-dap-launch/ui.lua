local popup = require("plenary.popup")

local UI = {}

function UI:show_select_ui(items, title, on_choice)
  vim.ui.select(
    items,
    {
      prompt = title,
      format_item = function(item)
        return item.name or tostring(item)
      end,
    },
    function(choice)
      if choice then on_choice(choice) end
    end)
end

function UI:show_input_ui(title, on_choice)
  vim.ui.input(
    {
      prompt = title,
      format_item = function(item)
        return item.name or tostring(item)
      end,
    },
    function(choice)
      if choice then on_choice(choice) end
    end)
end

return UI
