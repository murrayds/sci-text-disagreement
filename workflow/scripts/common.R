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

# Long field levels, to be used in many bar plots
field_long_levels <- function() {
  c("All",
    "Social sciences and humanities",
    "Biomedical and health sciences",
    "Life and earth sciences",
    "Physical sciences and engineering",
    "Mathematics and computer science")
}

# Long field labels
field_long_labels <- function() {
  c("All",
    "Soc & Hum",
    "Bio & Health",
    "Life & Earth",
    "Phys & Engr",
    "Math & Comp"
  )
}

# Get field labels and leels where the middle is "All"
field_mid_labels <- function() {
  c("Soc&Hum",
    "Bio&Health",
    "All",
    "Life&Earth",
    "Phys&Engr",
    "Math&Comp"
  )
}

field_mid_levels <- function() {
  c("Social sciences and humanities",
    "Biomedical and health sciences",
    "All",
    "Life and earth sciences",
    "Physical sciences and engineering",
    "Mathematics and computer science")
}

# Set the names of the columns to use
query_columns <- function() {
   c("weight<Share results 56: no consensus + studies>",
     "weight<Share results 57: no consensus + results>",
     "weight<Share results 58: no consensus + methods>",
     "weight<Share results 59: no consensus + ideas>",
     "weight<Share results 60: no consensus + standalone>",
     "weight<Share results 51: debat* + studies>",
     "weight<Share results 52: debat* + results>",
     "weight<Share results 53: debat* + methods>",
     "weight<Share results 55: debat* + standalone>",
     "weight<Share results 07: contradict* + results>",
     "weight<Share results 06: contradict* + studies>",
     "weight<Share results 21: conflict* + studies>",
     "weight<Share results 14: contrast* + ideas>",
     "weight<Share results 36: controvers* + studies>",
     "weight<Share results 37: controvers* + results>",
     "weight<Share results 38: controvers* + methods>",
     "weight<Share results 39: controvers* + ideas>",
     "weight<Share results 40: controvers* + standalone>",
     "weight<Share results 26: disagree* + studies>",
     "weight<Share results 27: disagree* + results>",
     "weight<Share results 17: contrary + results>",
     "weight<Share results 41: disprov* + studies>",
     "weight<Share results 63: questionable + methods>"
     )
}

# And the levels of the final, formatted columns
query_levels <- function() {
  c("conflict* + studies", "contrast* + ideas",
    "contradict* + studies", "contradict* + results",
    "contrary + results",
    "controvers*", "controvers* + studies", "controvers* + ideas", "controvers* + methods", "controvers* + results",
    "no consensus", "no consensus + studies", "no consensus + methods", "no consensus + results", "no consensus + ideas",
    "debat*", "debat* + studies", "debat* + methods", "debat* + results",
    "disagree* + studies", "disagree* + results",
    "disprov* + studies",
    "questionable + methods"
    )
}

#
filter_term_levels <- function() {
  c("overall", "standalone", "studies", "ideas", "methods", "results")
}

filter_term_labels <- function() {
  labels = c("Overall", "_standalone_", "+studies", "+ideas", "+methods", "+results")
}

clean_mapdata_query_name <- function(query) {
  query = gsub("weight<Share results", "", query, fixed = T)
  query = gsub("[0-9]+", "", query)
  query = gsub("[:>]+", "", query)
  query = trimws(query)
  query = gsub(" + standalone", "", query, fixed = T)
  return(query)
}
