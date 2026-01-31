# zzvim-R Quick Reference

\begin{multicols}{3}
\footnotesize

## Key Mappings

### Terminal Management
| Key | Action |
|-----|--------|
| `SPC r` | Create R terminal |
| `SPC w` | Vertical split terminal |
| `SPC W` | Horizontal split terminal |
| `SPC q` | Quit R session |
| `SPC c` | Interrupt (Ctrl-C) |

### Code Execution
| Key | Action |
|-----|--------|
| `CR` | Smart submit |
| `SPC sf` | Force function |
| `SPC sl` | Force line |
| `SPC sa` | Smart auto |

### R Markdown
| Key | Action |
|-----|--------|
| `SPC j` | Next chunk |
| `SPC k` | Previous chunk |
| `SPC l` | Execute chunk |
| `SPC t` | All previous chunks |

### Object Inspection
| Key | Function |
|-----|----------|
| `SPC h` | head() |
| `SPC u` | tail() |
| `SPC s` | str() |
| `SPC d` | dim() |
| `SPC p` | print() |
| `SPC n` | names() |
| `SPC f` | length() |
| `SPC g` | glimpse() |
| `SPC b` | dt() |
| `SPC y` | help() |

### HUD Dashboard & Workspace
| Key | Action |
|-----|--------|
| `SPC 0` | **HUD Dashboard** (all 6 tabs) |
| `SPC m` | Memory Usage HUD |
| `SPC e` | Data Frames HUD |
| `SPC z` | Package Status HUD |
| `SPC x` | Environment Variables HUD |
| `SPC a` | R Options HUD |
| `SPC v` | **RStudio-style Data Viewer** |
| `SPC '` | Workspace overview |
| `SPC i` | Inspect object |
| `SPC o` | Insert pipe |

## Ex Commands

### Core Operations
| Command | Action |
|---------|--------|
| `:ROpenTerminal` | Create terminal |
| `:RSendLine` | Send line |
| `:RSendSelection` | Send selection |
| `:RSendFunction` | Send function |
| `:RSendSmart` | Smart detect |
| `:RSend {code}` | Execute code |

### Chunks
| Command | Action |
|---------|--------|
| `:RNextChunk` | Next chunk |
| `:RPrevChunk` | Previous chunk |
| `:RSendChunk` | Execute chunk |
| `:RSendPreviousChunks` | All previous |

### Analysis
| Command | Function |
|---------|----------|
| `:RHead [obj]` | head() |
| `:RTail [obj]` | tail() |
| `:RStr [obj]` | str() |
| `:RDim [obj]` | dim() |
| `:RPrint [obj]` | print() |
| `:RNames [obj]` | names() |
| `:RLength [obj]` | length() |
| `:RGlimpse [obj]` | glimpse() |
| `:RSummary [obj]` | summary() |
| `:RHelp [topic]` | help() |

### Session Control
| Command | Action |
|---------|--------|
| `:RQuit` | Quit R |
| `:RInterrupt` | Interrupt |
| `:RGetwd` | Show directory |
| `:RSetwd [dir]` | Set directory |
| `:RLs` | List objects |
| `:RRm` | Clear workspace |

### Packages
| Command | Action |
|---------|--------|
| `:RLibrary {pkg}` | Load package |
| `:RInstall {pkg}` | Install package |
| `:RSource {file}` | Source file |
| `:RInstallDplyr` | Install dplyr |

### Data Management
| Command | Action |
|---------|--------|
| `:RLoad {file}` | Load RDS |
| `:RSave {obj} {file}` | Save RDS |

### Terminal Association
| Command | Action |
|---------|--------|
| `:RShowTerminal` | Show terminal |
| `:RListTerminals` | List all terminals |
| `:RSwitchToTerminal` | Jump to terminal |
| `:ROpenSplit [type]` | Split terminal |

### HUD Dashboard & Workspace Tools
| Command | Action |
|---------|--------|
| `:RHUDDashboard` | **HUD Dashboard** (all 6 tabs) |
| `:RMemoryHUD` | Memory Usage HUD |
| `:RDataFrameHUD` | Data Frames HUD |
| `:RPackageHUD` | Package Status HUD |
| `:REnvironmentHUD` | Environment Variables HUD |
| `:ROptionsHUD` | R Options HUD |
| `:RDataViewer` | **RStudio-style Data Viewer** |
| `:RWorkspace` | Overview |
| `:RInspect [obj]` | Detailed inspect |

## Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `g:zzvim_r_disable_mappings` | 0 | Disable mappings |
| `g:zzvim_r_terminal_width` | 100 | Vertical width |
| `g:zzvim_r_terminal_height` | 15 | Horizontal height |
| `g:zzvim_r_command` | R --no-save | R startup |
| `g:zzvim_r_chunk_start` | ^```{ | Chunk start |
| `g:zzvim_r_chunk_end` | ^``` | Chunk end |

## Smart Detection

- **Functions**: `function()` → complete function
- **Control**: `if/for/while` → entire block  
- **Multi-line**: `()` `[]` → balanced block
- **Pipes**: `%>%` `|>` → complete chain
- **Lines**: assignments → current line
- **Debug**: inside functions → single lines

## Tips

- LocalLeader = `SPC` (space key)
- Leader = `,` (comma key)
- Each buffer = isolated R session
- Uses `.zzvim_r_temp.R` for clean output
- Visual mode: `CR` sends selection
- Object inspection: cursor word or argument
- Terminal per file for workflow isolation

\end{multicols}