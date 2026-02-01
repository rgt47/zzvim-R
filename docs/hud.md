 AI-Assisted R Coding Tools

R developers now have many AI-powered plugins and extensions that act as a “heads-up display” (HUD) inside the IDE. These range from inline code completions (e.g. GitHub Copilot) to chat-like addins (e.g. gptstudio, chattr, chores) that can rewrite or explain code, to visualization tools (e.g. flow, pkgnet) for call graphs and data pipelines. Below we categorize the most relevant tools, their capabilities, limits, integration, and cost.

Inline Code Completion & Suggestions
	•	GitHub Copilot (RStudio Desktop & VS Code): An AI pair programmer offering autocomplete-style ghost-text suggestions as you type ￼. Copilot can generate or complete R code based on context (including comments) and project files ￼. It is built into RStudio (v2023.09+; enable via Tools > Global Options > Copilot) and available as an extension for VS Code. Cost: Paid subscription (free for GitHub Education users) ￼. Limitations: Requires internet; suggestions may need human review; privacy and licensing of generated code should be considered.
	•	TabNine / Codeium (VS Code and others): AI-driven code-completion plugins that support many languages (including R). They offer context-aware suggestions but without the deep project indexing of Copilot. Both have free tiers (Codeium is free; TabNine has free/basic plans and paid advanced models). (No formal R docs; general information from user communities.)
	•	R Language Server (VS Code): A non-LLM tool (language server protocol) used by the official R extension in VS Code ￼. It provides syntax checking, smart autocompletion, function signatures, and in-editor help (hover documentation and inline help) using static analysis ￼. This improves coding speed and is free/open-source. It is less “creative” than Copilot but works offline and is tightly integrated.
	•	VS Code R Extension (R Editor): Provides IDE features (syntax highlighting, plotting, package management) and hooks into the language server and languageserver package ￼. It includes an R data viewer and shows help pages in a side pane. These are not AI, but they form part of the HUD for documentation lookup.
	•	RStudit Built-in Autocomplete: RStudio’s own IntelliSense suggests functions and arguments. While not AI-powered, it’s the baseline for any HUD.

LLM Chat & Refactoring Add-ins
	•	gptstudio (RStudio addins): An R package with several addins for chatting with LLMs and transforming code. For example, the “Chat in Source” addin sends selected R code to the model (via OpenAI API or other services) and replaces it with the response ￼. In practice, you highlight code, invoke the addin (via the Addins menu or shortcut), and the LLM can refactor or document it inline. gptstudio can also “chat” about code in a separate pane. Cost: Free package (requires user’s LLM API key). Limitations: Writes directly into your files; responses depend on model quality.
	•	chattr (RStudio Shiny addin) ￼: A Shiny-based chat interface inside RStudio. After installing the chattr package, you run chattr_app(). You then choose an LLM (e.g. Copilot Chat, OpenAI GPT-3.5/4) and ask questions or request code in the app. Responses are displayed in chunks with buttons to copy code into your script ￼ ￼. This is essentially an embedded ChatGPT/Copilot window. Cost: Free (open-source) – requires subscription or API keys for LLM backends. Limitations: Need to copy code manually (though buttons help), and it runs in RStudio’s Viewer (or terminal).
	•	chores (RStudio addins) ￼ ￼: A collection of specialized LLM “helpers” for repetitive tasks. For example, chores provides helpers to convert code to cli style, generate testthat tests, or auto-document functions with roxygen ￼. The workflow is: highlight code, press the chores shortcut, choose a helper (e.g. “cli”, “testthat”), and the code is rewritten by the LLM. Chores is essentially the successor to the earlier pal and ensure packages (see note below) ￼. Cost: Free (requires setting up an ellmer LLM chat via API key) ￼. Limitations: Experimental; LLM cost per call applies (e.g. ~ $1–$15 per 1,000 edits depending on model) ￼.
	•	gander (RStudio addin) ￼: An experimental chat addin for data science tasks. Unlike generic chat, gander inspects your R session: it knows which data frames, variables, and files are loaded. When you invoke it (with or without selecting code), gander builds a prompt including the current script and R environment, then streams LLM-generated code into your script ￼. For example, you can ask “plot this data frame with ggplot2”, and gander will generate plotting code using the actual column names ￼. Cost: Free (works via ellmer on OpenAI/Anthropic/etc). Limitations: Still experimental (not yet on CRAN); it writes directly to the source file, so mistakes alter your code; requires internet/keys. Early feedback suggests it can greatly speed up tasks by automating boilerplate code.
	•	Pal / Ensure (Superseded): Older RStudio addins (by the same developer as chores/gander). pal (“cli pal”) converted erroring code to use the cli package (fixing error messages) ￼. ensure generated testthat tests for functions. These were superseded by the chores package.
	•	Positron Assistant (Positron IDE) ￼: Positron is a new code editor (like VS Code) by Posit. Its Assistant is a preview feature (as of 2025) that provides LLM chat (currently Anthropic Claude) and inline completions (via GitHub Copilot) ￼. After enabling it, you get a chat pane and can also ask it to refactor or write code. Cost: The editor is free (open-source preview) – using it still requires LLM access (e.g. Copilot token for completions or Anthropic key for chat). Limitations: Early-stage; fewer model choices for now.
	•	RStudio Help/Docs (built-in): RStudio’s Help pane and VS Code’s help pop-ups provide instant access to function documentation and examples. These aren’t AI, but they form part of the HUD by giving real-time documentation when you hover or type ?. (Some new tools like the lang package can even translate help pages on the fly.)

