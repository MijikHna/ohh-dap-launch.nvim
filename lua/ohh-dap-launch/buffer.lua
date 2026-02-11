local Buffer = {}

function Buffer:create_floating_buffer(config, opts, header)
  -- Create a new scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Floating window dimensions
  local row = math.floor((vim.o.lines - opts.height) / 2 - 1)
  local col = math.floor((vim.o.columns - opts.width) / 2)

  -- Open floating window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = opts.width,
    height = opts.height,
    row = row,
    col = col,
    style = "minimal",
    border = "shadow"
  })

  if header then
    local separator = string.rep("-", opts.width)
    table.insert(header, separator)
    table.insert(header, "")

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, header)
  end

  return win, buf
end

return Buffer
