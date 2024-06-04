# nvim-everysig

A tiny neovim plugin that provides an alternate [`textDocument/signatureHelp`](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_signatureHelp) request handler that displays every signature returned by the language server.

## Optional setup

```lua
require('everysig').setup(options)
```

The `options` table may contain the following keys:

- override: boolean (default false), whether to override the default signature help handler.
- number: boolean (default false), whether to append number comments to displayed signatures.

Example plugin spec for [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    'aattoa/nvim-everysig',
    opts = { override = true },
    event = 'LspAttach',
}
```

## The handler

The signature help handler can be accessed without any setup.

For example, manually override the default handler (same as `setup({ override = true })`):

```lua
vim.lsp.handlers['textDocument/signatureHelp'] = require('everysig').signature_help_handler
```
