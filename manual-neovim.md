# Manual do Neovim

> Guia prático da instalação atual.  
> **Versão:** Neovim v0.12.4 (LuaJIT) — config em `~/.config/nvim`.  
> Filosofia: **zero plugins**, usando apenas recursos nativos do Neovim 0.11+.

---

## Visão geral da configuração

A configuração está em `~/.config/nvim/` e é carregada por `init.lua`:

```
~/.config/nvim/
├── init.lua
├── lsp/
│   ├── lua_ls.lua
│   └── tsgo.lua
└── lua/
    ├── autocommands.lua
    ├── colorscheme.lua
    ├── diagnostics.lua
    ├── find.lua
    ├── formatting.lua
    ├── grep.lua
    ├── keymaps.lua
    ├── lsp.lua
    ├── netrw.lua
    ├── options.lua
    └── statusline.lua
```

Pacote adicional: `catppuccin.nvim` instalado manualmente em `pack/colors/start/`.

---

## Comandos de inicialização

```bash
nvim arquivo.lua            # Abre arquivo
nvim .                      # Abre diretório com netrw
nvim +"Lexplore"            # Abre com explorador lateral
```

---

## Opções principais (`lua/options.lua`)

| Opção              | Valor    | Significado                          |
| ------------------ | -------- | ------------------------------------ |
| `number`           | `true`   | Número absoluto da linha             |
| `relativenumber`   | `true`   | Números relativos para saltos fáceis |
| `tabstop`          | `2`      | Tab = 2 espaços                      |
| `softtabstop`      | `2`      | Backspace/remove como 2 espaços      |
| `signcolumn`       | `"yes"`  | Coluna de sinais sempre visível      |
| `undofile`         | `true`   | Undo persistente entre sessões       |
| `autoread`         | `true`   | Recarrega arquivo se mudado fora     |
| `laststatus`       | `3`      | Uma única statusline global          |
| `cmdheight`        | `0`      | Esconde a linha de comando quando vazia |

---

## Tema e aparência (`lua/colorscheme.lua`)

```lua
vim.cmd.colorscheme("catppuccin")
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
```

- Tema principal: **Catppuccin**.
- Fundo transparente (`bg = "none"`), respeitando o fundo do terminal.

---

## Mapas de teclas (`lua/keymaps.lua`)

Leader (`<leader>`) configurado como **espaço**.

### Gerais

| Atalho        | Ação                            |
| ------------- | ------------------------------- |
| `<leader> w`  | Salvar (`:w`)                   |
| `<leader> q`  | Sair (`:q`)                     |
| `U`           | Refazer (`Ctrl+r`)              |

### Movimento entre janelas

| Atalho     | Ação                           |
| ---------- | ------------------------------ |
| `Ctrl+h`   | Ir para janela à esquerda      |
| `Ctrl+j`   | Ir para janela abaixo          |
| `Ctrl+k`   | Ir para janela acima           |
| `Ctrl+l`   | Ir para janela à direita       |

---

## Explorador de arquivos: netrw (`lua/netrw.lua`)

Abre com:

```text
<leader> e
```

Configurações:

- Modo **árvore** (`liststyle = 3`)
- Banner oculto
- Largura fixa de 25%
- Abre arquivos na janela anterior
- `%` dentro do netrw cria arquivo/pasta na janela anterior

### Dentro do netrw

| Tecla     | Ação                                              |
| --------- | ------------------------------------------------- |
| `<leader>e` | Abrir/fechar explorador lateral (`Lexplore`)    |
| `%`       | Criar novo arquivo/pasta (pergunta nome)          |
| Enter     | Abrir arquivo/pasta                               |
| `d`       | Criar diretório (padrão netrw)                    |
| `D`       | Apagar arquivo/pasta (padrão netrw)               |
| `r`       | Renomear (padrão netrw)                           |
| `R`       | Atualizar listagem (padrão netrw)                 |

> A tecla `%` foi redefinida para criar arquivos na **janela anterior**, respeitando `netrw_browse_split = 0`.

---

## Busca fuzzy de arquivos (`lua/find.lua`)

```text
<leader> f
```

- Usa `findfunc` nativo do Neovim.
- Lista todos os arquivos recursivamente.
- Ignora: `node_modules`, `.git`, `.cache`, `dist`, `build`, `.tmp`, `.log`.
- Filtro com `matchfuzzy()`.

**Uso:**

1. Pressione `<leader> f`.
2. Digite parte do nome do arquivo.
3. Use `<Tab>` / `<C-n>` / `<C-p>` para navegar candidatos.
4. Pressione `<Enter>` para abrir.

---

## Busca em texto: live grep (`lua/grep.lua`)

```text
<leader> g
```

- Usa `ripgrep` (`rg --vimgrep --smart-case --hidden`).
- Pede o padrão, executa `:grep!` e abre a quickfix list (`:copen`).

**Uso:**

1. Pressione `<leader> g`.
2. Digite o termo de busca.
3. Resultados aparecem na quickfix list.
4. Navegue com `:cn` (próximo) e `:cp` (anterior), ou `Enter` para ir ao arquivo.

---

