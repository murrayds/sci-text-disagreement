#
# heatmap_meso_small.R
#
# author: Dakota Murray
#
# Plot a big heatmap showing the score across
# all quereis and meso-fields
#
source("scripts/figures/themes.R")
source("scripts/common.R")

FIG.HEIGHT = 5
FIG.WIDTH = 8.5
SEP.SIZE = 1
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
  make_option(c("--threshold"), action="store", default=NA, type="integer",
              help="The integer threshold for number of citances a meso field
              must have to be selected"),
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

# Get the selected meso-level fields following the same procedure
# as in the fieldmap plots
selected <- map %>%
  filter(`weight<No. sentences>` > opt$threshold) %>%
  rename(score = opt$score) %>%
  group_by(cluster) %>%
  top_n(3, score) %>%
  sample_n(3) %>%
  arrange(score) %>%
  mutate(
    index = row_number()
  ) %>%
  ungroup() %>%
  arrange(cluster, desc(score)) %>%
  mutate(
    number = row_number(),
  ) %>%
  select(id, number)

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
  # Now limit to the selected queries
  inner_join(selected, by = "id") %>%
  filter(sum(score, na.rm = T) > 0) %>%
  # The scores should saturate at the extremes
  mutate(score = ifelse(score > 4, 4, score),
         score = ifelse(score < 0.25, 0.25, score),) %>%
  arrange(cluster) %>%
  mutate(number = factor(number, levels = c(15:1)))

# Build the plot
plot <- plotdata %>%
  ggplot(aes(x = key, y = number, fill = log2(score), color = log2(score))) +
  geom_tile() +
  # Separate disciplines horizontally
  geom_hline(yintercept = 3.5, size = 1, color = SEP.COLOR) +
  geom_hline(yintercept = 6.5, size = 1, color = SEP.COLOR) +
  geom_hline(yintercept = 9.5, size = 1, color = SEP.COLOR) +
  geom_hline(yintercept = 12.5, size = 1, color = SEP.COLOR) +
  # Add the fill and color gradients
  fieldmap_gradient() +
  heatmap_color_gradient() +
  scale_x_discrete(position = "top", expand = c(0, 0)) +
  scale_y_discrete(expand = c(0, 0)) +
  theme_heatmap()

# Add vertical query separators
plot <- heatmap_query_separators(plot, SEP.SIZE, SEP.COLOR)

# Save the plot
ggsave(opt$output, plot, height = FIG.HEIGHT, width = FIG.WIDTH)
