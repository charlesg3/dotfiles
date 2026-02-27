# Neovim Keymap Reference

> **`<leader>`** is `\` (backslash) — e.g. `<leader><leader>` means press `\\`

## LSP / Code Navigation
| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Find all references |
| `gh` | Hover (show type / docs) |

## EasyMotion
| Key | Action |
|-----|--------|
| `s` | Jump to any location (type 2 chars, works across all panes) |

## General
| Key | Action |
|-----|--------|
| `gm` | Open keymap reference (this file) |
| `tt` | Open terminal in vertical split to the right |

## File & Buffer Navigation
| Key | Action |
|-----|--------|
| `<Tab>` | Next buffer |
| `<S-Tab>` | Previous buffer |
| `<C-n>` | Next buffer |
| `<leader><leader>` | Toggle between last two buffers |
| `<C-p>` | CtrlP fuzzy file finder |
| `<C-t>` | Toggle nvim-tree |
| `ff` | Reveal current file in nvim-tree |
| `<C-l>` | Buffer explorer |
| `<S-C-t>` | New tab |
| `<S-C-q>` | Close tab |
| `+` | Next quickfix item |

## nvim-tree (while inside the explorer)
| Key | Action |
|-----|--------|
| `<CR>` | Open file / expand directory |
| `<C-]>` or `cd` | Enter directory (change tree root) |
| `-` | Go up to parent directory |
| `s` | Open file in OS (macOS: `open`) |
| `<C-v>` | Open file in vertical split |
| `<C-x>` | Open file in horizontal split |
| `<C-t>` | Close explorer |

## Cursor Movement
| Key | Action |
|-----|--------|
| `J` / `K` | Jump 10 lines down / up |
| `gg` | Beginning of file |
| `G` | End of file |
| `^` | Beginning of line |
| `$` | End of line |

## Line Editing
| Key | Action |
|-----|--------|
| `<C-j>` / `<C-k>` | Move current line down / up |
| `<S-f>` | Join line below into current line |
| `<` / `>` | Dedent / indent (normal and visual) |

| `L` | Reflow entire file as paragraphs |

## Folding
| Key | Action |
|-----|--------|
| `zR` | Open all folds |
| `zM` | Close all folds (outline mode) |
| `zo` | Open current fold |
| `zc` | Close current fold |

## Commenting
| Key | Action |
|-----|--------|
| `ccc` | Comment line / selection |

## Macros
| Key | Action |
|-----|--------|
| `qq` | Start recording macro |
| `q` | Stop recording |
| `Q` | Replay last macro |

## Clipboard
| Key | Action |
|-----|--------|
| `<C-v><C-v>` | Paste from system clipboard (normal: after cursor, insert: inline, terminal: to shell) |

## Escape / Cancel
| Key | Action |
|-----|--------|
| `<C-g>` | Escape / clear search highlight |
| `kj` | Escape (insert mode) |

## Config
| Key | Action |
|-----|--------|
| `,s` | Re-source init.vim |
| `,v` | Edit init.vim |
| `,b` | Edit .bashrc |
| `<F3>` | Auto-indent entire file |
| `<C-e>` | Toggle taglist |

## Clojure / REPL
| Key | Action |
|-----|--------|
| `<C-s>e` | Send current s-expression to terminal |
| `<C-s>s` | Send visual selection to terminal |
| `<C-s>y` | Sync REPL (require namespaces) |
| `<C-s>r` | Reset REPL terminal |
| `<C-c>k` | Require (reload namespace) |
| `<C-c>j` | Eval expression |
