# Neovim — config zero-plugin (nvim_native)

Manual de uso e pós-instalação da config instalada pelos scripts `install-dev-cli-tools.sh`
e `setup-wsl-cli.sh` deste repositório.

- Config original: https://github.com/smnatale/nvim_native
- Filosofia: **zero plugin manager** (sem lazy.nvim/packer). Tudo é feito com recursos
  nativos do Neovim 0.11+ (`vim.lsp.enable()`, `findfunc`, `netrw`, autocmds, etc).

## O que o instalador faz

1. Instala o binário oficial do **Neovim >= 0.11** (baixado da release mais recente do
   GitHub, não do `apt`, porque o pacote do Ubuntu costuma ser mais antigo que 0.11 —
   requisito da config para `vim.lsp.enable()`).
2. Instala as dependências externas usadas pela config:
   - `ripgrep` (`rg`) — usado por `:grep` / `<leader>g`.
   - `lua-language-server` — LSP para arquivos `.lua`.
   - `tsgo` (pacote npm `@typescript/native-preview`) — LSP para JS/TS/JSX/TSX.
   - `stylua` — formata `.lua` ao salvar.
   - `prettier` — formata `.js/.ts/.tsx/.json` ao salvar.
3. Clona a config em `~/.config/nvim`. **Se já existir uma config anterior**, ela é
   movida para `~/.config/nvim.bak-<timestamp>` antes (nada é apagado).
4. **Desvio em relação ao repo original**: `lua/colorscheme.lua` faz
   `vim.cmd.colorscheme("catppuccin")`, mas o repo `nvim_native` **não inclui** esse
   colorscheme e ele não é nativo do Neovim — sem instalá-lo à parte, o Neovim erra
   `E185: Cannot find color scheme 'catppuccin'` na primeira abertura. Para manter o
   espírito "zero plugin manager", o instalador clona
   `catppuccin/nvim` como **pacote nativo do Vim** (recurso `:h packages`, não é um
   plugin manager) em:
   ```
   ~/.config/nvim/pack/colors/start/catppuccin.nvim
   ```
   O Neovim carrega qualquer coisa em `pack/*/start/*` automaticamente no boot — não
   precisa de `require`, `packadd` nem plugin manager.

## Atalhos (leader = <space>)

| Atalho        | Ação |
|---------------|------|
| `<leader>w`   | Salvar (`:w`) |
| `<leader>q`   | Sair (`:q`) |
| `U`           | Redo (`<C-r>`) |
| `<C-h/j/k/l>` | Navegar entre splits |
| `<leader>e`   | Abrir/fechar árvore de arquivos (`netrw`, `:Lexplore`) |
| `%` (dentro do netrw) | Criar arquivo/pasta na janela anterior |
| `<leader>f`   | Fuzzy find de arquivos (`:find`, usa `matchfuzzy()` nativo) |
| `<leader>g`   | Grep (pede o padrão, roda `ripgrep`, abre quickfix) |
| `<leader>d`   | Abrir lista de diagnósticos no quickfix |

### LSP (Neovim 0.11+ já traz os keymaps padrão, não precisa configurar)

| Atalho | Ação |
|--------|------|
| `K`    | Hover (documentação) |
| `grn`  | Rename |
| `gra`  | Code action |
| `grr`  | References |
| `gri`  | Go to implementation |
| `gO`   | Document symbols |
| `CTRL-]` | Go to definition |

Autocomplete abre automaticamente ao digitar (`autotrigger = true`), com
`completeopt+=noselect`.

### Formatação automática ao salvar

- `.lua` → `stylua`
- `.js` / `.ts` / `.tsx` / `.json` → `prettier`
- Qualquer outro filetype → cai no fallback do LSP (`vim.lsp.buf.format`), se o
  servidor anexado suportar formatação.

## Checklist pós-instalação

1. Abra `nvim` e rode `:checkhealth` — confira LSP, clipboard e provedores.
2. Abra um arquivo `.lua` em qualquer pasta e confirme que o `lua_ls` conectou
   (`:checkhealth lsp` ou `:LspInfo` se existir) e que diagnósticos aparecem.
3. `tsgo` só anexa em projetos com marcador de raiz: `package-lock.json`, `yarn.lock`,
   `pnpm-lock.yaml`, `bun.lock(b)` ou `.git`. Teste abrindo um `.ts`/`.tsx` dentro de um
   projeto Node de verdade — em um arquivo solto sem esses marcadores o LSP de
   TypeScript não vai subir.
4. Salve um arquivo `.lua` e um `.ts`/`.json` e confirme que a formatação rodou
   (`stylua`/`prettier`).
5. Teste `<leader>f` (find), `<leader>g` (grep), `<leader>e` (árvore de arquivos) e
   `<leader>d` (diagnósticos).
6. Se você tinha uma config antiga, ela está em `~/.config/nvim.bak-<timestamp>`. Para
   voltar atrás:
   ```bash
   rm -rf ~/.config/nvim
   mv ~/.config/nvim.bak-<timestamp> ~/.config/nvim
   ```
7. No WSL, `:checkhealth` pode reclamar de clipboard — para integrar com o clipboard do
   Windows instale `win32yank` (`winget install --id=equalsraf.win32yank` no Windows, ou
   baixe o `.zip` e coloque `win32yank.exe` no PATH do WSL).

## Atualizando a config

Como `~/.config/nvim` é um clone git do `nvim_native`:

```bash
cd ~/.config/nvim
git pull
```

Se você editou arquivos localmente, `git stash` antes do `pull` para não perder nada.

## Requisitos por trás de cada dependência

| Ferramenta | Por quê | Se faltar |
|---|---|---|
| Neovim >= 0.11 | `vim.lsp.enable()`, keymaps LSP padrão | Erro ao carregar `lsp.lua` |
| ripgrep | `<leader>g` (grepprg) | Grep não funciona |
| lua-language-server | LSP de `.lua` | Sem diagnósticos/autocomplete em Lua |
| tsgo | LSP de JS/TS | Sem diagnósticos/autocomplete em JS/TS |
| stylua | Formatar `.lua` ao salvar | `.lua` não formata (cai no fallback LSP) |
| prettier | Formatar JS/TS/JSON ao salvar | Idem, cai no fallback LSP |
| catppuccin.nvim (pacote nativo) | Colorscheme usado em `colorscheme.lua` | Erro `E185` ao abrir o Neovim |
