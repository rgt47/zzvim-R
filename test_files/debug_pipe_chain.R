missing_summary <- raw_data %>%
  summarise_all(~sum(is.na(.))) %>%
  t() %>% 
  as.data.frame() %>%
  setNames("Missing_Count") %>%
  mutate(Variable = rownames(.),
         Missing_Percent = round(Missing_Count/n*100, 1)) %>%
    arrange(desc(Missing_Count))