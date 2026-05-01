# Security

## Reporting

For sensitive security reports, email the maintainer at
`rgthomas@ucsd.edu` rather than filing a public issue.

## Threat model

This plugin is an editor integration that evaluates R code sent
from the current buffer in a user-launched R process. It has no
network surface of its own and stores no credentials.

The primary risk is the same one present in any "source and run"
tool: opening an `.R`, `.Rmd`, or `.qmd` file from an untrusted
source and then submitting its code to R gives that code the
ability to execute arbitrary operations with the user's privileges.
This is a property of the R language, not a plugin bug. Treat
unfamiliar `.R` / `.Rmd` / `.qmd` files the same way you would
treat an unfamiliar shell script.

The plugin writes small temporary files under the current working
directory (prefix `.zz`) for multi-line code submission. These are
deleted by R's `unlink()` after evaluation. If the R process dies
before cleanup, stale temp files may remain; they contain only
your own buffer content and can be safely removed.

## Supported versions

Only the most recent minor release receives security fixes.
