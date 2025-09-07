# Test file to verify R_ environment variable prioritization
# This demonstrates the sorting logic used in REnvironmentHUD

# Simulate environment variables (mix of R_ and regular variables)
test_env_vars <- c(
    "PATH" = "/usr/bin:/usr/local/bin",
    "R_HOME" = "/usr/local/lib/R", 
    "HOME" = "/Users/username",
    "R_LIBS_USER" = "~/R/library",
    "SHELL" = "/bin/bash",
    "R_PROFILE_USER" = "~/.Rprofile",
    "USER" = "username",
    "R_HISTFILE" = "~/.Rhistory"
)

# Create data frame (same logic as REnvironmentHUD)
env_df <- data.frame(
    Variable = names(test_env_vars),
    Value = as.character(test_env_vars),
    stringsAsFactors = FALSE
)

cat("Original order (alphabetical):\n")
print(env_df[order(env_df$Variable), ])

cat("\nNew order (R_ variables first, then alphabetical):\n")
env_df$R_priority <- ifelse(grepl("^R_", env_df$Variable), 1, 2)
sorted_df <- env_df[order(env_df$R_priority, env_df$Variable), ]
sorted_df$R_priority <- NULL
print(sorted_df)

cat("\nExpected result: R_HISTFILE, R_HOME, R_LIBS_USER, R_PROFILE_USER first\n")
cat("Then: HOME, PATH, SHELL, USER\n")