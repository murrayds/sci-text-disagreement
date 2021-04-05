#
# citations_by_disagreement_citing.R
#
# author: Dakota Murray
#
# Difference in citation rates between disagreement and non-disagreement papers
# by year post-publication
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
  make_option(c("--pubtype"), action="store", default=NA, type="character",
              help="Publication type: all, short, full, or review"),
  make_option(c("-o", "--output"), action="store", default=NA, type="character",
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

citations <- read_csv(opt$input, col_types = cols()) %>%
  filter(type == opt$pubtype) %>%
  # convert wide-format to long, by year
  gather(year, cites, `1`, `2`, `3`, `4`) %>%
  group_by(field, year) %>%
  # Calculate difference
  mutate(
    diff = last(cites) - first(cites)
  ) %>%
  # Remove redundant data
  select(field, year, diff) %>%
  distinct(field, .keep_all = T) %>%
  mutate(
    field = factor(field,
                   labels = c(
                     "All",
                     "Soc&Hum",
                     "Bio&Health",
                     "Life&Earth",
                     "Phys&Engr",
                     "Math&Comp"),
                   levels = field_long_levels()
            )
  )

print(head(citations))
# Construct the plot
plot <- citations %>%
  ggplot(aes(x = year, y = diff, group = field, fill = field, shape = field)) +
  geom_line() +
  geom_point(size = 2.5) +
  geom_text(aes(label = format(round(diff, 1), nsmall = 1)), nudge_y = 0.8) +
  facet_wrap(~field) +
  #scale_x_continuous(limits = c(0, 4), expand = c(0, 0), breaks = c(1, 2, 3, 4)) +
  scale_shape_manual(values = c(3, 21, 22, 24, 23, 25)) +
  scale_fill_manual(values = field_long_colors()) +
  theme_dakota() +
  theme(
    axis.title.x = element_blank(),
    legend.position = "none",
    panel.grid.major.x = element_blank(),
    axis.text.x = element_text(),
    legend.title = element_blank(),
    panel.border = element_rect(fill = NA, size = 0.5)
  ) +
  xlab("Years since publication") +
  ylab("Citation count difference")

# Save the plot
ggsave(opt$output, plot, height = FIG.HEIGHT, width = FIG.WIDTH)
