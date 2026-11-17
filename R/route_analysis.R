# Route analysis
#
# 4Mi asks the same follow-up questions about several countries and places on
# a respondent's route: up to eight transit countries, five stops, five most
# dangerous locations. Analysed slot by slot ("first stop", "second stop") the
# numbers mean little. The route analysis pools the slots instead: which
# countries and places were mentioned most across all of them, and, within
# each, why people stopped or what happened there.
#
# The slots are reshaped to a long table in memory - never saved - collapsed
# to one row per respondent and unit (country, or country and place), and the
# collapsed tables are analysed with the fast engine. Every percentage is of
# respondents: a respondent who gave the same reason at two stops in one
# country counts once for that country.

#' The Question Blocks of the Route Analysis
#'
#' The exact 4Mi question names behind each route block. One row of `slots`
#' per repeat of the block; `follow_ups` name the select_multiple questions
#' asked about each slot, and `respondent_follow_ups` the select_multiple
#' questions asked once per respondent about the route as a whole. `sheet` is
#' the name of the results sheet the block is written to.
#'
#' @return A named list, one element per block, in the order the blocks are
#'   written: `transit_country`, `places_stop`, `dangerous_location`.
#' @keywords internal
ck_route_blocks <- function() {
  list(
    transit_country = list(
      title = "Transit countries",
      sheet = "transit-countries",
      country_label = "Countries transited",
      location_label = NA_character_,
      slots = data.frame(
        country = paste0("Q", 47:54),
        stringsAsFactors = FALSE
      ),
      follow_ups = character(0),
      follow_up_labels = character(0),
      respondent_follow_ups = c("Q72", "QN8"),
      respondent_follow_up_labels = c(
        Q72 = "Why did you take this route?",
        QN8 = paste0(
          "What motivated you to continue onwards, rather than remain in any ",
          "of the countries you passed through so far?"
        )
      )
    ),
    places_stop = list(
      title = "Places stopped",
      sheet = "places-stop",
      country_label = "Countries stopped in",
      location_label = "Places stopped in",
      slots = data.frame(
        country = c("Q56", "Q59", "Q62", "Q65", "Q68"),
        location = c("Q57", "Q60", "Q63", "Q66", "Q69"),
        stop_reason = c("Q58", "Q61", "Q64", "Q67", "Q70"),
        stringsAsFactors = FALSE
      ),
      follow_ups = "stop_reason",
      follow_up_labels = c(
        stop_reason = "Why did you stop in this city/place?"
      ),
      respondent_follow_ups = character(0),
      respondent_follow_up_labels = character(0)
    ),
    dangerous_location = list(
      title = "Most dangerous locations",
      sheet = "dangerous-locations",
      country_label = "Most dangerous countries",
      location_label = "Most dangerous locations in",
      slots = data.frame(
        country = c("Q98", "Q102", "Q106", "Q110", "Q114"),
        location = c("Q99", "Q103", "Q107", "Q111", "Q115"),
        incident = c("Q100", "Q104", "Q108", "Q112", "Q116"),
        perpetrator = c("Q101", "Q105", "Q109", "Q113", "Q117"),
        stringsAsFactors = FALSE
      ),
      follow_ups = c("incident", "perpetrator"),
      follow_up_labels = c(
        incident = "Did you witness or experience any incidents?",
        perpetrator = "Who were the main perpetrators?"
      ),
      respondent_follow_ups = character(0),
      respondent_follow_up_labels = character(0)
    )
  )
}


#' The Route Analysis Settings
#'
#' Read by [run_analysis_spec()] and [run_route_analysis()], never passed to
#' `run_group_analysis_pipeline()`.
#'
#' @return A character vector of setting names.
#' @keywords internal
loa_route_settings <- function() {
  c(
    names(ck_route_blocks()),
    "route_gender_var",
    "route_top_locations"
  )
}


#' Which Route Blocks a Specification Asks For
#'
#' @param settings The `settings` element of an `analysis_spec`.
#' @return The names of the enabled blocks, possibly empty.
#' @keywords internal
ck_route_enabled <- function(settings) {
  blocks <- names(ck_route_blocks())
  blocks[vapply(blocks, function(b) isTRUE(settings[[b]]), logical(1))]
}


#' Every Dataset Column a Route Block Reads
#'
#' @param blocks Block names.
#' @return The question names: countries, locations, follow-ups.
#' @keywords internal
ck_route_columns <- function(blocks) {
  defs <- ck_route_blocks()[blocks]
  unique(unlist(
    lapply(defs, function(d) c(unlist(d$slots), d$respondent_follow_ups)),
    use.names = FALSE
  ))
}


