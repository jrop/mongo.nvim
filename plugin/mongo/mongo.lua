local kmap = vim.keymap.set
local ucmd = vim.api.nvim_create_user_command
local mongo = require'mongo'
local mongo_utils = require'mongo.utils'
local mongo_query = require'mongo.query'

function string:_startswith(needle)-- {{{
  return self:sub(1, needle:len()) == needle
end-- }}}

function string:_indent(n)-- {{{
  local indent = ''
  for _ = 1,n do
    indent = indent .. ' '
  end

  local lines = vim.fn.split(self, '\n')
  for i, _ in ipairs(lines) do
    lines[i] = indent .. lines[i]
  end
  return vim.fn.join(lines, '\n')
end-- }}}

function parse_args(args)-- {{{
  local parsed_args = {}
  local idx = 1
  for i, arg in ipairs(args) do
    if arg:_startswith('--') then
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

  local function next(db) 
    if db ~= nil then
      mongo._connection_string = host .. '/' .. db
    else
      mongo._connection_string = host
    end
  end

  local available_dbs = require'mongo'.get_dbs(host)
  if #available_dbs == 1 and db == nil then
    db = available_dbs[1]
  elseif db == nil then
    db = vim.ui.select(
      available_dbs,
      { prompt = 'Select a DB' },
      function(db)
        next(db)
      end
    )
  else
    next(db)
  end
end, { nargs = '*' })-- }}}

-- Create a temp buffer that shows a list of Mongo collections in the DB we are
-- currently connected to, and setup a buffer-local keybind (<Enter>) that will
-- take the current line and create a sample query in a new temp-buffer
ucmd('Mongocollections', function()-- {{{
  local function refresh()
    local collections = mongo.get_collections()
    mongo_utils.set_buf_text(vim.fn.join(collections, '\n'))
    vim.cmd[[normal! gg]]
  end
  mongo_utils.make_split({ refresh = refresh })
  mongo_utils.set_tmp_buf_options()
  refresh()

  -- When <Enter> is pressed on one of the lines in the buffer that lists the
  -- collections, pre-populate a new buffer with stubbed query:
  kmap('n', '<CR>', function()
    local collection = vim.fn.getline('.')
    mongo_utils.make_split()
    vim.cmd[[set ft=typescript]]
    mongo_utils.set_tmp_buf_options()
    mongo_utils.set_buf_text('db[' .. vim.fn.json_encode(collection) .. '].find({})')
    vim.cmd[[normal! gg]]
  end, { buffer = true })
end, {})-- }}}

-- Execute a query against the current DB. If args are given to the command,
-- then use that as the query. If a visual range is given, then the selected
-- text is used as the query.
ucmd('Mongoquery', function(args)-- {{{
  local parsed_args = parse_args(args.fargs);
  local query
  if #parsed_args ~= 0 then
    query = parsed_args[1]
  elseif args.range == 0 then
    -- no range given:
    query = mongo_utils.buf_text()
  else
    -- range was specified:
    query = mongo_utils.buf_vtext()
  end

  local function refresh()
    local response = mongo.query(query, parsed_args.fmt)
    if parsed_args.fmt ~= 'json' then
      response = '('.. response ..')'
      vim.cmd('set filetype=typescript')
    else
      vim.cmd('set filetype=json')
    end
    mongo_utils.set_buf_text(vim.fn.split(response, '\n'))
    vim.cmd[[normal! gg]]
  end
  mongo_utils.make_split({
    refresh = refresh,
    collection = mongo_query.get_collection_name(query),
  })
  local buf = vim.api.nvim_win_get_buf(0)
  mongo_utils.set_tmp_buf_options()
  refresh()
end, { range = true, nargs = '*' })-- }}}

-- Shorthand for fetching a document by `--collection=... --id=...` (or
-- shorthand `--coll=... --id=...`) and code-generating a
-- `db.*.replaceOne(...)` query that can be used in conjunction with
-- `:Mongoexecute` for easy document-editing
ucmd('Mongoedit', function(args)-- {{{
  local parsed_args = parse_args(args.fargs)
  local collection = parsed_args['collection'] or parsed_args['coll'] or mongo_utils.buf_data()['collection']
  local id = parsed_args['id'] or mongo_query.find_nearest_id()
  if collection == nil then
    print('Mongoedit: collection required')
    return
  end
  if id == nil then
    print('Mongoedit: id required')
    return
  end

  print('Editing '.. collection ..':'.. id)
  local function refresh()
    local response = mongo.query('db[' .. vim.fn.json_encode(collection) .. '].findOne({ _id: ' .. vim.fn.json_encode(id) .. ' })', parsed_args.fmt)
    local prefix = 'db[' .. vim.fn.json_encode(collection) .. '].replaceOne(\n  { _id: ' .. vim.fn.json_encode(id) .. ' }'
    mongo_utils.set_buf_text(vim.fn.split(prefix .. ',\n' .. response:_indent(2) .. '\n)', '\n'))
    vim.cmd[[normal! gg]]
  end
  mongo_utils.make_split({ refresh = refresh })
  vim.cmd[[set ft=typescript]]
  mongo_utils.set_tmp_buf_options()
  local buf = vim.api.nvim_win_get_buf(0)
  refresh()
end, { nargs = '*' })-- }}}

-- Like `:Mongoquery`, but instead of displaying the returned output in a
-- temp-buffer, just print the result to Vim's messages
ucmd('Mongoexecute', function(args)-- {{{
  local query
  if #args.args ~= 0 then
    query = args.args
  elseif args.range == 0 then
    -- no range given:
    query = mongo_utils.buf_text()
  else
    -- range was specified:
    query = mongo_utils.buf_vtext()
  end
  local response = mongo.execute(query)
  print(response)
end, { range = true })-- }}}

-- Refreshes the data in the current buffer
ucmd('Mongorefresh', function()-- {{{
  local data = mongo_utils.buf_data()
  if
    data == nil
    or data['refresh'] == nil
    or type(data['refresh']) ~= 'function'
  then
    return
  end
  data['refresh']()
end, {})-- }}}
