#
# fieldbar_meso_top.R
#
# author: Dakota Murray
#
# Barplot showing the top meso-fields
#
source("scripts/figures/themes.R")
source("scripts/common.R")

FIG.HEIGHT = 11.5
FIG.WIDTH = 7
colors <- field_colors() # Sourced from themes.R
labs <- field_labels() # sourced from common.R
levs <- field_levels()

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
    cluster = factor(cluster, labels = labs),
    cluster = factor(cluster, levels = levs)
  ) %>%
  rename(score = opt$score)

# Build the plotdata
plotdata <- map %>%
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
  ) %>%
  rowwise() %>%
  mutate(
    # Get the top journals from the lab variable
    lab = paste0(unlist(strsplit(lab, ";"))[1:2], collapse = ";"),
  )

# Build the plot
plot <- plotdata %>%
  ggplot(aes(x = index, y = score, fill = cluster)) +
  geom_bar(stat = "identity", color = "black") +
  # Journal labels to each meso-field
  geom_text(aes(label = lab, y = 0), hjust = 1, nudge_y = -0.1, lineheight = .8, size = 4) +
  # Show the ratio to the right of each bar
  geom_text(aes(label = paste0(sprintf("%.1f", round(score, 1)), "x")), hjust = -0.2, width = 1, fill = "white", size = 5.5) +
  # Label to order the points
  geom_label(aes(label = number, y = 0.25), size = 6) +
  facet_wrap(~cluster, ncol = 1) +
  scale_x_discrete(expand = c(0, 0)) +
  scale_y_continuous(
    limits = c(-2.2, 4),
    breaks = c(0, 1, 2, 3, 4),
    labels = c("0x", "Avg", "2x", "3x", "4x")) +
  scale_fill_manual(values = colors) +
  coord_flip() +
  guides(fill = F) +
  theme_dakota() +
  theme(
      panel.grid.major.y = element_blank(),
      axis.title = element_blank(),
      axis.text.x = element_text(face = "bold", size = 14),
      axis.text.y = element_blank(),
      legend.key.width = unit(2, "cm")
    )

ggsave(opt$output, plot, height = FIG.HEIGHT, width = FIG.WIDTH)