#' Run the Route Analysis
#'
#' Pools the repeated country and place questions of 4Mi - transit countries
#' (Q47-Q54, with Q72 and QN8), places stopped (Q56-Q70) and most dangerous
#' locations (Q98-Q117) - and analyses them across all slots. Turned on per
#' block by the `transit_country`, `places_stop` and `dangerous_location`
#' settings; [run_analysis_spec()] calls this when any of them is `TRUE`.
#'
#' For each block the result has an overall section, then one section per
#' country (most respondents first) and, for stops and dangerous locations,
#' one per place within the country (the `route_top_locations` places with the
#' most respondents). Every table is repeated for the gender variable
#' (`route_gender_var`, default `Q27`) and for every grouping variable of the
#' `group_analysis` sheet.
#'
#' Percentages are of respondents. A respondent counts once per country or
#' place however many slots name it, and a choice counts as selected there if
#' it was selected in any of those slots. Weights come from `weight_column`.
#'
#' @param dataset The dataset, with the ONA label row still on top (as for
#'   [run_analysis_spec()]).
#' @param spec An `analysis_spec` from [build_analysis_spec()].
#' @param blocks The blocks to run. Defaults to those the settings turn on.
#' @param verbose Logical. Print progress. Default `TRUE`.
#' @return A data frame, one row per cell, with `block`, `block_title`,
#'   `section` (writing order), `level` (`overall`, `country`, `location`),
#'   `country`, `location`, `unit_n`, `variable`, `variable_label`,
#'   `group_var` (`NA` for the undisaggregated table), `group_var_value`,
#'   `choice`, `stat`, `n`, `n_total`, `n_w` and `n_w_total`. `NULL` when no
#'   block is enabled or none could run.
#' @export
run_route_analysis <- function(
  dataset,
  spec,
  blocks = ck_route_enabled(spec$settings),
  verbose = TRUE
) {
  if (length(blocks) == 0) {
    return(NULL)
  }
  unknown <- setdiff(blocks, names(ck_route_blocks()))
  if (length(unknown) > 0) {
    stop(
      paste0(
        "Unknown route block(s): ",
        paste(unknown, collapse = ", "),
        ". Use transit_country, places_stop or dangerous_location."
      ),
      call. = FALSE
    )
  }

  settings <- spec$settings
  sm_separator <- settings$sm_separator %||% "/"
  top_n <- settings$route_top_locations %||% 4
  if (
    length(top_n) != 1 || is.na(top_n) || top_n < 1 || top_n != round(top_n)
  ) {
    stop(
      "route_top_locations must be a whole number of 1 or more.",
      call. = FALSE
    )
  }

  split <- ck_split_label_row(
    as.data.frame(dataset, stringsAsFactors = FALSE),
    skip_label_row = settings$skip_label_row %||% TRUE
  )
  data <- split$dataset
  label_row <- split$label_row
  rownames(data) <- NULL

  # Grouping variables use the names the group_analysis sheet gave them.
  rename_map <- spec$rename_map %||% character(0)
  data <- apply_rename_map(data, rename_map, sm_separator)
  if (!is.null(label_row)) {
    label_row <- apply_rename_map(label_row, rename_map, sm_separator)
  }

  gender_var <- loa_rename_values(
    settings$route_gender_var %||% "Q27",
    rename_map
  )
  group_vars <- unique(c(
    gender_var,
    setdiff(spec$group_variables %||% character(0), "Overall")
  ))
  absent <- setdiff(group_vars, names(data))
  if (length(absent) > 0) {
    ck_warn(
      "Route analysis: grouping variable(s) not in the dataset and skipped: ",
      paste(absent, collapse = ", "),
      "."
    )
    group_vars <- setdiff(group_vars, absent)
  }

  weight_column <- settings$weight_column
  if (!is.null(weight_column) && !weight_column %in% names(data)) {
    weight_column <- NULL
  }

  out <- list()
  for (b in blocks) {
    def <- ck_route_blocks()[[b]]
    res <- ck_route_block(
      data = data,
      def = def,
      block = b,
      group_vars = group_vars,
      weight_column = weight_column,
      sm_separator = sm_separator,
      top_n = top_n,
      label_row = label_row
    )
    if (!is.null(res)) {
      ck_note(
        "route analysis '",
        b,
        "': ",
        length(unique(res$section)),
        " section(s)",
        verbose = verbose
      )
      out[[b]] <- res
    }
  }

  if (length(out) == 0) {
    return(NULL)
  }
  out <- dplyr::bind_rows(out)
  rownames(out) <- NULL
  out
}


#' Clean a Text Column for the Route Analysis
#'
#' @param x A vector.
#' @return Trimmed character, blanks and `"NA"` as `NA`.
#' @keywords internal
ck_route_text <- function(x) {
  x <- trimws(as.character(x))
  x[!is.na(x) & (x == "" | x == "NA")] <- NA_character_
  x
}


