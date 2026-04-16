# Contributing to zzvim-R

## Code of conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Reporting bugs and requesting features

Both use [GitHub Issues](https://github.com/rgt47/zzvim-R/issues)
with structured YAML forms. The forms ask for Vim/Neovim version,
R version, OS, and a minimal reproduction.

## Code contributions

### Setup

```bash
git clone https://github.com/rgt47/zzvim-R.git
cd zzvim-R
make themis-install   # clone vim-themis for functional tests
```

### Running tests

```bash
make test             # smoke + functional, uses vim
make smoke            # smoke tier only
make functional       # themis functional tier only
make test THEMIS_VIM=nvim SMOKE_CMD='nvim --headless -es'
```

All tests must pass before submitting a PR. The CI matrix runs
both Vim and Neovim on Ubuntu, macOS, and Windows.

### Style

- 4-space indentation for VimScript (see `.editorconfig`)
- Use `l:` scope for local variables in functions
- Use `abort` on every `function!` declaration
- Plugin linted with `vint -e` (see `.vintrc.yaml`)
- Do not add 'what' comments; only add 'why' comments
  for non-obvious logic

### PR checklist

The PR template includes a checklist. The key items:

- [ ] Tests added or updated for the changed behavior
- [ ] `make test` passes locally
- [ ] Help documentation (`doc/zzvim-R.txt`) updated if commands,
      mappings, or configuration variables changed
- [ ] `CHANGELOG.md` entry under the `Unreleased` section

### Architecture notes

- `plugin/zzvim-R.vim` -- commands, mappings, startup wiring.
  Sourced unconditionally at Vim startup; keep it thin.
- `autoload/zzvim_r.vim` -- extracted logic; loaded lazily on
  first function call.
- `autoload/zzvimr/terminal_graphics.vim` -- terminal-type
  detection and `.Rprofile.local` template injection.
- `doc/zzvim-R.txt` -- Vim help. Run `vim -c 'helptags doc/'
  -c 'quit'` after editing; do not commit `doc/tags`.
- `test/ci_smoke.vim` -- existence assertions run in CI.
- `test/functional/` -- vim-themis specs for behavioral assertions.

For a fuller overview, see `CLAUDE.md` (instructions for the
AI-assisted development workflow; also a readable architecture
summary).

### Versioning

The project follows [Semantic Versioning](https://semver.org/).
Only the maintainer tags releases.
