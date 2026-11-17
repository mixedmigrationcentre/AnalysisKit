# Fixtures for the route analysis tests.
#
# Four respondents in an ONA-style export (label row first, choice labels in
# the select_multiple child cells), with every column of the three route
# blocks. Built so the expected numbers can be worked out by hand:
#
# Places stopped
#   r1  Female  Mali/Gao (Work), Mali/Bamako (Work + Rest/sleep), Niger/Agadez (Rest/sleep)
#   r2  Male    Mali/Gao (Rest/sleep)
#   r3  Female  Niger/Agadez (Work), then a "None" country, which is no stop
#   r4  Male    no stop
#
# Most dangerous locations
#   r1  Libya/Sabha: Physical violence, by "Armed groups/militias"
#   r2  Libya/Kufra: None, perpetrator not asked
#
# Transit countries
#   r1 Mali, Niger; r2 Mali; r3 Niger; r4 none. Q72 asked of all four.

route_fixture_body <- function() {
  n <- 4
  na <- rep(NA_character_, n)
  cols <- list(
    Q27 = c("Female", "Male", "Female", "Male"),
    weight = c("1", "3", "1", "1")
  )

  # Transit
  for (q in paste0("Q", 47:54)) {
    cols[[q]] <- na
  }
  cols$Q47 <- c("Mali", "Mali", "Niger", NA)
  cols$Q48 <- c("Niger", NA, NA, NA)
  cols$Q72 <- c("Cheapest", "Safest", "Cheapest", "Cheapest")
  cols[["Q72/Cheapest"]] <- c("Cheapest", NA, "Cheapest", "Cheapest")
  cols[["Q72/Safest"]] <- c(NA, "Safest", NA, NA)
  cols$QN8 <- c("Economic reasons", NA, NA, NA)
  cols[["QN8/Economic reasons"]] <- c("Economic reasons", NA, NA, NA)

  # Stops: country, place, reasons (parent and two children) per slot
  stop_slots <- list(
    c("Q56", "Q57", "Q58"),
    c("Q59", "Q60", "Q61"),
    c("Q62", "Q63", "Q64"),
    c("Q65", "Q66", "Q67"),
    c("Q68", "Q69", "Q70")
  )
  for (s in stop_slots) {
    cols[[s[1]]] <- na
    cols[[s[2]]] <- na
    cols[[s[3]]] <- na
    cols[[paste0(s[3], "/Work")]] <- na
    cols[[paste0(s[3], "/Rest/sleep")]] <- na
  }
  cols$Q56 <- c("Mali", "Mali", "Niger", NA)
  cols$Q57 <- c("Gao", "Gao", "Agadez", NA)
  cols$Q58 <- c("Work", "Rest/sleep", "Work", NA)
  cols[["Q58/Work"]] <- c("Work", NA, "Work", NA)
  cols[["Q58/Rest/sleep"]] <- c(NA, "Rest/sleep", NA, NA)

  cols$Q59 <- c("Mali", NA, "None", NA)
  cols$Q60 <- c("Bamako", NA, NA, NA)
  cols$Q61 <- c("Work Rest/sleep", NA, NA, NA)
  cols[["Q61/Work"]] <- c("Work", NA, NA, NA)
  cols[["Q61/Rest/sleep"]] <- c("Rest/sleep", NA, NA, NA)

  cols$Q62 <- c("Niger", NA, NA, NA)
  cols$Q63 <- c("Agadez", NA, NA, NA)
  cols$Q64 <- c("Rest/sleep", NA, NA, NA)
  cols[["Q64/Rest/sleep"]] <- c("Rest/sleep", NA, NA, NA)

  # Dangerous locations
  danger_slots <- list(
    c("Q98", "Q99", "Q100", "Q101"),
    c("Q102", "Q103", "Q104", "Q105"),
    c("Q106", "Q107", "Q108", "Q109"),
    c("Q110", "Q111", "Q112", "Q113"),
    c("Q114", "Q115", "Q116", "Q117")
  )
  for (s in danger_slots) {
    for (q in s) {
      cols[[q]] <- na
    }
    cols[[paste0(s[3], "/Physical violence")]] <- na
    cols[[paste0(s[3], "/None")]] <- na
    cols[[paste0(s[4], "/Armed groups/militias")]] <- na
    cols[[paste0(s[4], "/Smugglers")]] <- na
  }
  cols$Q98 <- c("Libya", "Libya", NA, NA)
  cols$Q99 <- c("Sabha", "Kufra", NA, NA)
  cols$Q100 <- c("Physical violence", "None", NA, NA)
  cols[["Q100/Physical violence"]] <- c("Physical violence", NA, NA, NA)
  cols[["Q100/None"]] <- c(NA, "None", NA, NA)
  cols$Q101 <- c("Armed groups/militias", NA, NA, NA)
  cols[["Q101/Armed groups/militias"]] <- c("Armed groups/militias", NA, NA, NA)

  as.data.frame(cols, check.names = FALSE, stringsAsFactors = FALSE)
}

fixture_route_dataset <- function() {
  body <- route_fixture_body()
  label_row <- as.data.frame(
    as.list(stats::setNames(names(body), names(body))),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  label_row$Q72 <- "Why did you take this route? (label row)"
  out <- rbind(label_row, body)
  rownames(out) <- NULL
  out
}

# The smallest spec run_route_analysis() reads.
route_spec <- function(
  ...,
  group_variables = "Overall",
  rename_map = character(0)
) {
  list(
    settings = list(...),
    group_variables = group_variables,
    rename_map = rename_map
  )
}

# One cell of the route result.
route_cell <- function(
  res,
  block,
  variable,
  choice,
  country = NA,
  location = NA,
  group_var = NA,
  group_var_value = NA
) {
  hit <- res$block == block &
    res$variable == variable &
    res$choice == choice &
    (if (is.na(country)) is.na(res$country) else res$country %in% country) &
    (if (is.na(location)) is.na(res$location) else res$location %in% location) &
    (if (is.na(group_var)) {
      is.na(res$group_var)
    } else {
      res$group_var %in% group_var
    }) &
    (if (is.na(group_var_value)) {
      is.na(res$group_var_value)
    } else {
      res$group_var_value %in% group_var_value
    })
  res[which(hit), , drop = FALSE]
}
