library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(lubridate)


pretty_time <- function(time_obj){
  gsub(
    x = format(time_obj, "%I:%M%p"),
    pattern = "^0", 
    replacement = "",
    perl = TRUE
  )
}

green <- "#106850"
orange <- "#d4782e"
blue <- "#3d89a7"
red <- "#d84b22"
light_grey <- "#e6e5e6"

measure_units <- c(CO2 = "ppm", Temp = "F", Humidity = "%")

air_quality <- read_csv("air_quality.csv", col_names = c("Time", "CO2", "Temp", "Humidity") ) %>% 
  tail(-40) %>%
  mutate(Time = lubridate::mdy_hms(Time, tz = "GMT") %>% with_tz(tzone="EST")) %>% 
  pivot_longer(cols = c(CO2, Temp, Humidity)) %>% 
  mutate(
    value = ifelse(name == "Temp", (value*9/5) + 32, value),
    measure = paste0(name, " (", measure_units[name], ")"),
  )

extremes <- air_quality %>% 
  group_by(name, measure) %>%
  summarise(
    min_value = min(value),
    max_value = max(value),
    min_time = Time[which(value == min_value)[[1]]],
    max_time = Time[which(value == max_value)[[1]]],
    .groups = "drop"
  ) %>% 
  mutate(
    range = max_value - min_value,
    nudge_amnt = range * 0.22,
    min_y = min_value - nudge_amnt,
    max_y = max_value + nudge_amnt
  ) %>% 
  select(-range, -nudge_amnt)

extremes <- bind_rows(
  extremes %>% rename(value = min_value, time = min_time, y = min_y),
  extremes %>% rename(value = max_value, time = max_time, y = max_y)
) 

plot_title <- paste(
  "Air measurements for living room from", pretty_time(min(air_quality$Time)), "to", pretty_time(max(air_quality$Time))
)

air_quality %>% 
  ggplot(aes(x = Time, y = value)) +
  geom_line(aes(color = name)) +
  geom_segment(
    data = extremes,
    aes(x = time, xend = time, y = value, yend = y ),
    alpha = 0.5
  ) +
  geom_label(
    data = extremes, 
    aes(x = time, y = y, label = paste0(round(value,2), measure_units[name])),
    size = 3
  ) +
  facet_grid(rows = "measure", scales = "free", switch = "y") +
  labs(title = plot_title, y = "") +
  scale_color_manual(values = c(CO2 = green, Temp = blue, Humidity = orange)) +
  scale_x_datetime(date_labels = "%I:%M%p") +
  scale_y_continuous(position = "right", expand = expansion(mult = 0.1, add = 0)) +
  theme(
    legend.position = "none",
    panel.background = element_rect(fill=light_grey),
    strip.background.y = element_rect(fill="white"),
    strip.text.y.left = element_text(angle = 0, hjust = 1, size = 12)
  ) 
