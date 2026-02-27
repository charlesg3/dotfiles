-- YAML outline sidebar, bound to <C-e> to mirror TlistToggle behaviour.
-- Opens a left vertical split showing top-level and second-level keys.
-- <CR> jumps to the key in the source buffer; q / <C-e> closes it.
-- Requires :TSInstall yaml (one-time setup).

local outline_state = {}  -- src_bufnr → { win, buf }

local function close_outline(src_bufnr)
  local state = outline_state[src_bufnr]
  if state and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  outline_state[src_bufnr] = nil
end

local function yaml_outline_toggle()
  local src_bufnr = vim.api.nvim_get_current_buf()
  local src_win   = vim.api.nvim_get_current_win()

  -- Toggle off if already open
  local existing = outline_state[src_bufnr]
  if existing and vim.api.nvim_win_is_valid(existing.win) then
    close_outline(src_bufnr)
    return
  end

  local ok, parser = pcall(vim.treesitter.get_parser, src_bufnr, 'yaml')
  if not ok or not parser then
    vim.notify('yaml_outline: parser not available — run :TSInstall yaml', vim.log.levels.WARN)
    return
  end

  local tree = parser:parse()[1]
  local root = tree:root()

  local ok_q, query = pcall(vim.treesitter.query.parse, 'yaml',
    '(block_mapping_pair key: (flow_node) @key)')
  if not ok_q then
    vim.notify('yaml_outline: query failed: ' .. tostring(query), vim.log.levels.ERROR)
    return
  end

  -- Count block_mapping ancestors for structural depth (not whitespace-based)
  local function mapping_depth(node)
    local depth, n = 0, node:parent()
    while n do
      if n:type() == 'block_mapping' then depth = depth + 1 end
      n = n:parent()
    end
    return depth
  end

  local lines    = {}
  local line_map = {}  -- outline line (1-indexed) → source line (1-indexed)

  for _, node in query:iter_captures(root, src_bufnr, 0, -1) do
    local depth = mapping_depth(node)
    if depth == 1 or depth == 2 then
      local row  = node:range()  -- 0-indexed
      local text = vim.treesitter.get_node_text(node, src_bufnr)
      table.insert(lines,    (depth == 2 and '  ' or '') .. text)
      table.insert(line_map, row + 1)
    end
  end

  if #lines == 0 then
    vim.notify('yaml_outline: no keys found', vim.log.levels.INFO)
    return
  end

  -- Open left vertical split (same side as TlistToggle)
  vim.cmd('topleft vertical 30 new')
  local out_win = vim.api.nvim_get_current_win()
  local out_buf = vim.api.nvim_get_current_buf()

  -- Buffer setup
  vim.bo.buftype   = 'nofile'
  vim.bo.bufhidden = 'wipe'
  vim.bo.swapfile  = false
  vim.bo.buflisted = false
  vim.bo.filetype  = 'yaml_outline'
  vim.api.nvim_buf_set_lines(out_buf, 0, -1, false, lines)
  vim.bo.modifiable = false

  -- Window setup
  vim.wo.number         = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn     = 'no'
  vim.wo.wrap           = false
  vim.wo.cursorline     = true
  vim.wo.winfixwidth    = true
  vim.wo.statusline     = ' YAML Outline'

  -- <CR>: jump to source line
  vim.keymap.set('n', '<CR>', function()
    local src_lnum = line_map[vim.api.nvim_win_get_cursor(0)[1]]
    if src_lnum and vim.api.nvim_win_is_valid(src_win) then
      vim.api.nvim_set_current_win(src_win)
      vim.api.nvim_win_set_cursor(src_win, { src_lnum, 0 })
    end
  end, { buffer = out_buf, silent = true })

  -- q / <C-e>: close
  for _, key in ipairs({ 'q', '<C-e>' }) do
    vim.keymap.set('n', key, function() close_outline(src_bufnr) end,
      { buffer = out_buf, silent = true })
  end

  -- Clean up state if window is closed by other means
  vim.api.nvim_create_autocmd('WinClosed', {
    pattern  = tostring(out_win),
    once     = true,
    callback = function() outline_state[src_bufnr] = nil end,
  })

  outline_state[src_bufnr] = { win = out_win, buf = out_buf }

  -- Place cursor on the entry at or just above the source cursor position
  local src_lnum = vim.api.nvim_win_get_cursor(src_win)[1]
  local best = 1
  for i, lnum in ipairs(line_map) do
    if lnum <= src_lnum then
      best = i
    else
      break
    end
  end
  vim.api.nvim_win_set_cursor(out_win, { best, 0 })
end

vim.keymap.set('n', '<C-e>', yaml_outline_toggle, { silent = true, buffer = true })
