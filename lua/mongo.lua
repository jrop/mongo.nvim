local M = {}

M._connection_string = "localhost:27017"

function mkquery(q, fmt)
  if fmt == nil then
    fmt = 'print(q)'
  elseif fmt == 'ejson' or fmt == 'json' then
    fmt = 'EJSON.stringify(q, null, 2)'
  end

  local s = [[
    // https://github.com/nodejs/node/issues/6456
    try {
      process.stdout._handle.setBlocking(true);
    } catch (_e) {}

    config.set('inspectDepth', Infinity);
    q = $q;
    if (typeof q.toArray === 'function') q = q.toArray();
    $fmt
  ]]
  s = s:gsub('$(%w+)', { q = q, fmt = fmt })
  return s
end

function string:_trim()
  return self:match( "^%s*(.-)%s*$" )
end

function M.get_dbs()
  if M._connection_string == nil then
    return {}
  end

  local dbs = vim.fn.system{
    "mongosh",
    M._connection_string,
    "--quiet",
    "--eval",
    [[JSON.stringify(db.adminCommand({ listDatabases: 1 }).databases.map(d => d.name))]]
  }
  dbs = vim.fn.json_decode(dbs)
  local dbs_filtered = {}
  for _, d in ipairs(dbs) do
    if d == 'admin' or d == 'config' or d == 'local' then
      -- ignore
    else
      table.insert(dbs_filtered, d)
    end
  end
  table.sort(dbs_filtered)
  return dbs_filtered
end

function M.get_collections()
  if M._connection_string == nil then
    return {}
  end

  local collections = vim.fn.system{
    "mongosh",
    M._connection_string,
    "--quiet",
    "--eval",
    "JSON.stringify(db.getCollectionNames())",
  }
  collections = vim.fn.json_decode(collections)
  table.sort(collections)
  return collections
end

function M.query(q, fmt)
  q = mkquery(q, fmt)
  local results = vim.fn.system{
    "mongosh",
    M._connection_string,
    "--quiet",
    "--eval",
    q,
  }
  return results:_trim()
end

function M.execute(q)
  local results = vim.fn.system{
    "mongosh",
    M._connection_string,
    "--quiet",
    "--eval",
    mkquery(q),
  }
  return results:_trim()
end

return M
