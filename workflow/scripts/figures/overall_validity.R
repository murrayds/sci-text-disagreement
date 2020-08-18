#
# overall_validity.R
#
# author: Dakota Murray
#
# Plot a dot plot of overall agreement and validity
#
source("scripts/figures/themes.R")

FIG.WIDTH = 4
FIG.HEIGHT = 11

library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("--input"), action="store", default=NA, type="character",
              help="Path to file containing coded sentences"),
  make_option(c("--counts"), action="store", default=NA, type='character',
              help="Path to file containing query counts"),
  make_option(c("-o", "--output"), action="store", default=NA, type="character",
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Load the dataset
agreement <- read_csv(opt$input, col_types = cols()) %>%
  filter(signal_name != "AVERAGE") %>%
  filter(filter_name != "AVERAGE")

# Load the counts of citances returned by each query
counts <- read_csv(opt$counts, col_types = cols())

plot <- agreement %>%
  left_join(counts, by = c("signal_name", "filter_name")) %>%
  mutate(
    filter_name = ifelse(filter_name == "standalone", "", paste0("+", filter_name)),
  ) %>%
  unite(query, c("signal_name", "filter_name"), sep = " ") %>%
  spread(type, value) %>%
  mutate(
    query = factor(query),
    query = reorder(query, (validity))
  ) %>%
  gather(type, value, agreement, validity) %>%
  mutate(
    type = factor(type, levels = c("agreement", "validity"), labels = c("% Agree", "% Valid"))
  ) %>%
  arrange(desc(query)) %>%
  mutate(rank = row_number()) %>%
  ggplot(aes(x = query, y = value, shape = type, fill = type)) +
    geom_rect(xmin = 0, xmax = 131, ymin = 101, ymax = 135,
              fill = "white", color = NA) +
    geom_hline(yintercept = 80,
               linetype = "dashed", color = "darkslategrey") +
    geom_vline(xintercept = 42.5) +
    geom_point(size = 3.5, color = "white",
               aes(alpha = ifelse(rank < 47, "1.0", "0.95"))) +
    geom_text(aes(label = format(All, big.mark=",", format ="d", trim = T),
              color = log10(All), x = query, y = 105),
              hjust = 0, size = 3, family = "Helvetica") +
    scale_y_continuous(
      limits = c(0, 135),
      breaks = c(0, 80, 100),
      expand = c(0, 0)
    ) +
    coord_flip(clip = "off") +
    guides(alpha = F) +
    scale_alpha_manual(values = c(0.6, 1.0)) +
    scale_shape_manual(name = "Measure", values = c(21, 23)) +
    scale_fill_manual(name = "Measure", values = c("dodgerblue4", "firebrick")) +
    scale_color_gradient(name = "# Citances ",
                         low = "#dfe6e9", high = "#2d3436",
                         breaks = c(2, 4, 6),
                         labels = function(x) { parse(text=paste0("10^", x)) },
                         limits = c(1, 7)) +
    theme_dakota() +
    theme(
      axis.title.y = element_blank(),
      axis.text.x = element_text(hjust = 1),
      legend.position = c(0.3, 0.85),
      legend.background = element_rect(size = 0.5)
    ) +
    ylab("%")


ggsave(opt$output, plot, height = FIG.HEIGHT, width = FIG.WIDTH)
