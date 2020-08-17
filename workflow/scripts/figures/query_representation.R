#
# query_representation.R
#
# author: Dakota Murray
#
# Plot the relative reprasentation of the share of disagreement
# across fields
#

library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("--input"), action="store", default=NA, type="character",
              help="Path to file containing coded sentences"),
  make_option(c("--type"), action="store", default=NA, type="character",
              help="Type of plot to make, 'all', 'signal_name', or 'filter_name'"),
  make_option(c("-o", "--output"), action="store", default=NA, type="character",
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Load the counts data
counts <- read_csv(opt$input, col_types = cols()) %>%
  gather(key, value, 4:9) %>%
  mutate(
    key = factor(key,
                 levels = c("Biomedical and health sciences", "Life and earth sciences",
                            "Physical sciences and engineering", "Social sciences and humanities",
                            "Mathematics and computer science", "All"),
                 labels = c("Bio & Health", "Life & Earth", "Phys & Engr", "Soc & Hum", "Math & Comp", "All")
                 )
  )

# Get the expected vs. actual values
expected <- counts %>%
  filter(key != "All") %>%
  group_by(key) %>%
  summarize(
    exp = sum(value)
  ) %>%
  mutate(exp = exp / sum(exp))

# Used to color the y-axis differently by signal term
a = c(rep(c(rep("black", 5), rep("darkslategrey", 5)), 6), rep("black", 5))

# Prepare the data for the plot
plotdata <- counts %>%
  filter(key != "All") %>%
  select(signal_name, filter_name, key, value) %>%
  mutate(
    filter_name = ifelse(filter_name == "standalone", "", paste0("+", filter_name)),
  )

print(head(plotdata))
print(opt$type)
if (opt$type == "all") {
  print("general plot")

  plotdata <- plotdata %>%
    unite("query", c("signal_name", "filter_name"), sep = " ")

  FIG.HEIGHT <- 11
  FIG.WIDTH <- 7
  plot.title <- "Actual vs. expected by signal and filter term"
} else if (opt$type %in% c("signal_name", "filter_name")) {
  print("more specific plot")

  plotdata <- plotdata %>%
    rename(query = opt$type) %>%
    group_by(key, query) %>%
    summarize(value = sum(value))

  FIG.HEIGHT <- 7
  FIG.WIDTH <- 5.5
  plot.title <- gsub("_", "", paste0("Actual vs. expected by ", opt$type), fixed = T)
}


plotdata <- plotdata %>%
  group_by(query) %>%
  mutate(
    prop = value / sum(value)
  ) %>%
  left_join(expected, by = "key") %>%
  ungroup() %>%
  mutate(
    change = (prop - exp) / exp * 100,
    representation = ifelse(change < 0, "under-represented", "over-represented"),
    representation = factor(representation, levels = c("under-represented", "over-represented")),
    query = factor(query),
    query = factor(query, levels = rev(levels(query))),
  )

print(head(plotdata))

# Build the plot
plot <- plotdata %>%
  ggplot(aes(x = change, y = query, shape = representation)) +
  geom_vline(xintercept = 0, color = "firebrick", alpha = 0.6) +
  geom_point(size = 2.5) +
  geom_hline(yintercept = c(5.5, 10.5, 15.5, 20.5, 25.5, 30.5, 35.5, 40.5, 45.5, 50.5, 55.5, 60.5),
             linetype = "dashed",
             color = "darkgrey") +
  facet_wrap(~key, nrow = 1, labeller = label_wrap_gen(width = 18, multi_line = TRUE)) +
  scale_x_continuous(
    limits = c(-100, 400),
    breaks = c(0, 200),
    expand = c(0, 0)
  ) +
  scale_shape_manual(
    values = c(1, 16)
  ) +
  coord_cartesian(clip = F) +
  theme_minimal() +
  theme(
    text = element_text(family = "Helvetica", size = 12),
    axis.title.y = element_blank(),
    panel.grid.minor.x = element_blank(),
    panel.grid.minor.y = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.border = element_rect(size = 0.25, fill = NA),
    axis.text.y = element_text(color = a, face = "bold"),
    legend.position = "none",
    legend.title = element_blank(),
    legend.text = element_text(face = "bold", size = 12),
    strip.text = element_text(face = "bold"),
    plot.title = element_text(size = 14, face = "bold")
  ) +
  xlab("% Change from expected proportion") +
  ggtitle(plot.title)


ggsave(opt$output, plot, height = FIG.HEIGHT, width = FIG.WIDTH)
