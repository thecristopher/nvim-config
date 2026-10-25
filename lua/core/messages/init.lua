-- Player messages on the ground of your code: pick a template, fill the blank, and the note
-- glows at the end of that line for every future visit. Stored per repo, extmarks keep each
-- message on its line while you edit and the new positions are saved on write.
local actions = require("core.messages.actions")

local M = {}

local ns = vim.api.nvim_create_namespace("eldentree_messages")
local store_file = vim.fn.stdpath("state") .. "/eldentree_messages.json"
-- extmark id to message text, per buffer
local marks = {}

local function read_store()
  local ok, lines = pcall(vim.fn.readfile, store_file)
  if not ok then return {} end
  local decoded_ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  return (decoded_ok and type(decoded) == "table") and decoded or {}
end

local function write_store(store)
  pcall(vim.fn.writefile, { vim.json.encode(store) }, store_file)
end

local function define_highlights()
  local p = require("core.themes").palette()
  vim.api.nvim_set_hl(0, "EldenMessage", { fg = p.peach, italic = true })
end

-- the repo and the file's path inside it, or nil for buffers that are not repo files
local function locate(buf)
  if vim.bo[buf].buftype ~= "" then return nil end
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then return nil end
  local repo = vim.fs.root(buf, ".git")
  if not repo then return nil end
  repo = vim.fs.normalize(repo)
  local file = actions.relative(repo, vim.fs.normalize(name))
  if not file then return nil end
  return repo, file
end

function M.render(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  marks[buf] = {}
  local repo, file = locate(buf)
  if not repo then return end

  local line_count = vim.api.nvim_buf_line_count(buf)
  for _, message in ipairs(actions.for_file(read_store(), repo, file)) do
    if message.line <= line_count then
      local id = vim.api.nvim_buf_set_extmark(buf, ns, message.line - 1, 0, {
        virt_text = { { "  ✎ " .. message.text, "EldenMessage" } },
        virt_text_pos = "eol",
        hl_mode = "combine",
      })
      marks[buf][id] = message.text
    end
  end
end

-- where the messages sit right now, after any edits moved them around
local function current_positions(buf)
  local messages = {}
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {})) do
    local text = (marks[buf] or {})[mark[1]]
    if text then table.insert(messages, { line = mark[2] + 1, text = text }) end
  end
  return messages
end

local function save_positions(buf)
  local repo, file = locate(buf)
  if not repo or not marks[buf] then return end
  write_store(actions.replace(read_store(), repo, file, current_positions(buf)))
end

local function write_message(buf, line, text)
  local repo, file = locate(buf)
  local store = actions.replace(read_store(), repo, file, current_positions(buf))
  write_store(actions.put(store, repo, file, line, text))
  M.render(buf)
end

--- Asks for a template and a word, then writes the message on the cursor line.
function M.write()
  local buf = vim.api.nvim_get_current_buf()
  if not locate(buf) then
    vim.notify("Messages can only be left on files inside a repo", vim.log.levels.WARN, { title = "Eldentree" })
    return
  end
  local line = vim.api.nvim_win_get_cursor(0)[1]

  vim.ui.select(actions.templates(), {
    prompt = "Choose a template",
    format_item = function(template) return template:format("****") end,
  }, function(template)
    if not template then return end
    vim.ui.input({ prompt = "Fill the blank: " }, function(word)
      local text = actions.compose(template, word)
      if text then write_message(buf, line, text) end
    end)
  end)
end

--- Erases the message on the cursor line.
function M.erase()
  local buf = vim.api.nvim_get_current_buf()
  local repo, file = locate(buf)
  if not repo then return end
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local store, erased = actions.erase(actions.replace(read_store(), repo, file, current_positions(buf)), repo, file, line)
  if not erased then
    vim.notify("No message on this line", vim.log.levels.INFO, { title = "Eldentree" })
    return
  end
  write_store(store)
  M.render(buf)
end

--- Lists every message in the current repo and jumps to the one you pick.
function M.pick()
  local repo = vim.fs.root(0, ".git") or vim.uv.cwd()
  repo = vim.fs.normalize(repo)
  local items = {}
  for index, entry in ipairs(actions.list(read_store(), repo)) do
    table.insert(items, {
      idx = index,
      text = entry.text .. " " .. entry.file,
      file = repo .. "/" .. entry.file,
      pos = { entry.line, 0 },
      message = entry.text,
      where = ("%s:%d"):format(entry.file, entry.line),
    })
  end
  if #items == 0 then
    vim.notify("No messages left in this repo yet", vim.log.levels.INFO, { title = "Eldentree" })
    return
  end

  Snacks.picker({
    title = "Messages",
    items = items,
    format = function(item)
      return {
        { "✎ ", "EldenMessage" },
        { item.message, "SnacksPickerFile" },
        { "  " .. item.where, "SnacksPickerDir" },
      }
    end,
  })
end

function M.setup()
  define_highlights()
  local group = vim.api.nvim_create_augroup("eldentree_messages", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = define_highlights })
  vim.api.nvim_create_autocmd("BufReadPost", { group = group, callback = function(ev) M.render(ev.buf) end })
  vim.api.nvim_create_autocmd("BufWritePost", { group = group, callback = function(ev) save_positions(ev.buf) end })
  vim.api.nvim_create_autocmd("BufWipeout", { group = group, callback = function(ev) marks[ev.buf] = nil end })

  vim.api.nvim_create_user_command("Inscribe", M.write, { desc = "Leave a message on this line" })
  vim.api.nvim_create_user_command("Inscriptions", M.pick, { desc = "List the messages in this repo" })
end

return M
