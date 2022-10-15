local kmap = vim.keymap.set
local ucmd = vim.api.nvim_create_user_command
local mongo = require'mongo'

function string:startswith(needle)-- {{{
  return self:sub(1, needle:len()) == needle
end-- }}}

function parse_args(args)-- {{{
  local parsed_args = {}
  local idx = 1
  for i, arg in ipairs(args) do
    if arg:startswith('--') then
      local equals_idx = arg:find('=')
      local key = ''
      local value = nil
      if equals_idx == nil then
        key = arg:sub(3)
      else
        key = arg:sub(3, equals_idx - 1)
        value = arg:sub(equals_idx + 1)
      end
      parsed_args[key] = value
    else
      parsed_args[idx] = arg
      idx = idx + 1
    end
  end
  return parsed_args
end-- }}}

-- "Connect" to a given Mongo instance (i.e., cache the connection info in a
-- global variable)
ucmd('Mongoconnect', function(args)-- {{{
  local parsed_args = parse_args(args.fargs)

  local db = parsed_args['db'] or parsed_args[1]
  local host = parsed_args['host'] or 'localhost:27017'

  if db ~= nil then
    mongo._connection_string = host .. '/' .. db
  else
    mongo._connection_string = host
  end
end, { nargs = '*' })-- }}}

-- Create a temp buffer that shows a list of Mongo collections in the DB we are
-- currently connected to, and setup a buffer-local keybind (<Enter>) that will
-- take the current line and create a sample query in a new temp-buffer
ucmd('Mongocollections', function()-- {{{
  local collections = mongo.get_collections()
  vim.cmd[[new]]
  require'mongo.utils'.set_tmp_buf_options()
  local buf = vim.api.nvim_win_get_buf(0)
  vim.api.nvim_buf_set_lines(buf, 0, 0, false, collections)
  vim.cmd[[normal! gg]]

  -- When <Enter> is pressed on one of the lines in the buffer that lists the
  -- collections, pre-populate a new buffer with stubbed query:
  kmap('n', '<CR>', function()
    local collection = vim.fn.getline('.')
    vim.cmd[[
      new
      set ft=typescript
    ]]
    require'mongo.utils'.set_tmp_buf_options()
    local buf = vim.api.nvim_win_get_buf(0)
    vim.api.nvim_buf_set_lines(buf, 0, 0, false, { 'db[' .. vim.fn.json_encode(collection) .. '].find({})' })
    vim.cmd[[normal! gg]]
  end, { buffer = true })
end, {})-- }}}

-- Execute a query against the current DB. If args are given to the command,
-- then use that as the query. If a visual range is given, then the selected
-- text is used as the query.
ucmd('Mongoquery', function(args)-- {{{
  local query
  if #args.args ~= 0 then
    query = args.args
  elseif args.range == 0 then
    -- no range given:
    query = require'mongo.utils'.buf_text()
  else
    -- range was specified:
    query = require'mongo.utils'.buf_vtext()
  end
  local response = mongo.query(query)
  vim.cmd[[
    new
    set ft=typescript
  ]]
  require'mongo.utils'.set_tmp_buf_options()
  local buf = vim.api.nvim_win_get_buf(0)
  vim.api.nvim_buf_set_lines(buf, 0, 0, false, vim.fn.split(response, '\n'))
  vim.cmd[[
    Prettier
    normal! gg
  ]]
end, { range = true, nargs = '*' })-- }}}

-- Shorthand for fetching a document by `--collection=... --id=...` (or
-- shorthand `--coll=... --id=...`) and code-generating a
-- `db.*.replaceOne(...)` query that can be used in conjunction with
-- `:Mongoexecute` for easy document-editing
ucmd('Mongoedit', function(args)-- {{{
  local parsed_args = parse_args(args.fargs)
  local collection = parsed_args['collection'] or parsed_args['coll']
  local id = parsed_args['id']
  local response = mongo.query('db[' .. vim.fn.json_encode(collection) .. '].findOne({ _id: ObjectId(' .. vim.fn.json_encode(id) .. ') })')
  vim.cmd[[
    new
    set ft=typescript
  ]]
  require'mongo.utils'.set_tmp_buf_options()
  local buf = vim.api.nvim_win_get_buf(0)
  local prefix = 'db[' .. vim.fn.json_encode(collection) .. '].replaceOne(\n{ _id: ObjectId(' .. vim.fn.json_encode(id) .. ') }'
  vim.api.nvim_buf_set_lines(buf, 0, 0, false, vim.fn.split(prefix .. ', \n' .. response .. '\n)', '\n'))
  vim.cmd[[
    Prettier
    normal! gg
  ]]
end, { nargs = '*' })-- }}}

-- Like `:Mongoquery`, but instead of displaying the returned output in a
-- temp-buffer, just print the result to Vim's messages
ucmd('Mongoexecute', function(args)-- {{{
  local query
  if #args.args ~= 0 then
    query = args.args
  elseif args.range == 0 then
    -- no range given:
    query = require'mongo.utils'.buf_text()
  else
    -- range was specified:
    query = require'mongo.utils'.buf_vtext()
  end
  local response = mongo.execute(query)
  print(response)
end, { range = true })-- }}}
