local ts = vim.treesitter

local M = {}

function caps_to_table(query, captures)
  local tab = {}
  for id, cap in ipairs(captures) do
    local name = query.captures[id]
    tab[name] = cap
  end
  return tab
end

function M.get_collection_name(src)
  local parser = ts.get_string_parser(src, "typescript")
  local tree = parser:parse()[1]
  local query = ts.query.parse('typescript', [[
  (call_expression
    function: (member_expression
      object: ((_) @mbr (#match? @mbr "^db(\\[|\\.)"))
      ; property: (_) @fn
    )
  ) @call
  ]])


  local result = nil

  for _, captures in query:iter_matches(tree:root(), src) do
    local tab = caps_to_table(query, captures)
    if result ~= nil then
      -- oops, we already found a result, meaning the given src has
      -- multiple matches, which we don't support
      return nil
    end

    local txt = ts.get_node_text(tab["mbr"], src)

    if string.sub(txt, 1, 3) == "db[" then
      txt = string.sub(txt, 5) -- trim leading 'db[' (and quote)
      txt = string.sub(txt, 1, #txt - 2) -- trim trailing '"]' or "']"
    elseif string.sub(txt, 1, 3) == "db." then
      txt = string.sub(txt, 4) -- trim leading 'db.'
    end

    result = txt
  end

  return result
end

function M.find_nearest_id(bufid)
  if bufid == nil then
    bufid = vim.fn.bufnr('%')
  end

  local parser = ts.get_parser(bufid)
  local tree = parser:parse()[1]

  local query = ts.query.parse('json', [[
    (object
     (pair
       key: (string (string_content) @id (#eq? @id "_id"))
       value: (_) @id_value
     )
    ) @obj
  ]])

  local pos = vim.fn.getpos('.')
  local line = pos[2] - 1
  local col = pos[3] - 1

  for _, captures in query:iter_matches(tree:root(), bufid) do
    local tab = caps_to_table(query, captures)
    if ts.is_in_node_range(tab["obj"], line, col) then
      local node_text = ts.get_node_text(tab["id_value"], bufid)
      -- node_text could be a JSON object, so let's remove newlines:
      node_text = vim.fn.json_encode(vim.fn.json_decode(node_text))
      return node_text
    end
  end
end

return M
