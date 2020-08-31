#
# fieldmap_main.R
#
# author: Dakota Murray
#
# Plot the standard field map, but with a convex hull drawn
# aroung the selected cluster
#
source("scripts/figures/themes.R")
source("scripts/common.R")

FIG.HEIGHT = 5
FIG.WIDTH = 8

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
  make_option(c("--labels"), action="store_true", default=FALSE,
              help="If set, plot labels"),
  make_option(c("-o", "--output"), action="store", default=NA, type="character",
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Load the map file
map <- read_csv(opt$input, col_types = cols()) %>%
  mutate(
    cluster = factor(cluster, labels = field_labels()),
    cluster = factor(cluster, levels = field_levels())
  ) %>%
  rename(score = opt$score)

# Build the plotdata
plotlabs <- map %>%
  filter(`weight<No. sentences>` > opt$threshold) %>%
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
  )

plot <- map %>%
  rowwise() %>%
  mutate(
    # The score will saturate at a specific point
    score = ifelse(score > 4, 4, score),
    score = ifelse(score < 0.25, 0.25, score),
    ) %>%
  ggplot(aes(x = x, y = y,
             size = `weight<No. results 00: valid queries>`,
             fill = log2(score))
  ) +
  geom_point(shape = 21, alpha = 0.9, color = "black") +
  scale_size_area(max_size = 15, breaks = c(0, 4000, 8000)) +
  fieldmap_gradient() +
  guides(size = F, color = F) +
  theme_fieldmap() +
  theme(
    legend.position = "left",
    legend.key.width = unit(0.4, "cm"),
    legend.key.height = unit(2.0, "cm")
  )

# If the labels flag is set, then add the labels to the plot
if (opt$labels) {
  plot <- plot + ggrepel::geom_label_repel(
    data = plotlabs,
    aes(label = number),
    color = "black",
    size = 6,
    fill =  sapply(plotlabs$cluster, cluster2color),
    min.segment.length = 0.1
  )
}

ggsave(opt$output, plot, height = FIG.HEIGHT, width = FIG.WIDTH)
