local M = {}

M._connection_string = "localhost:27017"

function string:_trim()
   return self:match( "^%s*(.-)%s*$" )
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

function M.query(q)
  local results = vim.fn.system{
    "mongosh",
    M._connection_string,
    "--quiet",
    "--eval",
    'printjson(' .. q .. ')',
  }
  return results:_trim()
end

function M.execute(q)
  local results = vim.fn.system{
    "mongosh",
    M._connection_string,
    "--quiet",
    "--eval",
    q,
  }
  return results:_trim()
end

return M
