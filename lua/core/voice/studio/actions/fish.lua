-- Pure Fish Audio plumbing: the curl commands the studio runs and what their answers mean.
local M = {}

M.TTS_URL = "https://api.fish.audio/v1/tts"
M.WALLET_URL = "https://api.fish.audio/wallet/self/api-credit"
-- notifications are short and mono, so half the default bitrate halves the cache with no loss heard
M.BITRATE = 64
-- smaller than this is an error page, not a take
M.MIN_AUDIO_BYTES = 2000
M.TIMEOUT_S = 30

---The JSON body that asks Fish Audio to voice a take.
---@param text string the take, already rewritten for its model
---@param voice string the Fish Audio voice id
---@return string
function M.body(text, voice)
  return vim.json.encode({
    text = text,
    reference_id = voice,
    format = "mp3",
    mp3_bitrate = M.BITRATE,
    latency = "balanced",
  })
end

---The curl command that voices a take into a file and prints only the HTTP status. The body goes
---on stdin.
---@param key string the API key
---@param model string
---@param out string where the audio lands
---@return string[]
function M.tts_command(key, model, out)
  return {
    "curl",
    "-sS",
    "--max-time",
    tostring(M.TIMEOUT_S),
    "-o",
    out,
    "-w",
    "%{http_code}",
    "-H",
    "Authorization: Bearer " .. key,
    "-H",
    "Content-Type: application/json",
    "-H",
    "model: " .. model,
    "--data-binary",
    "@-",
    M.TTS_URL,
  }
end

---The curl command that reads the prepaid balance.
---@param key string
---@return string[]
function M.wallet_command(key)
  return { "curl", "-sS", "--max-time", "10", "-H", "Authorization: Bearer " .. key, M.WALLET_URL }
end

---What a voicing answer means: ok, broke when the account has no credit left for the model, failed
---for anything else.
---@param code integer curl's exit code
---@param status string the HTTP status curl printed
---@param size integer bytes of the file it wrote
---@return "ok"|"broke"|"failed"
function M.outcome(code, status, size)
  if code ~= 0 then
    return "failed"
  end
  if status == "402" then
    return "broke"
  end
  if status == "200" and size >= M.MIN_AUDIO_BYTES then
    return "ok"
  end
  return "failed"
end

---The prepaid balance in a wallet answer, nil when it has none.
---@param text string|nil the answer's body
---@return number|nil dollars
function M.balance(text)
  local ok, data = pcall(vim.json.decode, text or "")
  return ok and type(data) == "table" and tonumber(data.credit) or nil
end

return M
