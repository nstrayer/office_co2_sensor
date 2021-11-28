library(dplyr)
library(tidyr)
library(ggplot2)

pretty_time <- function(time_obj) {
  gsub(
    x = format(time_obj,"%I:%M%p on %m/%d/%y"),
    pattern = "^0",
    replacement = "",
    perl = TRUE
  )
}

green <- "#106850"
blue <- "#3d89a7"
red <- "#d84b22"
light_grey <- "#e6e5e6"

measure_units <- c(
  CO2 = "ppm",
  Temp = "°F",
  Humidity = "%"
)

plot_air_data <- function(air_quality_wide, room_name, trim_amount = 1){
  
  air_quality <- air_quality_wide %>%
    pivot_longer(cols = c(CO2, Temp, Humidity))
  
  extremes <- air_quality %>% 
    group_by(name) %>% 
    slice(c(which.min(value), which.max(value))) %>% 
    mutate(
      label_pos = value + c(-1, 1)*(last(value) - first(value))*0.22
    )
  
  name_to_measure <- paste0(names(measure_units), " (", measure_units, ")")
  names(name_to_measure) <- names(measure_units)
  
  plot_title <- paste(
    "Air measurements for", room_name, "from",
    pretty_time(min(air_quality$Time)),
    "to",
    pretty_time(max(air_quality$Time))
  )
  
  air_quality %>%
    ggplot(aes(x = Time, y = value)) +
    geom_segment(
      data = extremes,
      aes(
        x = Time,
        xend = Time,
        y = value,
        yend = label_pos
      ),
      alpha = 0.5,
      size = 0.25
    ) +
    geom_label(
      data = extremes,
      aes(
        x = Time,
        y = label_pos,
        label = paste0(round(value, 2), measure_units[name])
      ),
      size = 3
    ) +
    geom_line(aes(color = name)) +
    facet_grid(
      rows = "name",
      scales = "free",
      switch = "y",
      labeller = labeller(name = name_to_measure)
    ) +
    labs(
      title = paste("Air measurements for", room_name),
      subtitle = paste(
        "From",
        pretty_time(min(air_quality$Time)),
        "to",
        pretty_time(max(air_quality$Time))
      ),
      y = ""
    ) +
    scale_color_manual(values = c(
        CO2 = green,
        Temp = red,
        Humidity = blue
      )
    ) +
    scale_x_datetime(date_labels = "%I:%M%p", expand = expansion(mult = 0.06, add = 0)) +
    scale_y_continuous(position = "right", expand = expansion(mult = 0.1, add = 0)) +
    theme(
      legend.position = "none",
      panel.background = element_rect(fill = light_grey),
      strip.background.y = element_rect(fill = "white"),
      strip.text.y.left = element_text(
        angle = 0,
        hjust = 1,
        size = 12
      )
    )
}