Debugging Assistance & Error Explanation

There are no mainstream tools specifically for “AI debugging” in R (yet), but LLMs and some addins can help:
	•	chores / ensure (test generation): The testthat helper in chores can auto-generate unit tests for selected code ￼. This indirectly aids debugging by encouraging test coverage.
	•	Chat-based Q&A: Using chattr or gptstudio, you can paste an error message or stack trace into the chat and ask the model to explain or fix it. For example, asking “Why am I getting this R error?” can elicit diagnostic help (though results vary with model accuracy).
	•	RStudio debug tools: Traditional breakpoints and traceback() are still the default. (Some LSPs can underline possible issues.)
	•	pacman/reticulate: Not relevant to AI directly, but RStudio’s integration with Python or other languages may allow using AI Python tools.

Code/Data Visualization Tools

For understanding code structure and data flow, the following R packages can create diagrams:
	•	flow (R package) ￼: Generates flowcharts of R functions or scripts. You can visualize the control flow of a function (static) or even run it and highlight the path taken. The flow diagram shows loops, conditionals, and calls, helping debug logic. Usage: functions like flow_view() and flow_run() produce HTML/SVG diagrams. Cost: Free (MIT-licensed) ￼.
	•	pkgnet (R package) ￼: Builds graph representations of an R package’s functions and dependencies. It creates an HTML report with interactive network graphs showing which functions call which, and which packages depend on others. Useful for package developers to find complex dependencies. Cost: Free (open-source) ￼.
	•	targets::tar_visnetwork (targets package) ￼: For data pipelines, the targets package can visualize the DAG of your workflow. tar_visnetwork() inspects your _targets.R and produces an interactive web graph of all targets and global objects, showing dependencies ￼. This helps trace data flow and identify outdated targets. Cost: Free (open-source).
	•	Other tools: R has various diagramming libraries (e.g. DiagrammeR, visNetwork, igraph) that can be scripted to show data or function relationships. For example, one can use these to plot package dependency networks or call graphs. (These require manual setup.)

Integration Platforms

Most AI tools integrate into popular R IDEs:
	•	RStudio Desktop: Supports Copilot (v2023.09+), RStudio addins (chattr, gptstudio, chores, gander) and existing tools (help, viewer). Copilot and addins make the HUD seamless. RStudio Server/Workbench can also use Copilot if enabled by the admin ￼; otherwise, its addins still run via the web UI.
	•	RStudio Cloud: The cloud (web-based RStudio) can run addins (like chattr or gptstudio), but note Copilot is off by default on RStudio Server/Cloud ￼ (requires admin enable).
	•	VS Code (Desktop & Web): The official R extension (with Language Server) plus VS Code AI extensions (Copilot, TabNine, Codeium) provide a robust environment. VS Code also supports R Markdown and interactive plots. Copilot works on both desktop VS Code and Codespaces/web (with subscription).
	•	Positron (Desktop/SSH): A new cross-language IDE by Posit. With Positron Assistant enabled, it offers LLM chat and completions within the editor. It can be run locally or remotely (SSH/Codespaces).
	•	Jupyter/Quarto (Browser): If you run R in a Jupyter notebook or Quarto (e.g. via Kaggle, Colab), you can still call out to ChatGPT via APIs or browser extensions, but native IDE HUD support is limited. Quarto sessions don’t yet have built-in LLM integrations like RStudio.

