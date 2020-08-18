#
# query_termporal.R
#
# author: Dakota Murray
#
# Plots the change over time of individual queries
#
source("scripts/figures/themes.R")
source("scripts/common.R")

FIG.HEIGHT <- 6
FIG.WIDTH <- 6

library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("--input"), action="store", default=NA, type="character",
              help="Path to file containing disagreement by gender data"),
  make_option(c("-o", "--output"), action="store", default=NA, type="character",
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))


queries <- read_csv(opt$input, col_types = cols()) %>%
  unite(query, signal_name, filter_name, sep = " +", remove = F) %>%
  filter(pub_year != "All") %>%
  filter(threshold == 80) %>%
  filter(type == "citances")

# Build the plot
plot <- queries %>%
  mutate(
    signal_name = factor(signal_name,
                         levels = c("controvers", "debat", "contradict", "conflict", "no consensus", "disagree", "contrary", "disprov", "questionable")),
    filter_name = ifelse(filter_name == "standalone", "_standalone_", paste0("+", filter_name))
  ) %>%
  ggplot(aes(x = pub_year, y = perc_intext_citations, group = filter_name, color = filter_name, shape = filter_name)) +
  geom_point(size = 1.5) +
  geom_line() +
  facet_wrap(~signal_name, ncol = 3) +
  scale_x_continuous(
    breaks = c(2000, 2008, 2016)
  ) +
  scale_color_manual(values = c("darkgrey", "#1e90ff", "#ff6348", "#27ae60", "#be2edd" )) +
  scale_shape_manual(values = c(NA, 15, 17, 18, 19)) +
  theme_dakota() +
  theme(
    panel.border = element_rect(fill = NA, size = 0.5, color = "black"),
    legend.position = "bottom",
    panel.grid.major = element_blank(),
    legend.title = element_blank(),
    axis.title.x = element_blank()
  ) +
  xlab("Year") +
  ylab("% in-text citations")

# Save the plot
ggsave(opt$output, plot, height = FIG.HEIGHT, width = FIG.WIDTH)
