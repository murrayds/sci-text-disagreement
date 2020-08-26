theme_dakota <- function() {
  require(ggplot2)
  theme_minimal() +
  theme(
    text = element_text(family = "Helvetica", size = 12),
    legend.title = element_text(face = "bold"),
    axis.title = element_text(face = "bold"),
    legend.background = element_blank(),
    legend.text = element_text(face = "bold"),
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold"),
    plot.title = element_text(size = 14, face = "bold")
  )
}

theme_fieldmap <- function() {
  require(ggplot2)
  theme_dakota() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.title = element_blank(),
    axis.text = element_blank(),
    legend.title = element_text(size = 14, face = "bold"),
    legend.text = element_text(size = 12, face = "bold"),
    legend.background = element_blank(),
    legend.key.width = unit(2, "cm")
  )
}

theme_heatmap <- function() {
  require(ggplot2)
  theme_dakota() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 0, vjust = 0.5, size = 13),
    panel.grid = element_blank(),
    axis.title = element_blank(),
    axis.text.y = element_text(size = 16, face = "bold"),
    legend.text = element_text(size = 14),
    legend.key.width = unit(0.5, "cm"),
    legend.key.height = unit(1, "cm")
  )
}

# The bottom-end of the ratio gradient for fieldmap
gradient.low <- function() {
  "dodgerblue4"
}

# The high-end of the gradient to use for the fieldmap
gradient.high <- function() {
  "firebrick"
}

# The middle-color for the gradient
gradient.mid <- function() {
  "white"
}


# DEFINE THE COLORS FOR FIELDS
SOCHUM <- "#fdcb6e"
BIOHEALTH <- "#d63031"
LIFEEARTH <- "#00b894"
PHYSENGR <- "#0984e3"
MATHCOMP <- "#6c5ce7"
ALL <- "darkgrey"

# Colors of fields
field_colors <- function() {
  c(SOCHUM,
    BIOHEALTH,
    LIFEEARTH,
    PHYSENGR,
    MATHCOMP)
}

# For the cases when the "All" field is included, such as
# for many of the bar plots
field_long_colors <- function() {
  c(ALL,
    SOCHUM,
    BIOHEALTH,
    LIFEEARTH,
    PHYSENGR,
    MATHCOMP)
}

# For the cases when the "All" field is included and
# should be inlucded in the middle
field_mid_colors <- function() {
  c(SOCHUM,
    BIOHEALTH,
    ALL,
    LIFEEARTH,
    PHYSENGR,
    MATHCOMP)
}

# A simple function that can be used to go from a cluster ID
# to a color
cluster2color <- function(clu) {
  switch(as.character(clu),
         "Soc & Hum" = SOCHUM,
         "Bio & Health" = BIOHEALTH,
         "Phys & Engr" = PHYSENGR,
         "Life & Earth" = LIFEEARTH,
         "Math & Comp" = MATHCOMP)
}

# Color gradient to be used when plotting all field maps
fieldmap_gradient <- function() {
  require(ggplot2)
  scale_fill_gradient2(low = gradient.low(),
                       mid = gradient.mid(),
                       high = gradient.high(),
                       midpoint = 0,
                       limits = c(-2, 2),
                       breaks = c(-2, -1, 0, 1, 2),
                       labels = c("1/4x-", "1/2x", "Avg", "2x", "4x+"),
                       name = "Log2\nratio",
  )
}

# Color gradient to be used when plotting the heatmap,
# should be identical to the fill gradient
heatmap_color_gradient <- function() {
  require(ggplot2)
  scale_color_gradient2(low = gradient.low(),
                       mid = gradient.mid(),
                       high = gradient.high(),
                       midpoint = 0,
                       limits = c(-2, 2),
                       breaks = c(-2, -1, 0, 1, 2),
                       labels = c("1/4x-", "1/2x", "Avg", "2x", "4x+"),
                       name = "Log2\nratio"
  )
}

# Vertical lines used to separate "blocks" of queries in the
# heatmaps
heatmap_query_separators <- function(plot, sep.size, col) {
  require(ggplot2)
  plot <- plot +
    geom_vline(xintercept = 2.5, size = sep.size, color = col) +
    geom_vline(xintercept = 4.5, size = sep.size, color = col) +
    geom_vline(xintercept = 5.5, size = sep.size, color = col) +
    geom_vline(xintercept = 10.5, size = sep.size, color = col) +
    geom_vline(xintercept = 15.5, size = sep.size, color = col) +
    geom_vline(xintercept = 19.5, size = sep.size, color = col) +
    geom_vline(xintercept = 21.5, size = sep.size, color = col) +
    geom_vline(xintercept = 22.5, size = sep.size, color = col) +
    geom_vline(xintercept = 23.5, size = sep.size, color = col)
  return(plot)
}
