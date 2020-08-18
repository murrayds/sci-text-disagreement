#
# fieldmap_cluster_hull.R
#
# author: Dakota Murray
#
# Plot the standard field map, but with a convex hull drawn
# aroung the selected cluster
#
source("scripts/figures/themes.R")

FIG.HEIGHT = 5
FIG.WIDTH = 7
colors <- field_colors()

library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("--input"), action="store", default=NA, type="character",
              help="Path to file containing vosviewer map data of disagreement"),
  make_option(c("--cluster"), action="store", default=NA, type="character",
              help="The name of the cluster to highlight"),
  make_option(c("-o", "--output"), action="store", default=NA, type="character",
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

clu <- gsub("-", " & ", opt$cluster, fixed = T)

# Load the map file
map <- read_delim(opt$input, col_types = cols(), delim = "\t") %>%
  mutate(
    cluster = factor(cluster, labels = c(labels = c("Soc & Hum", "Bio & Health", "Phys & Engr", "Life & Earth", "Math & Comp")))
  )

hull <- map %>%
  group_by(cluster) %>%
  slice(chull(x, y))

# Used to index the color list
levels <- unique(hull$cluster)

# Build the plot
plot <- map %>%
  ungroup() %>%
  mutate(
    score = `weight<Share results 00: valid queries>` /
             mean(`weight<Share results 00: valid queries>`, na.rm = T),
  ) %>%
  ggplot(aes(x = x, y = y,
             size = `weight<No. results 00: valid queries>`,
             fill = score)
  ) +
  geom_polygon(data = hull %>% filter(cluster == clu), alpha = 0.3,
               color = colors[which(levels == clu)],
               fill = colors[which(levels == clu)],
               size = 1) +
  geom_point(shape = 21, alpha = 0.9) +
  scale_color_manual(values = c("#fdcb6e", "#d63031", "#0984e3", "#00b894", "#6c5ce7")) +
  scale_size_area(max_size = 15, breaks = c(0, 4000, 8000)) +
  scale_fill_gradient2(low = "dodgerblue4", mid = "white", high = "firebrick", midpoint = 1,
                       limits = c(0, 4),
                       breaks = c(0, 1, 2, 3, 4),
                       labels = c("0x", "Avg", "2x", "3x", "4x")
  ) +
  guides(size = F, color = F, fill = F) +
  theme_fieldmap()

ggsave(opt$output, plot, height = FIG.HEIGHT, width = FIG.WIDTH)
