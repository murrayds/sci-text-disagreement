#
# discipline_temporal.R
#
# author: Dakota Murray
#
# Changes over time of disagreement by field
#
source("scripts/figures/themes.R")
source("scripts/common.R")

# Prevent from going into scientific notation
options(scipen=999)

FIG.HEIGHT <- 3.5
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
  make_option(c("--validity"), action="store", default=NA, type="integer",
              help="Validity threshold to use"),
  make_option(c("-o", "--output"), action="store", default=NA, type="character",
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

field <- read_csv(opt$input, col_types = cols()) %>%
  filter(type == "citances") %>%
  filter(threshold == opt$validity) %>%
  mutate(
    pub_year = as.numeric(pub_year),
    perc_intext_citations = perc_intext_citations * 100,
    field = factor(field,
                   levels = field_mid_levels(),
                   labels = field_mid_labels()
                   )
  )

# Labels to mark each field
field.labels <- field %>%
  filter(!is.na(perc_intext_citations)) %>%
  group_by(field) %>%
  filter(pub_year == max(pub_year, na.rm = T))

# Labels for the slopes of each line
slope.labels <- field %>%
  group_by(field) %>%
  summarize(
    slope = round(lm(perc_intext_citations ~ pub_year)$coefficients[2], 4),
  ) %>%
  mutate(
    slope = ifelse(slope > 0, paste0("+", round(slope, 4)), round(slope, 4)),
    pub_year = c(2003.5, 2004, 2007, 2008, 2011, 2013),
    perc_intext_citations = c(0.70, 0.45, 0.36, 0.25, 0.19, 0.01)
  )

# Build the plot
plot <- field %>%
  ggplot(aes(x = pub_year, y = perc_intext_citations, group = field, fill = field, shape = field)) +
  geom_line() +
  geom_point(size = 2.5) +
  geom_rect(xmin = 2015.3, xmax = 2019, ymin = -0.001, ymax = 0.007, fill = "white", color = NA) +
  ggrepel::geom_label_repel(data = field.labels,
             aes(y = perc_intext_citations, x = 2015.5, label = field),
             fill = "white",
             alpha = 0.9,
             direction = "y",
             min.segment.length = 0.1,
             hjust = 0) +
  geom_text(data = slope.labels,
            aes(label = paste0(slope, "/year"), color = field),
            size = 6) +
  scale_x_continuous(limits = c(1999.5, 2019), expand = c(0, 0), breaks = c(2000, 2005, 2010, 2015)) +
  scale_y_continuous(limits = c(0, 0.7)) +
  scale_shape_manual(values = c(21, 22, NA, 24, 23, 25)) +
  scale_fill_manual(values = field_mid_colors()) +
  scale_color_manual(values = field_mid_colors()) +
  theme_dakota() +
  theme(
    axis.title.x = element_blank(),
    legend.position = "none",
    panel.grid.major.x = element_blank(),
    axis.text.x = element_text(),
    legend.title = element_blank(),
    panel.border = element_rect(fill = NA, size = 0.5)
  ) +
  ylab("% disagreement")


# Save the plot
ggsave(opt$output, plot, height = FIG.HEIGHT, width = FIG.WIDTH)