#' A Country or Place Answer That Names No Place
#'
#' "None", "Refused", "Don't know" and the like. Such a slot is not a stop or
#' a dangerous location, so it is left out of the rankings and gets no section.
#'
#' @param x Character vector from [ck_route_text()].
#' @return The vector with non-answers set to `NA`.
#' @keywords internal
ck_route_place <- function(x) {
  x <- ck_route_text(x)
  non_answer <- grepl(
    "^(none|aucun|refus|don.?t know|do not know|prefer not|not applicable|n/?a$)",
    x,
    ignore.case = TRUE
  )
  x[non_answer] <- NA_character_
  x
}


#' Code One Select_Multiple Question as 0/1/NA
#'
#' @param data The dataset, label row removed.
#' @param parent The parent question.
#' @param sm_separator The select_multiple separator.
#' @return A numeric matrix, one column per choice (named by the choice), `NA`
#'   in rows that were not asked; `NULL` when the question has no children.
#' @keywords internal
ck_route_sm <- function(data, parent, sm_separator) {
  m <- ck_sm_selection_matrix(data, parent, sm_separator)
  if (is.null(m)) {
    return(NULL)
  }
  any_selected <- rowSums(m$selected) > 0
  asked <- any_selected
  if (parent %in% names(data)) {
    asked <- asked | !is.na(ck_route_text(data[[parent]]))
  }
  x <- matrix(
    as.numeric(m$selected),
    nrow = nrow(m$selected),
    dimnames = list(NULL, unname(m$suffixes))
  )
  x[!asked, ] <- NA_real_
  # Two children with the same label after trimming are one choice.
  if (anyDuplicated(colnames(x))) {
    x <- ck_route_merge_columns(x)
  }
  x
}


#' Merge Matrix Columns That Share a Name
#'
#' A choice counts as selected when any of its columns is.
#'
#' @param x A numeric 0/1/NA matrix.
#' @return The matrix with one column per distinct name.
#' @keywords internal
ck_route_merge_columns <- function(x) {
  nm <- unique(colnames(x))
  out <- matrix(
    NA_real_,
    nrow = nrow(x),
    ncol = length(nm),
    dimnames = list(NULL, nm)
  )
  for (k in nm) {
    cols <- x[, colnames(x) == k, drop = FALSE]
    asked <- rowSums(!is.na(cols)) > 0
    sel <- rowSums(cols == 1, na.rm = TRUE) > 0
    out[, k] <- ifelse(asked, as.numeric(sel), NA_real_)
  }
  out
}


#' Pool 0/1/NA Columns Within a Key
#'
#' @param x A numeric 0/1/NA matrix, one row per slot.
#' @param key The unit each slot belongs to.
#' @return One row per distinct key, in order of first appearance: 1 if
#'   selected in any slot, 0 if asked but never selected, `NA` if never asked.
#' @keywords internal
ck_route_pool <- function(x, key) {
  if (ncol(x) == 0) {
    return(x[!duplicated(key), , drop = FALSE])
  }
  sel <- rowsum((!is.na(x) & x == 1) * 1, key, reorder = FALSE)
  asked <- rowsum((!is.na(x)) * 1, key, reorder = FALSE)
  out <- ifelse(asked > 0, (sel > 0) * 1, NA_real_)
  dimnames(out) <- list(NULL, colnames(x))
  out
}


#' Rank the Countries or Places Respondents Named
#'
#' The share of respondents in a unit who named each value in at least one
#' slot. Counted directly rather than through one-hot columns, which on a full
#' 4Mi round would mean a column for every place in every country.
#'
#' @param id The respondent of each slot.
#' @param unit The unit each slot is ranked within (`"Overall"`, or the
#'   country).
#' @param value The country or place the slot names; `NA` is left out of both
#'   numerator and denominator.
#' @param variable The variable name to report.
#' @param w Respondent weights.
#' @param groups Named list of respondent-level disaggregation values.
#' @return Rows in the shape of [ck_route_analyse()].
#' @keywords internal
ck_route_rank <- function(id, unit, value, variable, w, groups) {
  ok <- !is.na(value)
  if (!any(ok)) {
    return(ck_route_empty())
  }
  sep <- "\u001f"
  trip <- data.frame(id = id[ok], unit = unit[ok], value = value[ok])
  trip <- trip[!duplicated(paste(trip$id, trip$unit, trip$value, sep = sep)), ]
  den <- trip[!duplicated(paste(trip$id, trip$unit, sep = sep)), ]

  one <- function(g_name, g_vals) {
    gv_den <- if (is.null(g_vals)) NULL else g_vals[den$id]
    gv_num <- if (is.null(g_vals)) NULL else g_vals[trip$id]
    d_ok <- if (is.null(gv_den)) rep(TRUE, nrow(den)) else !is.na(gv_den)
    n_ok <- if (is.null(gv_num)) rep(TRUE, nrow(trip)) else !is.na(gv_num)
    if (!any(n_ok)) {
      return(NULL)
    }
    d_key <- paste(den$unit, gv_den %||% "", sep = sep)[d_ok]
    d_n <- rowsum(rep(1, sum(d_ok)), d_key)
    d_w <- rowsum(w[den$id][d_ok], d_key)

    u_key <- paste(trip$unit, gv_num %||% "", sep = sep)[n_ok]
    n_key <- paste(u_key, trip$value[n_ok], sep = sep)
    n_n <- rowsum(rep(1, sum(n_ok)), n_key)
    n_w <- rowsum(w[trip$id][n_ok], n_key)

    first <- !duplicated(n_key)
    keys <- rownames(n_n)
    pos <- match(keys, n_key[first])
    u <- u_key[first][pos]
    data.frame(
      unit = trip$unit[n_ok][first][pos],
      variable = variable,
      group_var = if (is.null(g_name)) NA_character_ else g_name,
      group_var_value = if (is.null(gv_num)) {
        NA_character_
      } else {
        gv_num[n_ok][first][pos]
      },
      choice = trip$value[n_ok][first][pos],
      stat = n_w[keys, 1] / d_w[u, 1],
      n = n_n[keys, 1],
      n_total = d_n[u, 1],
      n_w = n_w[keys, 1],
      n_w_total = d_w[u, 1],
      stringsAsFactors = FALSE
    )
  }

  parts <- c(
    list(one(NULL, NULL)),
    lapply(names(groups), function(g) one(g, groups[[g]]))
  )
  out <- dplyr::bind_rows(parts)
  rownames(out) <- NULL
  out
}


