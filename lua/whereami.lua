local M = {}

-- Cria o comando quando o módulo for carregado
vim.api.nvim_create_user_command("WhereAmI", function()
  local params = { textDocument = vim.lsp.util.make_text_document_params() }

  local icons = {
    File = " ",
    Module = "󰏗 ",
    Namespace = "󰅩 ",
    Package = "󰏖 ",
    Class = "󰠱 ",
    Method = "󰡱 ",
    Property = "󰜢 ",
    Field = "󰽐 ",
    Constructor = " ",
    Enum = " ",
    Interface = " ",
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
    EnumMember = " ",
    Struct = " ",
    Event = " ",
    Operator = "󰆕 ",
    TypeParameter = "󰊄 ",
  }

  vim.lsp.buf_request(0, "textDocument/documentSymbol", params, function(err, result)
    if err or not result then return end

    local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

    local function find_symbol(symbols)
      for _, sym in ipairs(symbols) do
        local range = sym.range or (sym.location and sym.location.range)
        if range and cursor_line >= range.start.line + 1 and cursor_line <= range["end"].line + 1 then
          if sym.children then
            local child = find_symbol(sym.children)
            if child then
              local icon = icons[sym.kind and vim.lsp.protocol.SymbolKind[sym.kind]] or ""
              return (icon .. sym.name .. " › " .. child)
            end
          end
          local icon = icons[sym.kind and vim.lsp.protocol.SymbolKind[sym.kind]] or ""
          return (icon .. sym.name)
        end
      end
    end

    local current = find_symbol(result)
    if current then
      vim.api.nvim_echo({ { current, "Title" } }, false, {})
    else
      vim.api.nvim_echo({ { "Nenhum símbolo encontrado", "Comment" } }, false, {})
    end
  end)
end, {})

return M
