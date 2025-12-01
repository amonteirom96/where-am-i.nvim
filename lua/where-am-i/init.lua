local M = {}

-- Cache simples opcional
local last_location = ""

-- Ícones
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
  EnumMember = " ",
  Struct = " ",
  Event = " ",
  Operator = "󰆕 ",
  TypeParameter = "󰊄 ",
}

-- Função interna que realmente monta o breadcrumb
local function resolve_breadcrumb(result)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

  local function find_symbol(symbols)
    for _, sym in ipairs(symbols) do
      local range = sym.range or (sym.location and sym.location.range)
      if range
          and cursor_line >= range.start.line + 1
          and cursor_line <= range["end"].line + 1
      then
        if sym.children then
          local child = find_symbol(sym.children)
          if child then
            local icon = icons[sym.kind and vim.lsp.protocol.SymbolKind[sym.kind]] or ""
            return icon .. sym.name .. " › " .. child
          end
        end
        local icon = icons[sym.kind and vim.lsp.protocol.SymbolKind[sym.kind]] or ""
        return icon .. sym.name
      end
    end
  end

  return find_symbol(result)
end


-----------------------------------------------------------------------
--  FUNÇÃO PRINCIPAL: retorna breadcrumb via callback
-----------------------------------------------------------------------
function M.get_location(cb)
  local clients = vim.lsp.get_active_clients({ bufnr = 0 })
  if #clients == 0 then
    cb(nil)
    return
  end

  local params = { textDocument = vim.lsp.util.make_text_document_params() }

  vim.lsp.buf_request(0, "textDocument/documentSymbol", params, function(err, result)
    if err or not result then
      cb(nil)
      return
    end

    local breadcrumb = resolve_breadcrumb(result)
    last_location = breadcrumb or ""
    cb(breadcrumb)
  end)
end


-----------------------------------------------------------------------
--  VERSÃO SINCRONA (usa cache da última resposta)
-----------------------------------------------------------------------
function M.get_location_sync()
  return last_location
end


-----------------------------------------------------------------------
-- Comando :WhereAmI
-----------------------------------------------------------------------
function M.setup()
  vim.api.nvim_create_user_command("WhereAmI", function()
    M.get_location(function(breadcrumb)
      if not breadcrumb then
        vim.api.nvim_echo({ { "Nenhum símbolo encontrado", "WarningMsg" } }, false, {})
      else
        vim.api.nvim_echo({ { breadcrumb, "Title" } }, false, {})
      end
    end)
  end, { desc = "Mostra a hierarquia LSP atual (breadcrumb)" })
end

return M