#' Analyse One Route Block
#'
#' @param data The dataset, label row removed and grouping variables renamed.
#' @param def The block definition from [ck_route_blocks()].
#' @param block The block name.
#' @param group_vars Disaggregation variables.
#' @param weight_column Weights column, or `NULL`.
#' @param sm_separator The select_multiple separator.
#' @param top_n Places per country that get a section of their own.
#' @param label_row The ONA label row, or `NULL`.
#' @return The block's rows of the [run_route_analysis()] result, or `NULL`.
#' @keywords internal
ck_route_block <- function(
  data,
  def,
  block,
  group_vars,
  weight_column,
  sm_separator,
  top_n,
  label_row
) {
  slots <- def$slots
  has_location <- "location" %in% names(slots)

  needed <- c(slots$country, if (has_location) slots$location)
  missing_cols <- setdiff(needed, names(data))
  if (length(missing_cols) > 0) {
    ck_warn(
      "Route analysis '",
      block,
      "' skipped: the dataset has no column(s) ",
      paste(missing_cols, collapse = ", "),
      "."
    )
    return(NULL)
  }

  n_resp <- nrow(data)
  if (n_resp == 0) {
    return(NULL)
  }

  # --- 1. Slots to long --------------------------------------------------------
  # Every follow-up is coded per slot, then aligned on the union of its choices
  # so the slots stack into one table.
  fu_choices <- list()
  slot_rows <- vector("list", nrow(slots))
  for (s in seq_len(nrow(slots))) {
    country <- ck_route_place(data[[slots$country[s]]])
    location <- if (has_location) {
      ck_route_place(data[[slots$location[s]]])
    } else {
      rep(NA_character_, n_resp)
    }
    keep <- !is.na(country)
    fu <- list()
    for (f in def$follow_ups) {
      m <- ck_route_sm(data, slots[[f]][s], sm_separator)
      if (is.null(m)) {
        m <- matrix(NA_real_, nrow = n_resp, ncol = 0)
      }
      fu[[f]] <- m[keep, , drop = FALSE]
      fu_choices[[f]] <- union(fu_choices[[f]], colnames(m))
    }
    slot_rows[[s]] <- list(
      id = which(keep),
      country = country[keep],
      location = location[keep],
      fu = fu
    )
  }

  id <- unlist(lapply(slot_rows, `[[`, "id"), use.names = FALSE)
  if (length(id) == 0) {
    ck_warn("Route analysis '", block, "': no respondent answered any slot.")
    return(NULL)
  }
  country <- unlist(lapply(slot_rows, `[[`, "country"), use.names = FALSE)
  location <- unlist(lapply(slot_rows, `[[`, "location"), use.names = FALSE)

  fu_long <- list()
  for (f in def$follow_ups) {
    lv <- fu_choices[[f]] %||% character(0)
    parts <- lapply(slot_rows, function(sr) {
      m <- sr$fu[[f]]
      out <- matrix(
        NA_real_,
        nrow = length(sr$id),
        ncol = length(lv),
        dimnames = list(NULL, lv)
      )
      if (ncol(m) > 0) {
        out[, colnames(m)] <- m
      }
      out
    })
    fu_long[[f]] <- do.call(rbind, parts)
  }

  # --- 2. Respondent-level follow-ups ------------------------------------------
  resp_fu <- list()
  for (q in def$respondent_follow_ups) {
    m <- ck_route_sm(data, q, sm_separator)
    if (is.null(m)) {
      ck_warn(
        "Route analysis '",
        block,
        "': ",
        q,
        " has no select_multiple columns in the dataset and is left out."
      )
      next
    }
    resp_fu[[q]] <- m
  }

  fu_labels <- c(
    def$follow_up_labels,
    vapply(
      names(resp_fu),
      function(q) {
        ck_route_question_label(
          q,
          label_row,
          def$respondent_follow_up_labels[[q]]
        )
      },
      character(1)
    )
  )

  # --- 3. Collapse to units ----------------------------------------------------
  w <- if (is.null(weight_column)) {
    rep(1, n_resp)
  } else {
    ww <- suppressWarnings(as.numeric(data[[weight_column]]))
    ww[is.na(ww)] <- 0
    ww
  }
  groups <- lapply(stats::setNames(group_vars, group_vars), function(g) {
    ck_route_text(data[[g]])
  })

  answered <- seq_len(n_resp) %in% id

  # Respondent table: everyone, so a respondent-level follow-up keeps its own
  # denominator. The country ranking is counted separately, out of those who
  # named a country.
  resp_tab <- list(
    id = seq_len(n_resp),
    unit = rep("Overall", n_resp),
    vars = c(ck_route_expand(fu_long, id, seq_len(n_resp)), resp_fu)
  )

  # Respondent x country.
  rc_key <- paste(id, country, sep = "\u001f")
  rc_first <- !duplicated(rc_key)
  rc_tab <- list(
    id = id[rc_first],
    unit = country[rc_first],
    vars = c(
      lapply(fu_long, ck_route_pool, key = rc_key),
      lapply(resp_fu, function(m) m[id[rc_first], , drop = FALSE])
    )
  )

  # Respondent x country x place.
  rl_tab <- NULL
  if (has_location && any(!is.na(location))) {
    ok <- !is.na(location)
    rl_key <- paste(id[ok], country[ok], location[ok], sep = "\u001f")
    rl_first <- !duplicated(rl_key)
    rl_tab <- list(
      id = id[ok][rl_first],
      unit = paste(country[ok], location[ok], sep = "\u001f")[rl_first],
      vars = lapply(fu_long, function(m) {
        ck_route_pool(m[ok, , drop = FALSE], rl_key)
      })
    )
  }

  # --- 4. Analyse ----------------------------------------------------------------
  labels <- c(
    route_country = def$country_label,
    route_location = def$location_label,
    fu_labels
  )

  # Rankings first, so each section opens with them.
  overall <- dplyr::bind_rows(
    ck_route_rank(
      id,
      rep("Overall", length(id)),
      country,
      "route_country",
      w,
      groups
    ),
    ck_route_analyse(resp_tab, w, groups, sm_separator)
  )
  by_country <- dplyr::bind_rows(
    if (has_location) {
      ck_route_rank(id, country, location, "route_location", w, groups)
    },
    ck_route_analyse(rc_tab, w, groups, sm_separator)
  )
  by_place <- if (!is.null(rl_tab)) {
    ck_route_analyse(rl_tab, w, groups, sm_separator)
  }

  # --- 5. Order the sections -----------------------------------------------------
  # Countries by respondents naming them, places by respondents naming them
  # within the country; ties alphabetically.
  rank_tab <- function(res, var) {
    r <- res[res$variable == var & is.na(res$group_var), , drop = FALSE]
    r <- r[order(-r$n, r$choice), , drop = FALSE]
    r[r$n > 0, , drop = FALSE]
  }

  countries <- rank_tab(overall, "route_country")
  unit_n_overall <- sum(answered)

  sections <- list(
    ck_route_section(
      overall,
      "overall",
      NA_character_,
      NA_character_,
      unit_n_overall
    )
  )
  for (cc in countries$choice) {
    sec <- by_country[by_country$unit == cc, , drop = FALSE]
    sections[[length(sections) + 1]] <- ck_route_section(
      sec,
      "country",
      cc,
      NA_character_,
      countries$n[countries$choice == cc]
    )
    if (is.null(by_place)) {
      next
    }
    places <- rank_tab(sec, "route_location")
    for (pl in utils::head(places$choice, top_n)) {
      psec <- by_place[
        by_place$unit == paste(cc, pl, sep = "\u001f"),
        ,
        drop = FALSE
      ]
      sections[[length(sections) + 1]] <- ck_route_section(
        psec,
        "location",
        cc,
        pl,
        places$n[places$choice == pl]
      )
    }
  }

  out <- dplyr::bind_rows(lapply(seq_along(sections), function(i) {
    s <- sections[[i]]
    if (nrow(s) == 0) {
      return(NULL)
    }
    s$section <- i
    s
  }))
  if (is.null(out) || nrow(out) == 0) {
    return(NULL)
  }

  out$block <- block
  out$block_title <- def$title
  out$variable_label <- unname(labels[out$variable])
  out$variable_label[is.na(out$variable_label)] <- out$variable[is.na(
    out$variable_label
  )]

  out[, c(
    "block",
    "block_title",
    "section",
    "level",
    "country",
    "location",
    "unit_n",
    "variable",
    "variable_label",
    "group_var",
    "group_var_value",
    "choice",
    "stat",
    "n",
    "n_total",
    "n_w",
    "n_w_total"
  )]
}


