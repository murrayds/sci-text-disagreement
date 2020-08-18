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

# build the plotdata
plotdata <- map %>%
  gather(key, value, query_columns()) %>%
  mutate(
    weight.name = gsub("weight<Share results", "weight<No. results", key, fixed = T),
    key = clean_mapdata_query_name(key),
    key = factor(key, levels = query_levels()),
    value = ifelse(is.na(value), 0, value)
  ) %>%
  group_by(key, cluster) %>%
  mutate(
    score.field = value / mean(value)
  ) %>%
  group_by(key) %>%
  mutate(
    score.all = value / mean(value)
  ) %>%
  rename(score = opt$score) %>%
  filter(!is.na(key)) %>%
  rowwise() %>%
  mutate(
    score = ifelse(is.na(score), 0, score),
    score = ifelse(score < 0.25, 0.25, score),
    score = ifelse(score > 4, 4, score),
    weight = get(weight.name),
    weight = ifelse(weight == 0, 1, weight)
  )

print(plotdata %>% filter(key == "no consensus + ideas") %>% select(score, id))
# Build the plot
plot <- plotdata %>%
  ggplot(aes(x = x, y = y,
             size = log10(weight),
             fill = log2(score))
  ) +
  geom_point(shape = 21, stroke = 0.15) +
  facet_wrap(~key, ncol = 4) +
  scale_size_area(max_size = 5) +
  fieldmap_gradient() +
  guides(alpha = F, size = F) +
  theme_fieldmap() +
  theme(
    legend.position = "bottom",
    legend.key.width = unit(2, "cm")
  )

# Save the plot
ggsave(opt$output, plot, height = FIG.HEIGHT, width = FIG.WIDTH)
