#
# fieldmap_cluster_hull.R
#
# author: Dakota Murray
#
# Plot the standard field map, but with a convex hull drawn
# aroung the selected cluster
#
source("scripts/figures/themes.R")
source("scripts/common.R")

FIG.HEIGHT = 5
FIG.WIDTH = 7
colors <- field_colors() # sourced from themes.R
labs <- field_labels() # sourced from common.R

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
  make_option(c("--cluster"), action="store", default=NA, type="character",
              help="The name of the cluster to highlight"),
  make_option(c("-o", "--output"), action="store", default=NA, type="character",
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

clu <- gsub("-", " & ", opt$cluster, fixed = T)

# Load the map file
map <- read_csv(opt$input, col_types = cols()) %>%
  mutate(
    cluster = factor(cluster, labels = labs)
  ) %>%
  rename(score = opt$score)

hull <- map %>%
  group_by(cluster) %>%
  slice(chull(x, y))

# Used to index the color list
levels <- field_levels()

# Build the plot
plot <- map %>%
  ungroup() %>%
  ggplot(aes(x = x, y = y,
             size = `weight<No. results 00: all valid queries>`,
             fill = log2(score))
  ) +
  geom_polygon(data = hull %>% filter(cluster == clu), alpha = 0.3,
               color = colors[which(levels == clu)],
               fill = colors[which(levels == clu)],
               size = 1) +
  geom_point(shape = 21, alpha = 0.9) +
  scale_color_manual(values = colors) +
  scale_size_area(max_size = 15, breaks = c(0, 4000, 8000)) +
  fieldmap_gradient() +
  guides(size = F, color = F, fill = F) +
  theme_fieldmap()

ggsave(opt$output, plot, height = FIG.HEIGHT, width = FIG.WIDTH)