#' A Question's Label From the ONA Label Row
#'
#' @param q The question name.
#' @param label_row The label row, or `NULL`.
#' @param fallback Used when the label row has no text for `q`.
#' @return A single string.
#' @keywords internal
ck_route_question_label <- function(q, label_row, fallback = NULL) {
  if (!is.null(label_row) && q %in% names(label_row)) {
    lab <- ck_route_text(label_row[[q]][1])
    if (!is.na(lab) && !identical(lab, q)) {
      return(lab)
    }
  }
  fallback %||% q
}


#' Spread Slot Rows Onto Respondents
#'
#' @param fu_long Named list of slot-level 0/1/NA matrices.
#' @param id The respondent of each slot.
#' @param ids Every respondent.
#' @return The matrices pooled to one row per element of `ids`.
#' @keywords internal
ck_route_expand <- function(fu_long, id, ids) {
  lapply(fu_long, function(m) {
    pooled <- ck_route_pool(m, id)
    first <- unique(id)
    out <- matrix(
      NA_real_,
      nrow = length(ids),
      ncol = ncol(m),
      dimnames = list(NULL, colnames(m))
    )
    out[match(first, ids), ] <- pooled
    out
  })
}


#' Run the Fast Engine Over One Collapsed Route Table
#'
#' Builds the derived dataset - select_multiple children named
#' `<variable>/<choice>`, the unit, and one unit-by-group column per
#' disaggregation variable - and analyses every variable for the unit and for
#' each unit-by-group cell in one call to [ck_fast_analysis()].
#'
#' @param tab A list with `id`, `unit` and `vars` (named list of 0/1/NA
#'   matrices, one row per element of `id`).
#' @param w Respondent weights.
#' @param groups Named list of respondent-level disaggregation values.
#' @param sm_separator Unused in the derived data, which always uses `/`;
#'   kept so the signature mirrors the engine's.
#' @return Long results with `unit`, `variable`, `group_var`,
#'   `group_var_value`, `choice` and the statistic columns.
#' @keywords internal
ck_route_analyse <- function(tab, w, groups, sm_separator = "/") {
  vars <- tab$vars[vapply(
    tab$vars,
    function(m) !is.null(m) && ncol(m) > 0,
    logical(1)
  )]
  if (length(vars) == 0 || length(tab$id) == 0) {
    return(ck_route_empty())
  }
  sep <- "\u001f"

  cols <- list(route_unit = tab$unit, route_weight = w[tab$id])
  g_cols <- character(0)
  for (g in names(groups)) {
    gv <- groups[[g]][tab$id]
    nm <- paste0("route_unit__", length(g_cols) + 1L)
    cols[[nm]] <- ifelse(
      is.na(gv),
      NA_character_,
      paste(tab$unit, gv, sep = sep)
    )
    g_cols[[g]] <- nm
  }
  derived <- as.data.frame(cols, stringsAsFactors = FALSE, check.names = FALSE)
  var_names <- character(0)
  for (v in names(vars)) {
    m <- vars[[v]]
    vn <- paste0("v", length(var_names) + 1L)
    var_names[[vn]] <- v
    child <- as.data.frame(m, check.names = FALSE)
    names(child) <- paste0(vn, "/", colnames(m))
    derived <- cbind(derived, child)
  }

  loa <- expand.grid(
    analysis_var = names(var_names),
    group_var = c("route_unit", unname(g_cols)),
    stringsAsFactors = FALSE
  )
  loa$analysis_type <- "prop_select_multiple"

  res <- ck_fast_analysis(
    derived,
    loa,
    weight_column = "route_weight",
    sm_separator = "/",
    keep_missing_groups = FALSE,
    verbose = FALSE
  )
  if (is.null(res) || nrow(res) == 0) {
    return(ck_route_empty())
  }
  res <- res[!is.na(res$group_var_value), , drop = FALSE]

  is_g <- res$group_var != "route_unit"
  parts <- strsplit(res$group_var_value, sep, fixed = TRUE)
  # The unit itself may contain the separator (country and place), so the group
  # value is the last piece and the unit everything before it.
  unit <- ifelse(
    is_g,
    vapply(
      parts,
      function(p) paste(utils::head(p, -1), collapse = sep),
      character(1)
    ),
    res$group_var_value
  )
  gval <- ifelse(
    is_g,
    vapply(parts, function(p) utils::tail(p, 1), character(1)),
    NA_character_
  )

  data.frame(
    unit = unit,
    variable = unname(var_names[res$analysis_var]),
    group_var = ifelse(
      is_g,
      names(g_cols)[match(res$group_var, g_cols)],
      NA_character_
    ),
    group_var_value = gval,
    choice = res$analysis_var_value,
    stat = res$stat,
    n = res$n,
    n_total = res$n_total,
    n_w = res$n_w,
    n_w_total = res$n_w_total,
    stringsAsFactors = FALSE
  )
}


