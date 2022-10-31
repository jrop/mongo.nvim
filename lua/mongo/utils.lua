M = {}

M._buf_data = {}

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

function M.set_buf_text(text, bufnr)
  if bufnr == nil then
    bufnr = vim.fn.bufnr('%')
  end

  if type(text) == 'string' then
    text = vim.fn.split(text, '\n')
  end

  vim.api.nvim_buf_set_lines(
    bufnr,
    0,
    vim.fn.line('$'),
    false,
    text
  )
end

function M.make_split(data)
  local num_lines = #vim.fn.split(require'mongo.utils'.buf_text(), '\n')
  local curr_height = vim.fn.winheight('%')

  local new_buf_height = curr_height - num_lines - 5
  if new_buf_height < 0 then
    -- just create a new split with no fuss:
    vim.cmd[[new]]
  else
    vim.cmd(new_buf_height ..'new')
  end

  local bufnr = vim.fn.bufnr('%')
  M._buf_data[bufnr] = data

  vim.api.nvim_create_autocmd(
    { "BufUnload" },
    {
      buffer = bufnr,
      callback = function ()
        local deleting = vim.fn.bufnr('%')
        if deleting ~= bufnr then
          return
        end
        M._buf_data[bufnr] = nil
      end
    }
  )
end

function M.buf_data(bufnr)
  if bufnr == nil then
    bufnr = vim.fn.bufnr('%')
  end
  return M._buf_data[bufnr]
end

return M
