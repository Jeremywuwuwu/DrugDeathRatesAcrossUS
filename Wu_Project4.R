#Jeremy Wu
#Author: Jeremy Wu
#Date: 2/5/2026

library(tidyverse)
library(dplyr)
library(ggplot2)

drugs <- read_csv("drugs.csv")
summary(drugs)
drugs %>% 
  summarise(na_count = sum(is.na(STUB_LABEL)))

#1 Which population subgroup experiences the highest average drug overdose death rate (both age adjusted and crude) from all drug overdose deaths 
#Deaths per 100,000 resident population, crude
popcrude_subgroup <- drugs %>% 
  group_by(STUB_LABEL, PANEL) %>% 
  filter(UNIT == "Deaths per 100,000 resident population, crude") %>% 
  summarise(avg_estimate = mean(ESTIMATE, na.rm = TRUE)) %>% 
  arrange(desc(avg_estimate))
#Male 35-44 years old have the highest average estimate of deaths per 100,000 residents at shocking rate of 29.3. Following right behind is Male between the ages of 45-54 years old at 29.2, and then followed up by Male between the ages of 25-34 years old at a 26.2 average estimate number of deaths per 100,000 resident population. 
#Suggestion: male are more prone to death from overdose than females. The highest estimated deaths for the population subgroup are females betwen the age of 45-54 years old is 19.15, 10 less than the average male between the ages of 45-54 years old. 

#Deaths per 100,000 resident population, age-adjusted
pop_subgroup <- drugs %>% 
  group_by(STUB_LABEL, PANEL) %>% 
  filter(UNIT == "Deaths per 100,000 resident population, age-adjusted") %>% 
  summarise(avg_estimate = mean(ESTIMATE, na.rm = TRUE)) %>% 
  arrange(desc(avg_estimate))
#When we dive deeper with the age adjusted factor included, we identified that White Males between the age of 35-44 years old has the highest estimate of deaths per 100,000 residents at 19.9. Followed tightly behind are American Indians or Alaskan Natives at 19.2. We can see the difference between filtering with an age adjusted factor, and the difference in results. 

#Its important to distinguish between the two (Crude & Age Adjusted filter under the UNIT column): An area could have a higher older population leading to a higher natural death rate, and if we are measuring an area with a lot of younger families, then naturally the death rate will be lower. The adjusted rate removes any bias allowing us to compare the true underlying risk of drug overdose deaths between each population, meaning it accounts for age differences for a more fair comparison
# Compare crude vs age-adjusted for different groups
crude_vs_adjusted <- drugs %>%
  filter(STUB_LABEL != "All persons") %>%
  group_by(STUB_LABEL, UNIT) %>%
  summarise(avg_rate = mean(ESTIMATE, na.rm = TRUE)) %>%
  pivot_wider(names_from = UNIT, values_from = avg_rate) %>%
  mutate(difference = `Deaths per 100,000 resident population, age-adjusted` - `Deaths per 100,000 resident population, crude`) %>% 
  drop_na()
#The difference between female age adjusted and non age adjusted estimates are very similar, close to 0. However, the difference is a bit larger for males. This is good to understand before we continue further analysis, understanding the difference in UNIT and how it affects the estimated values of death from overdose.

#2 How have drug overdose trends changed over time for different demographic groups
trend_by_sex <- drugs %>%
  filter(STUB_NAME == "Sex", STUB_LABEL != "All persons") %>%
  group_by(YEAR, STUB_LABEL) %>%
  summarise(avg_estimate = mean(ESTIMATE, na.rm = TRUE)) %>%
  arrange(desc(avg_estimate))

#Now lets display this on a graph
ggplot(trend_by_sex, aes(x = YEAR, y = avg_estimate, color = STUB_LABEL)) +
  geom_line() +
  labs(title = "Drug Overdose Death Rates by Sex Over Time",
       x = "Year", y = "Deaths per 100,000 people", color = "Gender")

#3 Which drug type dow young teens between the ages of 15-24 overdose most on 
age_by_drug <- drugs %>%
  filter(!is.na(AGE), AGE == "15-24 years", PANEL != "All drug overdose deaths", PANEL != "Drug overdose deaths involving any opioid") %>%
  group_by(PANEL) %>%
  summarise(avg_estimate = mean(ESTIMATE, na.rm = TRUE)) %>%
  ungroup() %>% 
  mutate(PANEL_short = case_when(
    PANEL == "Drug overdose deaths involving heroin" ~ "Heroin",
    PANEL == "Drug overdose deaths involving natural and semisynthetic opioids" ~ "Natural/Semi-synthetic",
    PANEL == "Drug overdose deaths involving other synthetic opioids (other than methadone)" ~ "Other Synthetic",
    PANEL == "Drug overdose deaths involving methadone" ~ "Methadone"
  )) %>%
  arrange(desc(avg_estimate))

ggplot(age_by_drug, aes(x = PANEL_short, y = avg_estimate)) +
  geom_col(fill = "steelblue", width = 0.6) +
  labs(
    title = "Drug type vs estimated deaths for teens\nbetween the ages of 15-24 years old",
    x = "Drug Type",
    y = "Deaths per 100,000 people"
  )+
  theme_minimal()+
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
    axis.text.y = element_text(size = 8),
    plot.title = element_text(hjust = 0.5, face = "bold", size = 14))

#4 Which year showed the sharpest increase in overdose deaths?
# Year-over-year change analysis
yearly_change <- drugs %>%
  filter(STUB_LABEL == "All persons") %>%
  group_by(YEAR, PANEL) %>%
  summarise(avg_estimate = mean(ESTIMATE, na.rm = TRUE)) %>%
  arrange(PANEL, YEAR) %>%
  group_by(PANEL) %>%
  mutate(
    prev_year_rate = lag(avg_estimate),
    year_change = avg_estimate - prev_year_rate,
    percent_change = (year_change / prev_year_rate) * 100
  ) %>%
  arrange(desc(percent_change))

panel_short <- yearly_change %>%
  filter(!is.na(percent_change), PANEL != "All drug overdose deaths", PANEL != "Drug overdose deaths involving any opioid") %>%
  mutate(short = case_when(
    PANEL == "Drug overdose deaths involving natural and semisynthetic opioids" ~ "Natural/Semi-synthetic Opiod",
    PANEL == "Drug overdose deaths involving methadone" ~ "Methadone",
    PANEL == "Drug overdose deaths involving other synthetic opioids (other than methadone)" ~ "Other Synthetic",
    PANEL == "Drug overdose deaths involving heroin" ~ "Heroin",
    TRUE ~ PANEL
  ))

ggplot(panel_short, aes(x = YEAR, y = short, fill = percent_change)) + 
  geom_tile(color = "white", linewidth = 0.5) +
  scale_fill_gradient2(low = "orange", mid = "pink", high = "red", midpoint = 0) +
  labs(
    title = "Year over Year Changes\nin Drug Type Overdoses",
    x = "Year",
    y = "Drug Type",
    fill = "% Change from previous year"
  ) +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 8))

