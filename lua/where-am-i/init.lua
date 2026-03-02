local M = {}

function M.setup()
  vim.api.nvim_create_user_command("WhereAmI", function()
    local icons = {
      File = " ", Module = "󰏗 ", Namespace = "󰅩 ", Package = "󰏖 ",
      Class = "󰠱 ", Method = "󰡱 ", Property = "󰜢 ", Field = "󰽐 ",
      Constructor = " ", Enum = " ", Interface = " ", Function = "󰊕 ",
      Variable = "󰀫 ", Constant = "󰏿 ", String = "󰀬 ", Number = "󰎠 ",
      Boolean = "󰔯 ", Array = "󰅪 ", Object = "󰅩 ", Key = "󰌋 ",
      Null = "󰟢 ", EnumMember = " ", Struct = " ", Event = " ",
      Operator = "󰆕 ", TypeParameter = "󰊄 ",
    }

    -- Ícones para nós Treesitter
    local ts_icons = {
      for_statement       = "󰑖 ",
      for_in_statement    = "󰑖 ",
      while_statement     = "󰑖 ",
      repeat_statement    = "󰑖 ",
      if_statement        = " ",
      else_clause         = " ",
      elseif_clause       = " ",
      function_definition = "󰊕 ",
      method_definition   = "󰡱 ",
    }

    local cursor = vim.api.nvim_win_get_cursor(0)
    local cursor_row = cursor[1] - 1 -- Treesitter usa 0-indexed
    local cursor_col = cursor[2]

    -- 1. Busca contexto Treesitter (for, if, while, etc.)
    local ts_context = {}
    local ok, parser = pcall(vim.treesitter.get_parser, 0)
    if ok and parser then
      local tree = parser:parse()[1]
      local root = tree:root()

      local node = root:named_descendant_for_range(cursor_row, cursor_col, cursor_row, cursor_col)

      while node do
        local ntype = node:type()
        if ts_icons[ntype] then
          -- Tenta extrair um label útil do nó
          local label = ntype:gsub("_statement", ""):gsub("_", " ")

          -- Para funções/métodos, tenta pegar o nome
          if ntype == "function_definition" or ntype == "method_definition" then
            local name_node = node:field("name")[1]
            if name_node then
              label = vim.treesitter.get_node_text(name_node, 0)
            end
          end

          table.insert(ts_context, 1, ts_icons[ntype] .. label)
        end
        node = node:parent()
      end
    end

    -- 2. Busca contexto LSP (função, classe, método)
    local clients = vim.lsp.get_active_clients({ bufnr = 0 })
    if #clients == 0 and #ts_context == 0 then
      vim.api.nvim_echo({ { "Nenhum LSP ou Treesitter disponível!", "WarningMsg" } }, false, {})
      return
    end

    if #clients == 0 then
      vim.api.nvim_echo({ { table.concat(ts_context, " › "), "Title" } }, false, {})
      return
    end

    local params = { textDocument = vim.lsp.util.make_text_document_params() }
    local cursor_line = cursor[1]

    vim.lsp.buf_request(0, "textDocument/documentSymbol", params, function(err, result)
      if err or not result then
        if #ts_context > 0 then
          vim.api.nvim_echo({ { table.concat(ts_context, " › "), "Title" } }, false, {})
        else
          vim.api.nvim_echo({ { "Nenhum símbolo encontrado", "Comment" } }, false, {})
        end
        return
      end

      local function find_symbol(symbols)
        for _, sym in ipairs(symbols) do
          local range = sym.range or (sym.location and sym.location.range)
          if range and cursor_line >= range.start.line + 1 and cursor_line <= range["end"].line + 1 then
            local icon = icons[sym.kind and vim.lsp.protocol.SymbolKind[sym.kind]] or ""
            if sym.children then
              local child = find_symbol(sym.children)
              if child then
                return icon .. sym.name .. " › " .. child
              end
            end
            return icon .. sym.name
          end
        end
      end

      local lsp_context = find_symbol(result)

      -- 3. Combina LSP + Treesitter
      local parts = {}
      if lsp_context then
        table.insert(parts, lsp_context)
      end
      -- Filtra nós TS que são funções (já cobertas pelo LSP)
      for _, ctx in ipairs(ts_context) do
        if not ctx:match("^󰊕") and not ctx:match("^󰡱") then
          table.insert(parts, ctx)
        end
      end

      if #parts > 0 then
        vim.api.nvim_echo({ { table.concat(parts, " › "), "Title" } }, false, {})
      else
        vim.api.nvim_echo({ { "Nenhum símbolo encontrado", "Comment" } }, false, {})
      end
    end)
  end, { desc = "Mostra a hierarquia LSP+Treesitter atual (breadcrumb)" })
end

return M