#' An Empty Route Result
#' @return A zero-row data frame with the columns of [ck_route_analyse()].
#' @keywords internal
ck_route_empty <- function() {
  data.frame(
    unit = character(0),
    variable = character(0),
    group_var = character(0),
    group_var_value = character(0),
    choice = character(0),
    stat = numeric(0),
    n = numeric(0),
    n_total = numeric(0),
    n_w = numeric(0),
    n_w_total = numeric(0),
    stringsAsFactors = FALSE
  )
}


#' Label One Section of a Route Block
#'
#' Drops choices nobody in the unit selected and orders the rest by
#' percentage, largest first.
#'
#' @param res Rows of [ck_route_analyse()] for one unit.
#' @param level `overall`, `country` or `location`.
#' @param country,location The unit.
#' @param unit_n Respondents in the unit.
#' @return The section's rows.
#' @keywords internal
ck_route_section <- function(res, level, country, location, unit_n) {
  if (nrow(res) == 0) {
    return(res)
  }
  main <- res[is.na(res$group_var), , drop = FALSE]
  shown <- paste(main$variable, main$choice)[main$n > 0]
  res <- res[paste(res$variable, res$choice) %in% shown, , drop = FALSE]

  # Choice order is the undisaggregated table's, applied to every table of the
  # variable so the disaggregations read row for row against it.
  main <- res[is.na(res$group_var), , drop = FALSE]
  main <- main[
    order(main$variable, -main$stat, -main$n, main$choice),
    ,
    drop = FALSE
  ]
  rank <- paste(main$variable, main$choice)
  res <- res[
    order(
      match(res$variable, unique(res$variable)),
      match(paste(res$variable, res$choice), rank)
    ),
    ,
    drop = FALSE
  ]

  res$level <- level
  res$country <- country
  res$location <- location
  res$unit_n <- unit_n
  res$unit <- NULL
  res
}


