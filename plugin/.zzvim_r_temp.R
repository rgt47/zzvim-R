penguins  %>%
  filter(!is.na(bill_len), !is.na(bill_dep)) %>%
  mutate(
    bill_ratio = bill_len / bill_dep,
    size_category = case_when(
      body_mass < 3500 ~ "small",
      body_mass < 4500 ~ "medium",
      TRUE ~ "large"
    )
  )
