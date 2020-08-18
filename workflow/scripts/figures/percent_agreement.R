#
# plot_agreement.r
#
# author: Dakota Murray
#
# Plot a heatmap of the percent agreement
#
source("scripts/figures/themes.R")

FIG.WIDTH = 5
FIG.HEIGHT = 6

library(dplyr)
library(ggplot2)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("-i", "--input"), action="store", default=NA, type="character",
              help="Path to file containing coded sentences"),
  make_option(c("--type"), action="store", default=NA, type='character',
              help="'agreement' or 'validity' for the type of measure to plot"),
  make_option(c("-o", "--output"), action="store", default=NA, type="character",
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Load the dataset
agreement <- readr::read_csv(opt$input, col_types = readr::cols()) %>%
  filter(type == opt$type)

# Plot options based on the measure type to plot
if (opt$type == "agreement") {
    plot.title = "Percent Agreement"
    leg.title = "% Agree"
    viridis.option = "D"
} else {
    plot.title = "Percent Validity"
    leg.title = "% Valid"
    viridis.option = "C"
}

# Build the plot
plot <- agreement %>%
  mutate(
    filter_name = factor(filter_name,
                         levels = c("standalone", "studies", "ideas", "methods", "results", "AVERAGE"),
                         labels = c("_standalone_", "+studies", "+ideas", "+methods", "+results", "AVERAGE")),
    signal_name = factor(signal_name),
    signal_name = factor(signal_name,
                         level = rev(levels(factor(agreement$signal_name)))
                        )
  ) %>%
  ggplot(aes(x = filter_name, y = signal_name, fill = value)) +
  geom_tile(color = "white", size = 0.8, alpha = 0.7) +
  geom_text(aes(label = format(round(value, 1), nsmall = 1),
                fontface = ifelse(signal_name == "AVERAGE" | filter_name == "AVERAGE", "bold", "plain")
            ),
            size = 3,
            color = "black") +
  viridis::scale_fill_viridis(name = leg.title,
                              option = viridis.option,
                              breaks = c(0, 50, 100),
                              limits = c(0, 100),
                              labels = c("0", "50", "100")) +
  scale_x_discrete(position = "top") +
  guides(color = F) +
  theme_dakota() +
  theme(
    axis.text.x = element_text(angle = -30, hjust = 1),
    legend.title = element_text(face = "bold", vjust = 0.5),
    panel.grid = element_blank(),
    plot.title = element_text(size = 13, face = "bold"),
    legend.key.width = unit(0.5, "cm"),
    legend.key.height = unit(1, "cm"),
    axis.title = element_blank()
  ) +
  xlab("Filter term") +
  ylab("Signal term") +
  ggtitle(plot.title)

ggsave(opt$output, plot, height = FIG.HEIGHT, width = FIG.WIDTH)
