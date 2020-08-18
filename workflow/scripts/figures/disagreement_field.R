#
# disagreement_field.R
#
# author: Dakota Murray
#
# Barchart of the overall share of disagreement by field
#
# No input is needed, as the raw values will just be used
#
source("scripts/figures/themes.R")
source("scripts/common.R")


FIG.HEIGHT <- 3.5
FIG.WIDTH <- 6

library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("-o", "--output"), action="store", default=NA, type="character",
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Just hard-code the values
df <- data.frame(value = c(0.006112487, 0.004084958, 0.003157444, 0.002894441, 0.001498165, 0.000638813),
                 field = field_mid_labels())

plot <- df %>%
    mutate(field = factor(field, levels = field_mid_labels()),
           value = value * 100) %>%
    ggplot(aes(x = field, y = value, fill = field)) +
    geom_bar(stat = "identity", color = "black") +
    geom_text(aes(label = paste0(round(value, 2), "%")), vjust = -1, size = 5) +
    scale_fill_manual(values = field_mid_colors()) +
    scale_y_continuous(expand = c(0, 0), limits = c(0, 0.7)) +
    guides(fill = F) +
    theme_dakota() +
    theme(
      panel.grid.major.x = element_blank(),
      panel.border = element_rect(fill = NA, size = 0.5, color = "black"),
      legend.title = element_blank(),
      axis.title.x = element_blank(),
      axis.text.x = element_text(face = "bold"),
    ) +
    ylab("% disagreement")

# Save the plot
ggsave(opt$output, plot, height = FIG.HEIGHT, width = FIG.WIDTH)
