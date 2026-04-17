# zzvim-R v1.0.0 Launch Plan
*2026-04-16 17:53 PDT*

Based on a survey of current Vim/Neovim plugin launch practices,
recent successful launches, and R-ecosystem-specific channels.

## Key insight from case studies

The highest-performing launches share three traits:

1. **Visual-first**: a 30-second GIF in the README and every
   announcement post. Text-only posts get dramatically less
   engagement on r/neovim.
2. **Problem-first framing**: write about the workflow problem
   ('terminal-based R development'), not the product ('announcing
   zzvim-R v1.0'). Educational content outperforms direct
   self-promotion.
3. **Timing**: post to Reddit Tuesday-Thursday, 7-9 AM EST for
   maximum algorithmic promotion in the first hour.

## Pre-launch prerequisites (before Day 1)

- [ ] Record a 30-second demo GIF using
  [VHS](https://github.com/charmbracelet/vhs). Show: open .R
  file, `<LocalLeader>rh` to launch R, `<CR>` on a pipe chain,
  `<LocalLeader>h` for head(), `<LocalLeader>0` for HUD dashboard.
  Commit the `.tape` source alongside the GIF.
- [ ] Add the GIF to the top of README.md, immediately after the
  badges.
- [ ] Set GitHub repo topics via Settings > General > Topics:
  `vim-plugin`, `neovim-plugin`, `vim`, `neovim`, `r`,
  `rstats`, `r-language`, `rmarkdown`, `quarto`,
  `data-science`, `vimscript`
- [ ] Verify the GitHub Release at
  https://github.com/rgt47/zzvim-R/releases/tag/v1.0.0 renders
  correctly with install snippets.
- [ ] Set up a blog (dev.to account or personal blog) and draft
  the launch post (see `docs/announcement-drafts.md`).
- [ ] Register blog RSS feed with
  [r-bloggers.com](https://www.r-bloggers.com/add-your-blog/) --
  approval takes 1-3 weeks, so start early. Use an R-specific
  category/tag for the feed URL.

## Day 1 (pick a Tuesday or Wednesday)

**Morning, 7-9 AM EST:**

1. **r/neovim** -- flair: 'Plugin'. Title describes the function,
   not the name. Include the GIF inline (upload to Reddit, not
   an external link). Body: 3-4 sentences on the problem, link
   to repo. Respond to every comment that day.

2. **r/vim** -- similar post, emphasize Vim 8+ support and
   VimScript implementation (no Lua dependency).

**Same day:**

3. **Dotfyle** -- submit via [dotfyle.com](https://dotfyle.com)
   plugin submission form. This can automatically surface in
   This Week in Neovim.

4. **awesome-neovim** -- open PR to
   [rockerBOO/awesome-neovim](https://github.com/rockerBOO/awesome-neovim).
   Rules per CONTRIBUTING.md:
   - PR title: `Add rgt47/zzvim-R`
   - One plugin per PR
   - Capitalize 'Neovim' (not 'nvim', 'Nvim', 'NeoVim')
   - Do not use the word 'plugin' in the description
   - Do not use emojis
   - Run `./scripts/readme-check.sh` before submitting
   - Alphabetize within the appropriate section
   - Suggested section: 'R' (under language-specific) or
     'Programming Languages Support'

5. **awesome-vim** -- open PR to
   [akrawchyk/awesome-vim](https://github.com/akrawchyk/awesome-vim).
   Per contributing.md: individual PR, alphabetized, capitalized
   title, explain why it is noteworthy.

## Days 2-3

6. **vim.org** -- upload at
   [vim.org/scripts](https://www.vim.org/scripts/). Create
   account at
   [vim.org/account/register.php](https://www.vim.org/account/register.php),
   then use 'add script' form. Upload as tarball. The site is
   legacy but still active (5,999 scripts, recent uploads in
   2026).

7. **Vim Awesome** -- submit via
   [vimawesome.com](https://vimawesome.com/). The site also
   auto-scrapes GitHub dotfiles for plugin manager references.
   Listing may take weeks.

8. **Respond to all Reddit comments** -- positive and critical.
   Active maintainer presence builds trust.

## Days 4-5

9. **Publish blog post** -- 'Terminal-Based R Development with
   Vim: An Alternative to RStudio' or similar problem-first
   title. Include the GIF, feature walkthrough, honest
   comparison with R.nvim and ESS. See draft in
   `docs/announcement-drafts.md`.

10. **Cross-post to dev.to** -- tags: `#vim #neovim #rstats
    #programming`.

11. **Mastodon** -- post with `#rstats #neovim #vim` tags on
    Fosstodon or your instance. The R Foundation has 5,470+
    followers at `@R_Foundation@fosstodon.org`; the `#rstats`
    community is small but engaged.

## Day 7

12. **r/rstats** -- separate post, R-workflow framing. Title
    like 'Using Vim/Neovim for R development -- a terminal-based
    alternative to RStudio'. Link to the blog post. Lead with
    R workflow benefits (send code to console, inspect objects,
    navigate Rmd chunks, inline plots), not Vim features.

## Days 8-10

13. **This Week in Neovim** -- if the Dotfyle submission did not
    generate automatic coverage, open a PR to the
    [TWiN contents repo](https://github.com/RoryNesbitt/this-week-in-neovim-contents).
    TWiN is now hosted on Dotfyle.

14. **Matrix `#neovim:matrix.org`** -- share casually if the
    topic comes up organically. Not a broadcast channel.

## Day 14

15. **Review metrics** -- check GitHub Insights > Traffic for
    referral sources, star velocity, and issue activity. Identify
    which channel drove the most traffic.

16. **awesome-neovim follow-up** -- if the PR is still open,
    politely ping. If merged, verify listing on
    [neovimcraft.com](https://neovimcraft.com) (auto-scraped
    from awesome-neovim).

## 4-6 weeks later

17. **Educational follow-up post** on r/neovim or dev.to when a
    meaningful feature ships (e.g., `:checkhealth` support,
    `ftplugin/` extraction in 1.1). Not a 'v1.0.1 bugfix'
    announcement -- only genuine user-facing value.

---

## Channels NOT worth pursuing for 1.0

- **Hacker News**: unpredictable for niche tools. Recent Neovim
  plugin Show HN posts averaged 2-10 points. Try if you have a
  genuinely novel technical story (the plot pipeline might
  qualify), but do not rely on it.
- **LuaRocks**: Lua-only ecosystem. Irrelevant for VimScript.
- **Posit Community**: RStudio-centric forum. Vim plugin threads
  exist but are about RStudio's built-in vim keybindings, not
  external plugins. Low engagement expected.

## Anti-patterns to avoid

1. **Text-only announcements**: no GIF = dramatically less
   engagement. Record with VHS before Day 1.
2. **Name-first titles**: 'Announcing zzvim-R v1.0' loses to
   'Smart R code submission for Vim/Neovim' every time.
3. **Spamming minor updates**: announce major releases only.
   v1.0.1 bugfix posts erode goodwill.
4. **Weekend/late-night Reddit posts**: consistently underperform
   vs Tuesday-Thursday mornings EST.
5. **Ignoring comments**: unresponsive authors get mentally filed
   as 'abandonware'. Respond to everything Day 1.
6. **awesome-neovim formatting mistakes**: using 'nvim' instead
   of 'Neovim', including emojis, bundling multiple plugins.
   These get rejected.

## R-specific strategy notes

- **R-bloggers is the highest-value R channel.** A syndicated
  blog post reaches thousands of R users who will never visit
  r/neovim. Registration requires an existing blog with RSS,
  at least 2 prior posts demonstrating R knowledge, and a
  backlink to r-bloggers. Start the registration process now
  (1-3 week approval).
- **Frame for R users, not Vim users.** On r/rstats and
  r-bloggers, the audience cares about: sending code to console
  efficiently, object inspection without typing R commands,
  Rmd/Quarto chunk workflow, inline plots. Lead with those,
  not with VimScript architecture.
- **Honest positioning vs R.nvim.** R.nvim is Neovim-only, Lua,
  tree-sitter, heavier. zzvim-R is dual Vim/Neovim, VimScript,
  regex-based, lighter. Do not disparage R.nvim -- communities
  overlap and jalvesaq's work built the space zzvim-R operates
  in.

---
*Rendered on 2026-04-16 at 17:53 PDT.*<br>
*Source: ~/prj/sfw/04-zzvim-r/zzvim-R/docs/launch-plan.md*
