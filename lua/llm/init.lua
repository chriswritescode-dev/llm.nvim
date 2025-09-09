local completion = require("llm.completion")
local config = require("llm.config")
local keymaps = require("llm.keymaps")
local llm_ls = require("llm.language_server")

local M = { setup_done = false }

local function create_cmds()
  vim.api.nvim_create_user_command("LLMToggleAutoSuggest", function()
    completion.toggle_suggestion()
  end, {})

  vim.api.nvim_create_user_command("LLMSuggestion", function()
    completion.lsp_suggest()
  end, {})
  
  vim.api.nvim_create_user_command("LLMStop", function()
    llm_ls.stop()
    vim.notify("[LLM] Language server stopped", vim.log.levels.INFO)
  end, {})
  
  vim.api.nvim_create_user_command("LLMRestart", function()
    llm_ls.stop()
    vim.defer_fn(function()
      llm_ls.setup()
      vim.notify("[LLM] Language server restarted", vim.log.levels.INFO)
    end, 500)
  end, {})
  
  vim.api.nvim_create_user_command("LLMDebug", function()
    local client = vim.lsp.get_client_by_id(llm_ls.client_id)
    if client then
      local pid = client.rpc and client.rpc.pid or "unknown"
      vim.notify(string.format("[LLM] Client active, PID: %s", tostring(pid)), vim.log.levels.INFO)
    else
      vim.notify("[LLM] No active client", vim.log.levels.INFO)
    end
    
    -- Check for any llm-ls processes
    local ps_output = vim.fn.system("ps aux | grep llm-ls | grep -v grep")
    if ps_output ~= "" then
      vim.notify("[LLM] Running llm-ls processes:\n" .. ps_output, vim.log.levels.INFO)
    end
  end, {})
end

function M.setup(opts)
  if M.setup_done then
    return
  end

  create_cmds()

  config.setup(opts)

  llm_ls.setup()

  completion.setup(config.get().enable_suggestions_on_startup)
  completion.create_autocmds()

  keymaps.setup()

  M.setup_done = true
end

return M
