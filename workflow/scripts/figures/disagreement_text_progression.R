#
# disagreement_gender.R
#
# author: Dakota Murray
#
# Plots a barchoart of the gender differences in disagreement
#
source("scripts/figures/themes.R")
source("scripts/common.R")

FIG.HEIGHT <- 4
FIG.WIDTH <- 6

library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("--input"), action="store", default=NA, type="character",
              help="Path to file containing disagreement by gender data"),
  make_option(c("-o", "--output"), action="store", default=NA, type="character",
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Load the data and filter to the appropriate values
progression <- read_csv(opt$input, col_types = cols()) %>%
  mutate(
    progression = factor(progression,
                         levels = c("0-5", "5-10", "10-15", "15-20", "20-25",
                                    "25-30", "30-35", "35-40", "40-45", "45-50",
                                    "50-55", "55-60", "60-65", "65-70", "70-75",
                                    "75-80", "80-85", "85-90", "90-95", "95-100")
    ),
    field = factor(field,
                   levels = field_long_levels(),
                   labels = field_long_labels()
    ),
    type = factor(type,
                  levels = c("all", "disagreement"),
                  labels = c("All citances", "Disagreement citances"))
  )

print(head(progression))
# Build the plot
plot <- progression %>%
  ggplot(aes(x = progression, y = perc_citance, group = type, linetype = type, color = field)) +
  geom_line(aes(fill = field)) +
  #geom_point(size = 2) +
  scale_x_discrete(breaks = c("0-5", "45-50", "95-100")) +
  #scale_shape_manual(values = c(NA, 21, 22, 24, 23, 25)) +
  #scale_size_manual(values = c(1, 0.5, 0.5, 0.5, 0.5, 0.5)) +
  scale_fill_manual(values = field_long_colors()) +
  facet_wrap(~field) +
  guides(color = F, fill = F) +
  theme_minimal() +
  theme(
    text = element_text(size = 12, family = "Helvetica"),
    #legend.position = c(0.75, 0.75),
    legend.position = "bottom",
    legend.background = element_rect(fill = "white", color = "black"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid.major.x = element_blank(),
    legend.title = element_blank()
  ) +
  xlab("% progression") +
  ylab("% of citances")

# Save the plot
ggsave(opt$output, plot, height = FIG.HEIGHT, width = FIG.WIDTH)
