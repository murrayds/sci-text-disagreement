#
# fieldmap_reference.R
#
# author: Dakota Murray
#
# Plot a fieldmap reference
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

# Used to clean tags from the string
cleanFun <- function(htmlString) {
  return(gsub("<.*?>", "", htmlString))
}

# Command line arguments
option_list = list(
  make_option(c("--input"), action="store", default=NA, type="character",
              help="Path to file containing vosviewer map data of disagreement"),
  make_option(c("-o", "--output"), action="store", default=NA, type="character",
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))


# Load the map file
map <- read_delim(opt$input, col_types = cols(), delim = "\t") %>%
  mutate(
    cluster = factor(cluster, labels = c(labels = c("Soc & Hum", "Bio & Health", "Phys & Engr", "Life & Earth", "Math & Comp")))
  ) %>%
  rowwise() %>%
  mutate(
    journals = unlist(strsplit(cleanFun(description), ":"))[4],
    topics = unlist(strsplit(cleanFun(description), ":"))[5]
  )

# Select labels for the plots
plotlabs <- map %>%
  group_by(cluster) %>%
  top_n(3, `weight<No. sentences>`) %>%
  rowwise() %>%
  mutate(
    select.journal = unlist(strsplit(journals, ";"))[1],
    select.journal <- gsub("journal", "j.", select.journal, fixed = T),
    select.journal <- gsub("review", "rev.", select.journal, fixed = T),
    lab = paste0(strwrap(select.journal, width = 20), collapse = "\n")
  )

# Construct the plot
plot <- map %>%
  ggplot(aes(x = x, y = y,
             size = `weight<No. sentences>`,
             fill = cluster)
  ) +
  geom_point(shape = 21, alpha = 0.75) +
  ggrepel::geom_label_repel(
    data = plotlabs,
    aes(label = lab),
    fill = "white",
    size = 2.5,
    alpha = 0.9,
    min.segment.length = 0.1) +
  scale_size_area(max_size = 12) +
  scale_fill_manual(values = colors) +
  guides(size = F,
         fill = guide_legend(override.aes = list(size = 5))) +
  theme_fieldmap()

ggsave(opt$output, plot, height = FIG.HEIGHT, width = FIG.WIDTH)
