# Manual do Herdr

> Guia prático do terminal workspace manager para agentes de código IA.  
> Baseado na versão instalada em `~/.local/bin/herdr`.

---

## O que é o Herdr

O Herdr é um multiplexador de terminal (estilo tmux) pensado para rodar agentes de IA (Claude Code, Codex, Cursor, Grok, OpenCode, etc.). Ele mantém as sessões sempre vivas, mesmo se você fechar o notebook, perder a rede ou reiniciar a máquina.

**Instalação usada:**

```bash
curl -fsSL https://herdr.dev/install.sh | sh
```

Outras opções: `brew install herdr`, `mise use -g herdr` ou baixar binários em [Releases](https://github.com/herdrdev/herdr/releases).

---

## Conceitos principais

| Conceito    | Descrição                                              |
| ----------- | ------------------------------------------------------ |
| **Session** | Conjunto de workspaces, tabs e panes que persiste      |
| **Workspace** | Área de trabalho independente dentro de uma sessão   |
| **Tab**     | Aba dentro de um workspace                             |
| **Pane**    | Painel/divisão de terminal dentro de uma tab           |
| **Agent**   | Programa de IA rodando dentro de um pane               |

---

## Comandos básicos do CLI

```bash
herdr                           # Inicia ou reanexa à sessão padrão
herdr --session nome            # Cria/entra em uma sessão nomeada
herdr --remote usuario@host     # Anexa a uma sessão remota via SSH
herdr session attach nome       # Anexa a uma sessão existente
herdr server reload-config      # Recarrega config sem reiniciar
herdr server stop               # Para o servidor
herdr config reset-keys         # Restaura os atalhos padrão v2
herdr --default-config          # Imprime a configuração padrão completa
herdr --help                    # Ajuda geral
```

---

## Teclas — Modo Prefixo

O prefixo padrão é **`Ctrl+b`** (igual ao tmux). Pressione `Ctrl+b`, solte, depois a tecla de ação.

> Dica: a qualquer momento pressione **`prefix + ?`** para ver todos os atalhos ativos.  
> Dentro do painel de ajuda use `/` para filtrar ações.

### Navegação e uso diário

| Ação                              | Atalho                         |
| --------------------------------- | ------------------------------ |
| Nova tab                          | `prefix + c`                   |
| Dividir painel à direita          | `prefix + v`                   |
| Dividir paine abaixo              | `prefix + -`                   |
| Mover entre paines                | `prefix + h/j/k/l`             |
| Próxima / tab anterior            | `prefix + n` / `prefix + p`    |
| Ir para tab 1–9                   | `prefix + 1` a `prefix + 9`    |
| Navegar entre workspaces          | `prefix + w`                   |
| Destacar / ampliar painel         | `prefix + z`                   |
| Fechar painel                     | `prefix + x`                   |
| Trocar paines de lugar            | `prefix + Shift + h/j/k/l`     |
| Renomear tab                      | `prefix + Shift + t`           |
| Fechar tab                        | `prefix + Shift + x`           |
| Novo workspace                    | `prefix + Shift + n`           |
| Renomear workspace                | `prefix + Shift + w`           |
| Fechar workspace                  | `prefix + Shift + d`           |
| Abrir seletor "Goto"              | `prefix + g`                   |
| Mostrar/ocultar sidebar           | `prefix + b`                   |
| Desanexar (tudo continua rodando) | `prefix + q`                   |
| Modo redimensionar                | `prefix + r`                   |
| Modo cópia (scroll/selection)     | `prefix + [`                   |

### Modo cópia

Entre com `prefix + [`:

| Ação                            | Atalho                  |
| ------------------------------- | ----------------------- |
| Mover                           | `h/j/k/l`, `w/b/e`      |
| Página acima/abaixo             | `PageUp/PageDown`       |
| Metade da tela acima/abaixo     | `Ctrl+u` / `Ctrl+d`     |
| Buscar para frente / trás       | `/` / `?`               |
| Repetir busca                   | `n` / `N`               |
| Iniciar seleção                 | `v` ou `Space`          |
| Copiar seleção                  | `y` ou `Enter`          |
| Sair sem copiar                 | `q` ou `Esc`            |

> O modo cópia **não pausa** o processo do painel: o conteúdo continua ao vivo.  
> Também é possível selecionar com o mouse diretamente, sem entrar no modo cópia.

---

## Atalhos sem prefixo (recomendados)

A documentação oficial recomenda a família `Ctrl+Alt` porque a maioria dos terminais e SOs não a utiliza:

| Ação                          | Atalho                       |
| ----------------------------- | ---------------------------- |
| Foco painel esquerda          | `Ctrl+Alt+h`                 |
| Foco painel abaixo            | `Ctrl+Alt+j`                 |
| Foco painel acima             | `Ctrl+Alt+k`                 |
| Foco painel direita           | `Ctrl+Alt+l`                 |
| Tab anterior                  | `Ctrl+Alt+[`                 |
| Próxima tab                   | `Ctrl+Alt+]`                 |
| Nova tab                      | `Ctrl+Alt+c`                 |
| Dividir vertical              | `Ctrl+Alt+d`                 |
| Dividir horizontal            | `Ctrl+Alt+Shift+d`           |
| Zoom                          | `Ctrl+Alt+z`                 |

> Alguns atalhos podem ser interceptados pelo terminal ou ambiente gráfico. Se não funcionar, verifique os atalhos do Ghostty, iTerm2, kitty, WezTerm, GNOME, KDE etc.

---

## Configuração (`~/.config/herdr/config.toml`)

Se não existir, o Herdr usa os padrões. Para gerar o arquivo-base completo:

```bash
herdr --default-config > ~/.config/herdr/config.toml
```

Recarregue depois de editar:

```bash
herdr server reload-config
```

ou abra o menu global dentro do Herdr e escolha `reload config`.

### Exemplos de personalização

#### Mudar o prefixo

```toml
[keys]
prefix = "ctrl+a"
```

#### Adicionar atalhos extras

```toml
[keys]
focus_pane_left = ["prefix+h", "ctrl+alt+h"]
next_tab = ["prefix+n", "ctrl+alt+]"]
new_tab = ["prefix+c", "ctrl+alt+c"]
```

#### Comandos personalizados

```toml
[[keys.command]]
key = "prefix+g"
command = "lazygit"
description = "Abrir lazygit"
type = "popup"
```

Tipos disponíveis:

- `popup` — janela flutuante modal
- `pane` — painel temporário em zoom
- `shell` — executa em background
- `plugin_action` — chama ação de plugin instalado

#### Tema

```toml
[theme]
name = "catppuccin-mocha"

# Auto-switch claro/escuro
[theme]
name = "tokyo-night"
auto_switch = true
light_name = "tokyo-night-day"
dark_name = "tokyo-night"
```

#### Barra de tabs na parte inferior

```toml
[ui]
tab_bar_position = "bottom"
```

#### Notificações

```toml
[ui.toast]
mode = "system"   # opções: herdr, terminal, system, off
```

#### Shell padrão e modo de login

```toml
shell = "/bin/zsh"
shell_mode = "auto"   # auto, login, non_login
```

#### Diretório de novos paines

```toml
new_cwd = "follow"   # follow, home, current, ou caminho fixo
```

---

## Dicas práticas

1. **Sempre vivo:** feche o terminal, desconecte da internet ou reinicie — o servidor continua. Use `herdr` para voltar.
2. **Múltiplas sessões:** `herdr --session trabalho` e `herdr --session pessoal`.
3. **Remoto:** `herdr --remote usuario@servidor` mantém tudo rodando no servidor.
4. **Mouse:** você pode clicar em paines, tabs, workspaces e agentes; arrastar bordas; usar menus de botão direito.
5. **Estado dos agentes:** cada painel mostra se o agente está `idle`, `working`, `blocked`, `done` ou `unknown`.
6. **Ajuda rápida:** `prefix + ?` mostra todos os atalhos ativos no momento.

---

## Recursos oficiais

- Site: https://herdr.dev
- Docs: https://herdr.dev/docs/
- Teclado: https://herdr.dev/docs/keyboard/
- Configuração: https://herdr.dev/docs/configuration/
- Referência de config: https://herdr.dev/docs/config-reference/
- Repositório: https://github.com/herdrdev/herdr
