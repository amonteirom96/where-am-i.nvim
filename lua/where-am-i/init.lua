local M = {}
function M.setup()
  vim.api.nvim_create_user_command("WhereAmI", function()
    print("Comando WhereAmI executado!")
    
    -- Verificar se há clientes LSP ativos
    local clients = vim.lsp.get_active_clients({ bufnr = 0 })
    if #clients == 0 then
      vim.api.nvim_echo({ { "Nenhum LSP ativo neste buffer!", "WarningMsg" } }, false, {})
      return
    end
    print("LSP ativo, clientes:", vim.inspect(vim.tbl_map(function(c) return c.name end, clients)))
    
    local params = { textDocument = vim.lsp.util.make_text_document_params() }
  
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
  
    print("Requisitando símbolos...")
    vim.lsp.buf_request(0, "textDocument/documentSymbol", params, function(err, result)
      print("Resposta LSP recebida!")
      
      if err then
        print("Erro LSP:", vim.inspect(err))
        return
      end
      
      if not result then
        vim.api.nvim_echo({ { "LSP não retornou símbolos", "WarningMsg" } }, false, {})
        return
      end
      
      print("Símbolos recebidos:", #result)
  
      local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
      print("Linha do cursor:", cursor_line)
  
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
        print("Símbolo encontrado:", current)
        vim.api.nvim_echo({ { current, "Title" } }, false, {})
      else
        print("Nenhum símbolo encontrado na linha", cursor_line)
        vim.api.nvim_echo({ { "Nenhum símbolo encontrado", "Comment" } }, false, {})
      end
    end)
  end, { desc = "Mostra a hierarquia LSP atual (breadcrumb)" })
end
return M
