local M = {}

local last_location = ""
local last_line = -1
local debounce_timer = nil

local icons = {
  File = " ",
  Module = "󰏗 ",
  Namespace = "󰅩 ",
  Package = "󰏖 ",
  Class = "󰠱 ",
  Method = "󰡱 ",
  Property = "󰜢 ",
  Field = "󰽐 ",
  Constructor = " ",
  Enum = " ",
  Interface = " ",
  Function = "󰊕 ",
  Variable = "󰀫 ",
  Constant = "󰏿 ",
  String = "󰀬 ",
  Number = "󰎠 ",
  Boolean = "󰔯 ",
  Array = "󰅪 ",
  Object = "󰅩 ",
  Key = "󰌋 ",
  Null = "󰟢 ",
  Operator = "󰆕 ",
  TypeParameter = "󰊄 ",
}

-- ----------------------------------------------------------------------
-- Resolve símbolo
-- ----------------------------------------------------------------------
local function resolve_breadcrumb(result, cursor_line)
  local function find_symbol(list)
    for _, sym in ipairs(list) do
      local range = sym.range or (sym.location and sym.location.range)
      if range then
        if cursor_line >= range.start.line + 1
            and cursor_line <= range["end"].line + 1
        then
          if sym.children then
            local child = find_symbol(sym.children)
            if child then
              local icon = icons[vim.lsp.protocol.SymbolKind[sym.kind]] or ""
              return icon .. sym.name .. " › " .. child
            end
          end

          local icon = icons[vim.lsp.protocol.SymbolKind[sym.kind]] or ""
          return icon .. sym.name
        end
      end
    end
  end

  return find_symbol(result)
end

-- ----------------------------------------------------------------------
-- Busca LSP (assíncrono)
-- ----------------------------------------------------------------------
local function fetch_location()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

  if cursor_line == last_line then
    return
  end
  last_line = cursor_line

  local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
  if #clients == 0 then
    last_location = ""
    return
  end

  local params = { textDocument = vim.lsp.util.make_text_document_params() }

  vim.lsp.buf_request(bufnr, "textDocument/documentSymbol", params, function(err, result)
    if err or not result then
      last_location = ""
      return
    end

    last_location = resolve_breadcrumb(result, cursor_line) or ""
  end)
end

-- ----------------------------------------------------------------------
-- API pública
-- ----------------------------------------------------------------------

function M.update()
  if debounce_timer then
    vim.fn.timer_stop(debounce_timer)
  end
  debounce_timer = vim.fn.timer_start(100, fetch_location)
end

function M.get_location_sync()
  return last_location
end

function M.setup()
  vim.api.nvim_create_user_command("WhereAmI", function()
    M.update()
    vim.defer_fn(function()
      vim.notify(last_location ~= "" and last_location or "Nenhum símbolo encontrado")
    end, 150)
  end, {})
end

return M