Summary Tables

AI Coding Assistants and Integrations. Tools below provide code completion, chat, or refactoring assistance within R IDEs. All “LLM” tools require an API key or subscription to an underlying model (except R language server).

Tool / Extension	IDE / Platform	Capabilities	Cost / Notes
GitHub Copilot ￼	RStudio Desktop (v2023.09+), VS Code	Autocomplete-style AI suggestions (ghost-text) for R (and other languages). Can index project files for context ￼.	Paid subscription (free for students) ￼; requires internet.
R Language Server (RLS) ￼	VS Code (R extension), other editors (via LSP)	Static code analysis: syntax linting, smart completion, function signature help, and inline documentation ￼.	Free (open-source). Works offline.
VS Code R Extension ￼ ￼	VS Code	R console, plotting, data viewer, help pane integration ￼; uses RLS for completion ￼.	Free.
gptstudio (chat addins) ￼	RStudio (Addins menu)	LLM chat and code transformation. E.g. “Chat in Source” sends selected code to GPT and inserts response ￼.	Free package (requires user LLM API key).
chattr (Shiny chat UI) ￼	RStudio (Shiny Viewer)	Interactive chat with Copilot Chat or OpenAI. Returns code which can be copied into scripts ￼.	Free package (requires Copilot or OpenAI token).
chores (LLM helpers) ￼	RStudio (Addins / shortcut)	Contextual code refactoring helpers (e.g. convert to cli::cli_abort(), generate testthat tests, add Roxygen docs) ￼ ￼.	Free (requires LLM access via ellmer).
gander (context chat) ￼	RStudio (Addin)	Chat interface that “sees” your R session (data frames, variables). Generates or refines code using actual workspace context ￼.	Free (requires LLM key). Experimental (not on CRAN yet) ￼.
Positron Assistant ￼	Positron IDE	LLM chat pane (Anthropic Claude) and inline completions (GitHub Copilot) ￼.	Free (open-source preview; uses Copilot or Claude keys).
RStudio Help Viewer	RStudio / VS Code	Displays R documentation and examples for functions (static lookup). Not AI, but provides immediate docs in the HUD.	Free (built into IDE).

Code & Pipeline Visualization Tools. These packages can create diagrams of code logic or data workflows. They are offline tools (no LLM) that complement an AI HUD by making program structure clear.

Tool / Package	Purpose	Output / Features	Cost
flow ￼	Function logic flowcharts	Draws static flow diagrams of R functions/scripts, or visualizes the execution path of a function call ￼.	Free (MIT)
pkgnet ￼	Package dependency graph	Builds interactive HTML reports showing function-level and package-level dependency graphs (which functions call which, which packages are used) ￼.	Free (open source)
targets::tar_visnetwork ￼	Pipeline DAG visualization	Visualizes a directed acyclic graph of targets in a _targets.R workflow, showing data flow between analysis steps ￼.	Free (open source)

Each tool listed above integrates differently but aims to reduce friction for R coding. For example, Copilot ghost-completions reduce manual typing, chattr/gptstudio let you query an LLM as if it were a colleague, and chores automates routine edits. Together, they form an AI “HUD” that can suggest code, fetch docs, explain errors, and even draw diagrams, all within your R environment.

Sources: Authoritative documentation and blogs for each tool are cited above (using the format 【tool†Lx-Ly】). For example, Posit’s RStudio guide notes Copilot integration ￼; the gptstudio vignette describes the “Chat in Source” addin ￼; and Simon Couch’s chores website explains LLM-powered helpers ￼ ￼. These connected sources support the summaries above.
