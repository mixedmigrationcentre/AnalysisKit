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
#' questions asked once per respondent about the route as a whole;
#' `respondent_full_sample` are those of them asked of everyone, which
#' `route_full_sample_base` reports out of the full sample. `sheet` is the
#' name of the results sheet the block is written to.
#'
#' @return A named list, one element per block, in the order the blocks are
#'   written: `transit_country`, `places_stop`, `dangerous_location`.
#' @keywords internal
ck_route_blocks <- function() {
  list(
    transit_country = list(
      title = "Transit countries",
      sheet = "Transit Countries",
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
      ),
      # Asked of everyone, so out of the full sample under
      # route_full_sample_base. QN8 is not: it was skipped for anyone whose
      # first transit country was None or Refused.
      respondent_full_sample = "Q72"
    ),
    places_stop = list(
      title = "Places stopped",
      sheet = "Places Stop",
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
      respondent_follow_up_labels = character(0),
      respondent_full_sample = character(0)
    ),
    dangerous_location = list(
      title = "Most dangerous locations",
      sheet = "Dangerous Locations",
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
      respondent_follow_up_labels = character(0),
      respondent_full_sample = character(0)
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
    "route_top_countries",
    "route_top_locations",
    "route_full_sample_base"
  )
}


#' The Label of the Not-Asked Row in a Full-Sample Route Question
#' @return A single string.
#' @keywords internal
ck_route_no_response_label <- function() "Not asked / no response"


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
#' country for the `route_top_countries` countries with the most respondents
#' (default 10; 0 for all) and, for stops and dangerous locations, one per
#' place within the country (the `route_top_locations` places with the most
#' respondents, default 4). The overall section, which also ranks every
#' country, is disaggregated by the gender variable (`route_gender_var`,
#' default `Q27`) and by every grouping variable of the `disaggregation_variables`
#' sheet; the country and place sections are not.
#'
#' Percentages are of respondents. A respondent counts once per country or
#' place however many slots name it, and a choice counts as selected there if
#' it was selected in any of those slots. Weights come from `weight_column`.
#'
#' **The base.** With `route_full_sample_base` `TRUE` (the default; blank or
#' absent counts as `TRUE`), the questions asked of everyone are out of the
#' full sample: the country ranking of every block is out of all respondents,
#' whether or not they named a country (None, Refused and the like are still
#' not listed), and Q72 is out of all respondents, with anyone who did not
#' answer as a `Not asked / no response` row. Every other question - QN8, the
#' reasons for stopping, the incidents, the perpetrators - is out of the
#' respondents asked it. `FALSE` puts the ranking and Q72 on that footing too.
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
#'   `choice`, `stat`, `n`, `n_total`, `n_w`, `n_w_total` and `base`
#'   (`"full_sample"` or `"answered"`). `NULL` when no block is enabled or
#'   none could run.
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
  top_countries <- settings$route_top_countries %||% 10
  if (
    length(top_countries) != 1 ||
      is.na(top_countries) ||
      top_countries < 0 ||
      top_countries != round(top_countries)
  ) {
    stop(
      "route_top_countries must be a whole number: 0 for every country, or how many to show.",
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

  # Grouping variables use the names the disaggregation_variables sheet gave them.
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

  # Blank or absent means TRUE: the full sample is the default.
  full_sample <- settings$route_full_sample_base %||% TRUE
  if (
    length(full_sample) != 1 || is.na(full_sample) || !is.logical(full_sample)
  ) {
    stop("route_full_sample_base must be TRUE or FALSE.", call. = FALSE)
  }

  out <- list()
  for (b in blocks) {
    def <- ck_route_blocks()[[b]]
    res <- ck_route_block(
      data = data,
      def = def,
      block = b,
      full_sample = full_sample,
      group_vars = group_vars,
      weight_column = weight_column,
      sm_separator = sm_separator,
      top_n = top_n,
      label_row = label_row,
      top_countries = top_countries
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
#' @param base_id The respondents of the denominator, for a ranking with a
#'   single unit (`"Overall"`); `NULL` (the default) for those who named at
#'   least one value. The full sample passes every respondent, so those who
#'   named nothing, or only None or Refused, stay in the base.
#' @return Rows in the shape of [ck_route_analyse()].
#' @keywords internal
ck_route_rank <- function(
  id,
  unit,
  value,
  variable,
  w,
  groups,
  base_id = NULL
) {
  ok <- !is.na(value)
  if (!any(ok)) {
    return(ck_route_empty())
  }
  sep <- "\u001f"
  trip <- data.frame(id = id[ok], unit = unit[ok], value = value[ok])
  trip <- trip[!duplicated(paste(trip$id, trip$unit, trip$value, sep = sep)), ]
  den <- if (is.null(base_id)) {
    trip[!duplicated(paste(trip$id, trip$unit, sep = sep)), ]
  } else {
    stopifnot(length(unique(trip$unit)) == 1)
    data.frame(id = base_id, unit = trip$unit[1], value = NA_character_)
  }

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
#' @param top_countries Countries that get a section of their own, most
#'   respondents first; `0` for all.
#' @param label_row The ONA label row, or `NULL`.
#' @param full_sample Logical. Report the country ranking and the
#'   `respondent_full_sample` questions out of every respondent (see
#'   [run_route_analysis()]). Default `TRUE`.
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
  label_row,
  top_countries = 0,
  full_sample = TRUE
) {
  full_sample_vars <- if (isTRUE(full_sample)) {
    c("route_country", def$respondent_full_sample)
  } else {
    character(0)
  }
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
    # Asked of everyone: anyone who did not answer stays in the base, as
    # not selecting any choice, and is counted in a row of their own.
    if (q %in% full_sample_vars) {
      not_asked <- rowSums(!is.na(m)) == 0
      m[is.na(m)] <- 0
      if (any(not_asked)) {
        nr <- ck_route_no_response_label()
        if (nr %in% colnames(m)) {
          m[, nr] <- pmax(m[, nr], as.numeric(not_asked))
        } else {
          m <- cbind(m, stats::setNames(as.numeric(not_asked), NULL))
          colnames(m)[ncol(m)] <- nr
        }
      }
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

  # Countries by respondents naming them, places by respondents naming them
  # within the country; ties alphabetically.
  rank_tab <- function(res, var) {
    r <- res[res$variable == var & is.na(res$group_var), , drop = FALSE]
    r <- r[order(-r$n, r$choice), , drop = FALSE]
    r[r$n > 0, , drop = FALSE]
  }

  # The overall picture is the one disaggregated; countries and places are
  # the columns of the wide tables, analysed only for the top countries.
  overall <- dplyr::bind_rows(
    ck_route_rank(
      id,
      rep("Overall", length(id)),
      country,
      "route_country",
      w,
      groups,
      base_id = if ("route_country" %in% full_sample_vars) seq_len(n_resp)
    ),
    ck_route_analyse(resp_tab, w, groups, sm_separator)
  )
  countries <- rank_tab(overall, "route_country")
  if (top_countries > 0) {
    countries <- utils::head(countries, top_countries)
  }
  unit_n_overall <- if ("route_country" %in% full_sample_vars) {
    n_resp
  } else {
    sum(answered)
  }

  shown <- country %in% countries$choice
  rc_tab <- ck_route_subset(rc_tab, rc_tab$unit %in% countries$choice)
  by_country <- dplyr::bind_rows(
    if (has_location) {
      ck_route_rank(
        id[shown],
        country[shown],
        location[shown],
        "route_location",
        w,
        list()
      )
    },
    ck_route_analyse(rc_tab, w, list(), sm_separator)
  )
  by_place <- if (!is.null(rl_tab)) {
    rl_country <- sub("\u001f.*$", "", rl_tab$unit)
    rl_tab <- ck_route_subset(rl_tab, rl_country %in% countries$choice)
    ck_route_analyse(rl_tab, w, list(), sm_separator)
  }

  # --- 5. Order the sections -----------------------------------------------------

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
  # The places within a country are always out of those naming the country;
  # only the overall ranking and the asked-of-everyone questions take the full
  # sample.
  out$base <- ifelse(
    out$variable %in%
      full_sample_vars &
      (out$variable != "route_country" | out$level == "overall"),
    "full_sample",
    "answered"
  )

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
    "n_w_total",
    "base"
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


#' Keep Some Rows of a Collapsed Route Table
#'
#' @param tab A list with `id`, `unit` and `vars`, as for [ck_route_analyse()].
#' @param keep Logical, one element per row.
#' @return `tab` with only the kept rows.
#' @keywords internal
ck_route_subset <- function(tab, keep) {
  list(
    id = tab$id[keep],
    unit = tab$unit[keep],
    vars = lapply(tab$vars, function(m) m[keep, , drop = FALSE])
  )
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
#' One block per sheet, laid out as MMC's route tables:
#'
#' 1. The country ranking: every country, as a share of respondents, overall
#'    and by each disaggregation.
#' 2. For each follow-up question, a wide table: `Overall`, then each country
#'    (most respondents first) followed by its top places, as columns; then,
#'    two rows below, the same question overall and by each disaggregation.
#'
#' Every table is a percentage panel and, one column to the right, the same
#' table in counts.
#'
#' @param wb An `openxlsx` workbook.
#' @param sheet Sheet name.
#' @param route The rows of [run_route_analysis()] for one block.
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
  def <- ck_route_blocks()[[route$block[1]]]
  openxlsx::addWorksheet(
    wb,
    sheetName = sheet,
    tabColour = pal[["teal"]],
    gridLines = FALSE
  )

  # --- styles ------------------------------------------------------------------
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
  head_style <- function(fill = NULL, bold = TRUE, halign = "center") {
    args <- list(
      textDecoration = if (bold) "bold" else NULL,
      halign = halign,
      valign = "center",
      wrapText = TRUE,
      border = "Bottom",
      borderColour = pal[["navy"]]
    )
    if (!is.null(fill)) {
      args$fgFill <- fill
    }
    do.call(base, args[!vapply(args, is.null, logical(1))])
  }
  st <- list(
    sheet_title = ck_style(
      sg,
      fontName = font_name,
      fontSize = 13,
      fontColour = pal[["navy"]],
      textDecoration = "bold"
    ),
    note = base(textDecoration = "italic"),
    title = ck_style(
      sg,
      fontName = font_name,
      fontSize = 11,
      fontColour = pal[["navy"]],
      textDecoration = "bold"
    ),
    panel = base(textDecoration = "bold"),
    band = base(halign = "center"),
    head_cat = head_style(pal[["pale_blue"]], halign = "left"),
    head_overall = head_style(pal[["pale_blue"]]),
    head_country = head_style(pal[["light_blue"]]),
    head_place = head_style(bold = FALSE),
    head_group = head_style(pal[["pale_blue"]]),
    label = base(),
    pct = base(numFmt = pct_fmt, halign = "center"),
    num = base(numFmt = "0", halign = "center")
  )

  put <- function(values, r, c) {
    openxlsx::writeData(
      wb,
      sheet,
      x = matrix(values, nrow = 1),
      startRow = r,
      startCol = c,
      colNames = FALSE
    )
  }
  max_col <- 1L
  header_rows <- integer(0)

  # --- one table: a % panel, a gap column, the same in counts -----------------
  # `columns` has one row per value column: key, header, band, band_id and
  # kind (overall, country, place, group). `cells` has key, choice, stat, n and
  # n_total for every cell there is. Returns the next free row.
  write_table <- function(r, columns, cells, choices) {
    k <- nrow(columns)
    bases <- vapply(
      columns$key,
      function(key) {
        b <- cells$n_total[cells$key == key]
        if (length(b) == 0) 0 else max(b, na.rm = TRUE)
      },
      numeric(1)
    )
    headers <- paste0(columns$header, " (n=", bases, ")")
    idx <- match(
      paste(
        rep(choices, times = k),
        rep(columns$key, each = length(choices)),
        sep = "\u001f"
      ),
      paste(cells$choice, cells$key, sep = "\u001f")
    )
    pct <- matrix(cells$stat[idx], nrow = length(choices))
    cnt <- matrix(cells$n[idx], nrow = length(choices))
    # No row for an answer in a column that has respondents: nobody gave it.
    # No respondents at all: left blank.
    has_base <- matrix(rep(bases > 0, each = length(choices)), ncol = k)
    pct[is.na(pct) & has_base] <- 0
    cnt[is.na(cnt) & has_base] <- 0

    starts <- c(1L, k + 3L)
    labels <- c("% of respondents", "Number of respondents")
    for (p in 1:2) {
      c0 <- starts[p]
      vcols <- c0 + seq_len(k)
      put(labels[p], r, c0 + 1L)
      ck_add_rect(sg, st$panel, r, c0 + 1L)

      runs <- rle(columns$band_id)
      ends <- cumsum(runs$lengths)
      firsts <- ends - runs$lengths + 1L
      for (j in seq_along(firsts)) {
        put(columns$band[firsts[j]], r + 1L, vcols[firsts[j]])
        if (runs$lengths[j] > 1) {
          openxlsx::mergeCells(
            wb,
            sheet,
            cols = vcols[firsts[j]:ends[j]],
            rows = r + 1L
          )
        }
      }
      ck_add_rect(sg, st$band, r + 1L, vcols)

      put(c("Category", headers), r + 2L, c0)
      ck_add_rect(sg, st$head_cat, r + 2L, c0)
      for (kind in unique(columns$kind)) {
        ck_add_rect(
          sg,
          st[[paste0("head_", kind)]],
          r + 2L,
          vcols[columns$kind == kind]
        )
      }

      body <- data.frame(choice = choices, stringsAsFactors = FALSE)
      vals <- if (p == 1) pct else cnt
      for (j in seq_len(k)) {
        body[[paste0("v", j)]] <- vals[, j]
      }
      openxlsx::writeData(
        wb,
        sheet,
        x = body,
        startRow = r + 3L,
        startCol = c0,
        colNames = FALSE
      )
      rows <- r + 2L + seq_along(choices)
      ck_add_rect(sg, st$label, rows, c0)
      ck_add_rect(sg, if (p == 1) st$pct else st$num, rows, vcols)
    }
    header_rows <<- c(header_rows, r + 2L)
    max_col <<- max(max_col, 2L * k + 3L)
    r + 3L + length(choices)
  }

  # Answers in one order for every table of a question: the overall
  # percentage, largest first, then anything only seen in a country or place.
  choice_order <- function(cells, overall_key = "overall") {
    main <- cells[cells$key == overall_key, , drop = FALSE]
    main <- main[order(-main$stat, -main$n, main$choice), , drop = FALSE]
    out <- c(main$choice, sort(setdiff(unique(cells$choice), main$choice)))
    # The not-asked row of a full-sample question goes last.
    nr <- ck_route_no_response_label()
    c(setdiff(out, nr), intersect(out, nr))
  }
  is_full <- function(rows) {
    "base" %in% names(rows) && any(rows$base == "full_sample", na.rm = TRUE)
  }
  base_note <- function(text, r) {
    put(text, r, 1L)
    ck_add_rect(sg, st$note, r, 1L)
    r + 1L
  }

  overall <- route[route$level == "overall", , drop = FALSE]
  group_vars <- unique(stats::na.omit(overall$group_var))
  group_label <- function(g) gsub("_", " ", g, fixed = TRUE)

  # The disaggregation table of one variable: Overall, then every group of
  # every disaggregation variable.
  disaggregated <- function(rows) {
    main <- rows[is.na(rows$group_var), , drop = FALSE]
    cols <- data.frame(
      key = "overall",
      header = "Overall",
      band = "Overall",
      band_id = "overall",
      kind = "overall",
      stringsAsFactors = FALSE
    )
    cells <- data.frame(
      key = "overall",
      choice = main$choice,
      stat = main$stat,
      n = main$n,
      n_total = main$n_total,
      stringsAsFactors = FALSE
    )
    for (g in group_vars) {
      rg <- rows[!is.na(rows$group_var) & rows$group_var == g, , drop = FALSE]
      if (nrow(rg) == 0) {
        next
      }
      sizes <- tapply(rg$n_total, rg$group_var_value, max)
      lv <- names(sort(sizes, decreasing = TRUE))
      keys <- paste0("g:", g, ":", lv)
      cols <- rbind(
        cols,
        data.frame(
          key = keys,
          header = lv,
          band = group_label(g),
          band_id = paste0("g:", g),
          kind = "group",
          stringsAsFactors = FALSE
        )
      )
      cells <- rbind(
        cells,
        data.frame(
          key = paste0("g:", g, ":", rg$group_var_value),
          choice = rg$choice,
          stat = rg$stat,
          n = rg$n,
          n_total = rg$n_total,
          stringsAsFactors = FALSE
        )
      )
    }
    list(columns = cols, cells = cells)
  }

  sections <- unique(route[, c("section", "level", "country", "location")])
  sections <- sections[order(sections$section), , drop = FALSE]
  country_secs <- sections[sections$level == "country", , drop = FALSE]
  place_secs <- sections[sections$level == "location", , drop = FALSE]
  has_places <- nrow(place_secs) > 0 || !is.na(def$location_label)

  ranking <- overall[overall$variable == "route_country", , drop = FALSE]
  n_countries <- sum(is.na(ranking$group_var) & ranking$n > 0)
  max_places <- if (nrow(place_secs) > 0) {
    max(table(place_secs$country))
  } else {
    0L
  }

  # --- sheet heading -------------------------------------------------------------
  row <- 1L
  put(def$title, row, 1L)
  ck_add_rect(sg, st$sheet_title, row, 1L)
  row <- row + 1L
  notes <- c(
    paste0(
      "Percentages are of respondents. A respondent counts once per country ",
      "or place, however many route slots name it, and an answer counts if ",
      "it was given in any of those slots."
    ),
    paste0(
      "Columns do not add up: a respondent can name several countries and ",
      "places, and give several answers. n is the number of respondents in ",
      "each column's base."
    )
  )
  for (nt in notes) {
    put(nt, row, 1L)
    ck_add_rect(sg, st$note, row, 1L)
    row <- row + 1L
  }
  row <- row + 1L

  # --- 1. country ranking ---------------------------------------------------------
  if (nrow(ranking) > 0) {
    put(paste0(def$country_label, ": all countries"), row, 1L)
    ck_add_rect(sg, st$title, row, 1L)
    row <- base_note(
      if (is_full(ranking)) {
        paste0(
          "Out of all respondents, whether or not they named a country. ",
          "None, Refused and the like are not listed."
        )
      } else {
        "Out of the respondents who named at least one country."
      },
      row + 1L
    ) -
      1L
    tab <- disaggregated(ranking)
    main <- tab$cells[tab$cells$key == "overall", , drop = FALSE]
    choices <- main$choice[order(-main$n, main$choice)]
    row <- write_table(row + 1L, tab$columns, tab$cells, choices) + 3L
  }

  # --- 2. each follow-up question ---------------------------------------------------
  shown_note <- paste0(
    if (nrow(country_secs) < n_countries) {
      paste0(
        "Showing the top ",
        nrow(country_secs),
        " of ",
        n_countries,
        " countries"
      )
    } else {
      paste0("All ", n_countries, " countries")
    },
    ", by number of respondents",
    if (max_places > 0) {
      paste0(
        ", each followed by up to ",
        max_places,
        " of its places, likewise"
      )
    },
    "."
  )

  variables <- setdiff(
    unique(overall$variable),
    c("route_country", "route_location")
  )
  for (v in variables) {
    rv <- route[route$variable == v, , drop = FALSE]
    put(rv$variable_label[1], row, 1L)
    ck_add_rect(sg, st$title, row, 1L)
    row <- row + 1L
    if (v %in% def$respondent_follow_ups) {
      row <- base_note(
        paste0(
          "Asked once per respondent: a country column shows the answers of ",
          "the respondents who transited that country. ",
          if (is_full(rv)) {
            paste0(
              "Out of all respondents: anyone who did not answer is counted ",
              "in the '",
              ck_route_no_response_label(),
              "' row."
            )
          } else {
            "Out of the respondents who answered."
          }
        ),
        row
      )
    }

    # Wide table: Overall, then each country and its places.
    main <- rv[rv$level == "overall" & is.na(rv$group_var), , drop = FALSE]
    columns <- data.frame(
      key = "overall",
      header = "Overall",
      band = "Overall",
      band_id = "overall",
      kind = "overall",
      stringsAsFactors = FALSE
    )
    cells <- data.frame(
      key = "overall",
      choice = main$choice,
      stat = main$stat,
      n = main$n,
      n_total = main$n_total,
      stringsAsFactors = FALSE
    )
    for (i in seq_len(nrow(country_secs))) {
      cc <- country_secs$country[i]
      ckey <- paste0("c:", cc)
      columns <- rbind(
        columns,
        data.frame(
          key = ckey,
          header = cc,
          band = if (has_places) "Country" else "Countries",
          band_id = if (has_places) ckey else "countries",
          kind = "country",
          stringsAsFactors = FALSE
        )
      )
      rc <- rv[rv$level == "country" & rv$country == cc, , drop = FALSE]
      cells <- rbind(
        cells,
        data.frame(
          key = rep(ckey, nrow(rc)),
          choice = rc$choice,
          stat = rc$stat,
          n = rc$n,
          n_total = rc$n_total,
          stringsAsFactors = FALSE
        )
      )
      pl <- place_secs[place_secs$country == cc, , drop = FALSE]
      for (p in pl$location) {
        pkey <- paste0("p:", cc, "\u001f", p)
        columns <- rbind(
          columns,
          data.frame(
            key = pkey,
            header = p,
            band = "Locations",
            band_id = paste0("p:", cc),
            kind = "place",
            stringsAsFactors = FALSE
          )
        )
        rp <- rv[
          rv$level == "location" & rv$country == cc & rv$location == p,
          ,
          drop = FALSE
        ]
        cells <- rbind(
          cells,
          data.frame(
            key = rep(pkey, nrow(rp)),
            choice = rp$choice,
            stat = rp$stat,
            n = rp$n,
            n_total = rp$n_total,
            stringsAsFactors = FALSE
          )
        )
      }
    }
    choices <- choice_order(cells)
    row <- write_table(row, columns, cells, choices)
    put(shown_note, row, 1L)
    ck_add_rect(sg, st$note, row, 1L)
    row <- row + 3L

    # The same question, overall and by each disaggregation.
    if (length(group_vars) > 0) {
      tab <- disaggregated(rv[rv$level == "overall", , drop = FALSE])
      row <- write_table(row, tab$columns, tab$cells, choices) + 1L
    }
    row <- row + 3L
  }

  ck_flush_styles(sg, wb, sheet)
  openxlsx::setColWidths(wb, sheet, cols = 1L, widths = 42)
  if (max_col > 1L) {
    openxlsx::setColWidths(wb, sheet, cols = 2:max_col, widths = 13)
  }
  openxlsx::setRowHeights(wb, sheet, rows = header_rows, heights = 30)
  openxlsx::freezePane(wb, sheet, firstCol = TRUE)

  invisible(NULL)
}
