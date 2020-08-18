#########################################
# Common functions and resources
#########################################

# The labels to use for fields
field_labels <- function() {
  c("Soc & Hum",
    "Bio & Health",
    "Phys & Engr",
    "Life & Earth",
    "Math & Comp"
  )
}

# The order of labels to use
field_levels <- function() {
  c("Soc & Hum",
    "Bio & Health",
    "Life & Earth",
    "Phys & Engr",
    "Math & Comp"
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