## LSP nativo (`lua/lsp.lua`)

```lua
vim.lsp.enable({ "lua_ls", "tsgo" })
```

Servidores ativados:

- **lua_ls** — Lua Language Server
- **tsgo** — TypeScript Go (novo LSP rápido da Microsoft)

Recursos habilitados automaticamente ao anexar um LSP:

- Autocomplete nativo (`vim.lsp.completion.enable`) com `autotrigger = true`
- Diagnósticos com texto virtual
- `completeopt+=noselect`

### Atalhos LSP (padrão do Neovim)

| Atalho         | Ação                                   |
| -------------- | -------------------------------------- |
| `gd`           | Ir para definição                      |
| `gD`           | Ir para declaração                     |
| `grn`          | Renomear símbolo                       |
| `grr`          | Referências (abre quickfix)            |
| `gra`          | Ações de código (modo normal/visual)   |
| `K`            | Hover / documentação                   |
| `Ctrl+]`       | Ir para definição (tags fallback)      |
| `Ctrl+x Ctrl+o`| Complete com LSP (omni completion)     |

Autocomplete aparece automaticamente ao digitar. Use `<C-n>` / `<C-p>` para navegar e `<C-y>` para confirmar.

---

## Diagnósticos (`lua/diagnostics.lua`)

```text
<leader> d
```

- Abre todos os diagnósticos do buffer na quickfix list.
- Texto virtual habilitado (`virtual_text = true`).

Sinais padrão do Neovim:

| Ícone | Severidade |
| ----- | ---------- |
|      | Erro       |
|      | Aviso      |
|      | Informação |
|      | Dica       |

---

## Formatação (`lua/formatting.lua`)

Formata ao salvar (`BufWritePre`).

Formatadores externos configurados:

| Filetype         | Comando                          |
| ---------------- | -------------------------------- |
| `lua`            | `stylua -`                       |
| `javascript`     | `prettier --stdin-filepath %`    |
| `typescript`     | `prettier --stdin-filepath %`    |
| `typescriptreact`| `prettier --stdin-filepath %`    |
| `json`           | `prettier --stdin-filepath %`    |

Se não houver formatador externo para o filetype, tenta formatar via LSP (`textDocument/formatting`).

> Requer `stylua` e `prettier` instalados no PATH.

---

## Statusline customizada (`lua/statusline.lua`)

Mostra, da esquerda para direita:

1. Modo atual (NORMAL, INSERT, VISUAL, etc.)
2. Branch Git (se dentro de repositório)
3. Caminho relativo ao repositório Git
4. Diagnósticos (erros, avisos, infos, dicas)
5. Filetype
6. Linha:coluna

---

## Autocomandos (`lua/autocommands.lua`)

| Evento              | Ação                                              |
| ------------------- | ------------------------------------------------- |
| `TextYankPost`      | Destaca seleção copiada por 200ms                 |
| `BufReadPost`       | Restaura cursor na última posição do arquivo      |
| `LspAttach`         | Liga autocomplete nativo para o cliente LSP       |
| `BufEnter`          | Recalcula branch Git e caminho relativo           |
| `DiagnosticChanged` | Redesenha statusline quando diagnósticos mudam    |
| `BufWritePre`       | Formata arquivo antes de salvar                   |

---

## Como editar a configuração

Edite qualquer arquivo em `~/.config/nvim/lua/` e recarregue:

```vim
:source %
```

ou reinicie o Neovim.

### Exemplos de personalizações comuns

#### Adicionar um novo mapa

```lua
-- em lua/keymaps.lua
vim.keymap.set("n", "<leader>x", ":!chmod +x %<CR>", { silent = true })
```

#### Mudar opções

```lua
-- em lua/options.lua
vim.o.wrap = true
vim.o.cursorline = true
```

#### Adicionar outro LSP

1. Crie `~/.config/nvim/lsp/meu_lsp.lua`:

```lua
return {
  cmd = { "meu-lsp", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", ".git" },
}
```

2. Adicione em `lua/lsp.lua`:

```lua
vim.lsp.enable({ "lua_ls", "tsgo", "meu_lsp" })
```

#### Adicionar um formatador

```lua
-- em lua/formatting.lua
M.formatters.python = "black -"
```

---

## Dicas práticas

1. **Comece com `<leader> e`** para explorar arquivos, `<leader> f` para abrir fuzzy, `<leader> g` para buscar no projeto.
2. **Use `gd` e `K`** para navegar código com LSP.
3. **A formatação acontece automaticamente** ao salvar; instale `stylua` e `prettier` se ainda não tiver.
4. **O LSP nativo não precisa de plugins** — apenas servidores instalados (`lua-language-server`, `tsgo`).
5. **A configuração é pequena e explícita**: tudo está nos arquivos `lua/*.lua`.

---

## Recursos úteis

- `:help` — documentação completa
- `:help lsp` — LSP nativo
- `:help diagnostic` — diagnósticos
- `:help findfunc` — busca fuzzy nativa
- `:help netrw` — explorador de arquivos nativo
- Canal de referência (config baseada em): [youtu.be/otRvw9neQkg](https://youtu.be/otRvw9neQkg)
