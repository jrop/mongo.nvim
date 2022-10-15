M = {}

function M.buf_text()
  local bufnr = vim.api.nvim_win_get_buf(0)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, vim.api.nvim_buf_line_count(bufnr), true)
  local text = ''
  for i, line in ipairs(lines) do
    text = text .. line .. '\n'
  end
  return text
end

function M.buf_vtext()
  local a_orig = vim.fn.getreg('a')
  local mode = vim.fn.mode()
  if mode ~= 'v' and mode ~= 'V' then
    vim.cmd[[normal! gv]]
  end
  vim.cmd[[normal! "aygv]]
  local text = vim.fn.getreg('a')
  vim.fn.setreg('a', a_orig)
  return text
end

function M.set_tmp_buf_options()
  vim.opt_local.bufhidden = 'delete'
  vim.opt_local.writebackup = false
  vim.opt_local.buflisted = false
  vim.opt_local.buftype = 'nowrite'
  vim.opt_local.updatetime = 300
end

return M
