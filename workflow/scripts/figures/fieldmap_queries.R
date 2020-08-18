#
# fieldmap_queries.R
#
# author: Dakota Murray
#
# Plot the fieldmap across each query
#
source("scripts/figures/themes.R")
source("scripts/common.R")

FIG.HEIGHT = 12
FIG.WIDTH = 10

library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("--input"), action="store", default=NA, type="character",
              help="Path to file containing vosviewer map data of disagreement"),
  make_option(c("--score"), action="store", default=NA, type="integer",
              help="The scoring approach to use, either `score.all` or
                    `score.field`"),
  make_option(c("-o", "--output"), action="store", default=NA, type="character",
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Load the map file
map <- read_csv(opt$input, col_types = cols()) %>%
  mutate(
    cluster = factor(cluster, labels = field_labels()),
    cluster = factor(cluster, levels = field_levels())
  )

# build the plot
plot <- map %>%
  gather(key, value, columns) %>%
  mutate(
    weight.name = gsub("weight<Share results", "weight<No. results", key, fixed = T),
    key = gsub("weight<Share results", "", key, fixed = T),
    key = gsub("[0-9]+", "", key),
    key = gsub("[:>]+", "", key),
    key = trimws(key),
    key = gsub(" + standalone", "", key, fixed = T),
    key = factor(key, levels = levs),
    value = ifelse(is.na(value), 0, value)
  ) %>%
  group_by(key) %>%
  mutate(
    value = ifelse(is.na(value), 0, value),
    score.all = value / mean(value)
  ) %>%
  group_by(key, cluster) %>%
  mutate(
    score.field = value / mean(value)
  ) %>%
  rename(score = opt$score) %>%
  filter(!is.na(key)) %>%
  rowwise() %>%
  mutate(
    score = ifelse(is.na(score), 0, score),
    score = ifelse(log2(score) > 4, 4, score),
    weight = get(weight.name),
  ) %>%
  ggplot(aes(x = x, y = y,
             size = log10(weight),
             alpha = ifelse(is.na(score), "empty", "full"),
             fill = log2(score))
  ) +
  geom_point(shape = 21, stroke = 0.15) +
  scale_alpha_manual(values = c(1, 1)) +
  facet_wrap(~key, ncol = 4) +
  scale_size_area(max_size = 5) +
  fieldmap_gradient() +
  guides(alpha = F, size = F) +
  theme_fieldmap() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.title = element_blank(),
    axis.text = element_blank(),
    legend.position = "bottom",
    legend.key.width = unit(2, "cm")
  )

ggsave(opt$output, plot, height = FIG.HEIGHT, width = FIG.WIDTH)
