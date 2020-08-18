#
# heatmap_meso_big.R
#
# author: Dakota Murray
#
# Plot a big heatmap showing the score across
# all quereis and meso-fields
#
source("scripts/figures/themes.R")
source("scripts/common.R")

FIG.HEIGHT = 16
FIG.WIDTH = 10
SEP.SIZE = 1.2
SEP.COLOR = "black"

library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("--input"), action="store", default=NA, type="character",
              help="Path to file containing vosviewer map data of disagreement"),
  make_option(c("--score"), action="store", default=NA, type="character",
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

# Build the plotdata
plotdata <- map %>%
  gather(key, value, query_columns()) %>%
  mutate(
    weight.name = gsub("weight<Share results", "weight<No. results", key, fixed = T),
    key = clean_mapdata_query_name(key),
    key = factor(key, levels = query_levels()),
  ) %>%
  # Re-calculate the score by fields
  group_by(key, cluster) %>%
  mutate(score.field = value / mean(value, na.rm = T)) %>%
  group_by(key) %>%
  mutate(
    value = ifelse(is.na(value), 0, value),
    score.all = value / mean(value, na.rm = T)
  ) %>%
  rename(score = opt$score) %>%
  filter(sum(score, na.rm = T) > 0) %>%
  mutate(score = ifelse(score > 4, 4, score),
         score = ifelse(score < 0.25, 0.25, score),) %>%
  arrange(cluster) %>%
  mutate(row = row_number())

# Build the plot
plot <- plotdata %>%
  ggplot(aes(x = key, y = row, fill = log2(score), color = log2(score))) +
  geom_tile() +
  # Separate disciplines horizontally
  geom_hline(yintercept = 72, size = SEP.SIZE, color = SEP.COLOR) +
  geom_hline(yintercept = 423, size = SEP.SIZE, color = SEP.COLOR) +
  geom_hline(yintercept = 685, size = SEP.SIZE, color = SEP.COLOR) +
  geom_hline(yintercept = 795, size = SEP.SIZE, color = SEP.COLOR) +
  # Add the fill and color gradients
  fieldmap_gradient() +
  heatmap_color_gradient() +
  scale_y_continuous(
    expand = c(0, 0),
    breaks = c(36, 247, 553, 739, 835),
    labels = c("Soc & Hum", "Bio & Health", "Life & Earth", "Phys & Engr", "Math & Comp")
  ) +
  scale_x_discrete(position = "top") +
  theme_heatmap()

# Add vertical separators
plot <- heatmap_query_separators(plot, SEP.SIZE, SEP.COLOR)

ggsave(opt$output, plot, height = FIG.HEIGHT, width = FIG.WIDTH)