#' Write a Route Analysis Sheet
#'
#' Writes the rows it is given to one sheet, top to bottom: a band per block
#' (the formatter passes one block per sheet), then its sections in order -
#' overall, each country (most respondents first) and, under each country, its
#' top places. Each section lists its tables; each table is followed directly
#' by its disaggregations, one per grouping variable, with the groups side by
#' side (percentages first, then counts).
#'
#' @param wb An `openxlsx` workbook.
#' @param sheet Sheet name.
#' @param route The data frame from [run_route_analysis()].
#' @param pal The MMC palette.
#' @param font_name Font used throughout.
#' @param pct_fmt Excel number format for percentages.
#' @return `NULL`, invisibly. Called for its effect on `wb`.
#' @keywords internal
ck_write_route_sheet <- function(
  wb,
  sheet,
  route,
  pal,
  font_name,
  pct_fmt = "0%"
) {
  route <- as.data.frame(route, stringsAsFactors = FALSE)
  openxlsx::addWorksheet(
    wb,
    sheetName = sheet,
    tabColour = pal[["teal"]],
    gridLines = FALSE
  )

  dis <- route[!is.na(route$group_var), , drop = FALSE]
  k_max <- if (nrow(dis) > 0) {
    max(tapply(
      dis$group_var_value,
      paste(dis$block, dis$section, dis$variable, dis$group_var),
      function(v) length(unique(v))
    ))
  } else {
    1L
  }
  n_cols <- max(4L, 1L + 2L * as.integer(k_max))

  sg <- ck_new_style_grid()
  base <- function(...) {
    ck_style(
      sg,
      fontName = font_name,
      fontSize = 10,
      fontColour = pal[["navy"]],
      ...
    )
  }
  head_args <- list(
    fgFill = pal[["pale_blue"]],
    textDecoration = "bold",
    border = "Bottom",
    borderColour = pal[["navy"]],
    wrapText = TRUE,
    valign = "center"
  )
  st <- list(
    note = base(textDecoration = "italic"),
    block = ck_band_style(sg, pal, font_name, 13, pal[["navy"]], "left"),
    unit = ck_band_style(sg, pal, font_name, 11, pal[["teal"]], "left"),
    place = base(fgFill = pal[["light_blue"]], textDecoration = "bold"),
    title = base(textDecoration = "bold"),
    sub = base(textDecoration = "italic"),
    head_left = do.call(base, head_args),
    head = do.call(base, c(head_args, list(halign = "center"))),
    label = base(),
    pct = base(numFmt = pct_fmt, halign = "center"),
    num = base(numFmt = "0", halign = "center")
  )

  put_row <- function(values, r) {
    openxlsx::writeData(
      wb,
      sheet,
      x = matrix(values, nrow = 1),
      startRow = r,
      startCol = 1L,
      colNames = FALSE
    )
  }
  put_table <- function(df, r) {
    openxlsx::writeData(
      wb,
      sheet,
      x = df,
      startRow = r,
      startCol = 1L,
      colNames = FALSE
    )
  }

  row <- 1L
  put_row(
    paste0(
      "Percentages are of respondents. A respondent counts once per country ",
      "or place, however many route slots name it; a choice counts as ",
      "selected there if it was selected in any of those slots."
    ),
    row
  )
  ck_add_rect(sg, st$note, row, 1L)
  row <- row + 2L

  for (b in unique(route$block)) {
    rb <- route[route$block == b, , drop = FALSE]
    put_row(toupper(rb$block_title[1]), row)
    ck_add_rect(sg, st$block, row, seq_len(n_cols))
    row <- row + 2L

    for (s in sort(unique(rb$section))) {
      rs <- rb[rb$section == s, , drop = FALSE]
      level <- rs$level[1]
      unit_label <- switch(
        level,
        overall = "Overall",
        country = rs$country[1],
        location = paste0(rs$country[1], " > ", rs$location[1])
      )
      put_row(paste0(unit_label, " (n=", rs$unit_n[1], ")"), row)
      ck_add_rect(
        sg,
        if (level == "location") st$place else st$unit,
        row,
        seq_len(n_cols)
      )
      row <- row + 2L

      for (v in unique(rs$variable)) {
        rv <- rs[rs$variable == v, , drop = FALSE]
        main <- rv[is.na(rv$group_var), , drop = FALSE]
        if (nrow(main) == 0) {
          next
        }
        title <- main$variable_label[1]
        if (identical(v, "route_location")) {
          title <- paste(title, rs$country[1])
        }

        put_row(title, row)
        ck_add_rect(sg, st$title, row, 1L)
        row <- row + 1L
        put_row(c("Category", "%", "n", "n_total"), row)
        ck_add_rect(sg, st$head_left, row, 1L)
        ck_add_rect(sg, st$head, row, 2:4)
        row <- row + 1L
        put_table(
          data.frame(
            choice = main$choice,
            stat = main$stat,
            n = main$n,
            n_total = main$n_total,
            stringsAsFactors = FALSE
          ),
          row
        )
        rows <- row + seq_len(nrow(main)) - 1L
        ck_add_rect(sg, st$label, rows, 1L)
        ck_add_rect(sg, st$pct, rows, 2L)
        ck_add_rect(sg, st$num, rows, 3:4)
        row <- row + nrow(main) + 1L

        for (g in unique(stats::na.omit(rv$group_var))) {
          rg <- rv[!is.na(rv$group_var) & rv$group_var == g, , drop = FALSE]
          # Largest group first, judged by its denominator for this question.
          sizes <- tapply(rg$n_total, rg$group_var_value, max)
          lv <- names(sort(sizes, decreasing = TRUE))
          k <- length(lv)
          key <- function(choice, value) paste(choice, value, sep = "\u001f")
          idx <- match(
            key(rep(main$choice, times = k), rep(lv, each = nrow(main))),
            key(rg$choice, rg$group_var_value)
          )
          pct <- matrix(rg$stat[idx], nrow = nrow(main))
          cnt <- matrix(rg$n[idx], nrow = nrow(main))
          # A missing cell is a group in which nobody gave that answer.
          pct[is.na(idx)] <- 0
          cnt[is.na(cnt)] <- 0

          put_row(paste0("By ", g), row)
          ck_add_rect(sg, st$sub, row, 1L)
          row <- row + 1L
          put_row(
            c(
              "Category",
              paste0(lv, " (n=", sizes[lv], ") %"),
              paste0(lv, " n")
            ),
            row
          )
          ck_add_rect(sg, st$head_left, row, 1L)
          ck_add_rect(sg, st$head, row, 1L + seq_len(2L * k))
          row <- row + 1L

          tab <- data.frame(choice = main$choice, stringsAsFactors = FALSE)
          for (j in seq_len(k)) {
            tab[[paste0("p", j)]] <- pct[, j]
          }
          for (j in seq_len(k)) {
            tab[[paste0("n", j)]] <- cnt[, j]
          }
          put_table(tab, row)
          rows <- row + seq_len(nrow(main)) - 1L
          ck_add_rect(sg, st$label, rows, 1L)
          ck_add_rect(sg, st$pct, rows, 1L + seq_len(k))
          ck_add_rect(sg, st$num, rows, 1L + k + seq_len(k))
          row <- row + nrow(main) + 1L
        }
        row <- row + 1L
      }
      row <- row + 1L
    }
    row <- row + 1L
  }

  ck_flush_styles(sg, wb, sheet)
  openxlsx::setColWidths(wb, sheet, cols = 1L, widths = 55)
  openxlsx::setColWidths(wb, sheet, cols = 2:n_cols, widths = 14)

  invisible(NULL)
}
