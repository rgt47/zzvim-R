# Test long lines that would break R terminal character limits
library(dplyr)
x <- 5

# This long line would break if sent directly (>80 characters)
very_long_variable_name_that_exceeds_normal_limits <- data.frame(column_one_with_long_name = 1:10, column_two_with_very_long_descriptive_name = letters[1:10], column_three_additional_data = rnorm(10))

# Another long line with chained operations
result <- very_long_variable_name_that_exceeds_normal_limits %>% 
  filter(column_one_with_long_name > 5) %>% 
  select(column_one_with_long_name, column_two_with_very_long_descriptive_name) %>%
  arrange(desc(column_one_with_long_name))

# Long function call
complicated_function_call <- some_function_with_long_name(parameter_one = "very long string value that would exceed terminal limits", parameter_two = another_long_parameter_name, parameter_three = yet_another_parameter_with_long_name)

print("Testing completed")