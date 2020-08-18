#
# citance_count_by_field.R
#
# author: Dakota Murray
#
# Plots a barchoart of the citance count by field
#
source("scripts/figures/themes.R")

FIG.HEIGHT <- 2.5
FIG.WIDTH <- 7

library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("--input"), action="store", default=NA, type="character",
              help="Path to file containing coded sentences"),
  make_option(c("-o", "--output"), action="store", default=NA, type="character",
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Load the counts data
counts <- read_csv(opt$input, col_types = cols()) %>%
  gather(key, value, 4:9) %>%
  mutate(
    key = factor(key,
                 levels = c("Biomedical and health sciences", "Life and earth sciences",
                            "Physical sciences and engineering", "Social sciences and humanities",
                            "Mathematics and computer science", "All"),
                 labels = c("Bio & Health", "Life & Earth", "Phys & Engr", "Soc & Hum", "Math & Comp", "All")
                 )
  )

expected <- counts %>%
  filter(key != "All") %>%
  group_by(key) %>%
  summarize(
    exp = sum(value)
  ) %>%
  mutate(exp = exp / sum(exp))

# Build the plot
plotdata <- counts %>%
  filter(key != "All") %>%
  group_by(key) %>%
  summarize(
    total = sum(value)
  ) %>%
  ungroup() %>%
  left_join(expected, by = "key") %>%
  mutate(
    #key = stringr::str_wrap(key, width = 18),
    key = strwrap(key, width = 18),
    key = factor(key),
    key = reorder(key, desc(total)),
  )


plot <- plotdata %>%
  ggplot(aes(x = key, y = (total))) +
  geom_bar(stat = "identity") +
  geom_text(aes(label = paste0(round(exp * 100, 1), "%")),
            y = 150000, color = "white", size = 3.5) +
  geom_text(aes(label = key, y = total + 300000),
            color = "black", size = 4, fontface = "bold") +
  theme_dakota() +
  theme(
    axis.title.x = element_blank(),
    axis.text.x = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.y = element_blank(),
  ) +
  ylab("# Citances") +
  ggtitle("Distribution across fields")


ggsave(opt$output, plot, height = FIG.HEIGHT, width = FIG.WIDTH)
