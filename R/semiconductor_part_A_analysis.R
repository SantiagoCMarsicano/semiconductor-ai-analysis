# Semiconductor Industry 2010–2025 — Part A
# Final reconstructed R script
#
# Repository root:
# C:/Users/santi/semiconductor-ai-analysis
#
# IMPORTANT:
# Run this script with the repository root as your working directory.
# Raw data expected in: data/raw/
# English reconstructed figures written to: figures/EN/
# Each plot is also printed to the RStudio Plots pane.

# Install once if needed:
# install.packages(c(
#   "tidyverse", "readxl", "scales", "patchwork", "ggrepel"
# ))

library(tidyverse)
library(readxl)
library(scales)
library(patchwork)
library(ggrepel)

# Run the script from the repository root:
# C:/Users/santi/semiconductor-ai-analysis

raw_dir <- file.path("data", "raw")
figure_dir <- file.path("figures", "EN")

dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

# Print each figure in RStudio and save a separate reconstruction.
# 10.24 x 6.8267 inches at 150 dpi reproduces 1536 x 1024 pixels.
save_plot <- function(plot_object, filename) {
  print(plot_object)
  ggsave(
    filename = file.path(figure_dir, filename),
    plot = plot_object,
    width = 10.24,
    height = 6.8267,
    dpi = 150,
    bg = "white"
  )
}

theme_semiconductor <- function() {
  theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", size = 17),
      plot.subtitle = element_text(size = 11),
      plot.caption = element_text(size = 8, hjust = 0),
      axis.title = element_text(size = 10),
      legend.position = "bottom",
      legend.title = element_blank(),
      panel.grid.minor = element_blank(),
      plot.margin = margin(10, 15, 10, 15)
    )
}

event_years <- tibble(
  year = c(2017, 2020, 2023),
  event = c("A", "B", "C")
)

event_notes <- paste(
  "Notes:",
  "A = Cryptocurrency Mining Expansion (2017)",
  "B = COVID-19 & Semiconductor Crisis (2020)",
  "C = Generative AI Breakout Year (2023)",
  sep = "\n"
)

company_colors <- c(
  "AMD"    = "#F8766D",
  "ASML"   = "#A3A500",
  "Intel"  = "#00BF7D",
  "NVIDIA" = "#00B0F6",
  "TSMC"   = "#E76BF3"
)

wsts_path <- file.path(raw_dir, "Historical_Billings_Report.xlsx")

wsts_raw <- read_excel(
  wsts_path,
  sheet = "Monthly Data",
  col_names = FALSE
)

wsts_annual <- map_dfr(2010:2025, function(target_year) {

  year_row <- which(
    suppressWarnings(as.numeric(wsts_raw[[1]])) == target_year
  )[1]

  block <- wsts_raw[(year_row + 1):(year_row + 5), c(1, 14)]

  tibble(
    year = target_year,
    region = as.character(block[[1]]),
    sales_usd_thousands = as.numeric(block[[2]])
  )
}) %>%
  mutate(
    sales_usd_billions = sales_usd_thousands / 1e6
  )

global_sales <- wsts_annual %>%
  filter(region == "Worldwide") %>%
  select(year, semiconductor_sales = sales_usd_billions)

regional_sales <- wsts_annual %>%
  filter(region != "Worldwide") %>%
  mutate(
    macro_region = case_when(
      region %in% c("Japan", "Asia Pacific") ~ "East",
      region %in% c("Americas", "Europe") ~ "West",
      TRUE ~ NA_character_
    )
  ) %>%
  group_by(year, macro_region) %>%
  summarise(
    sales = sum(sales_usd_billions),
    .groups = "drop"
  )

regional_total <- regional_sales %>%
  group_by(year) %>%
  mutate(
    market_share = sales / sum(sales)
  ) %>%
  ungroup()

regional_index <- regional_sales %>%
  group_by(macro_region) %>%
  arrange(year) %>%
  mutate(
    growth_index = sales / first(sales) * 100
  ) %>%
  ungroup()

p1 <- ggplot(global_sales, aes(year, semiconductor_sales)) +
  geom_line(linewidth = 1.1, colour = "#1F4E79") +
  geom_point(size = 2, colour = "#1F4E79") +
  geom_vline(
    data = event_years,
    aes(xintercept = year),
    linetype = "dashed",
    linewidth = 0.5,
    colour = "grey45"
  ) +
  geom_text(
    data = event_years,
    aes(x = year, y = min(global_sales$semiconductor_sales) + 8, label = event),
    inherit.aes = FALSE,
    vjust = 1,
    size = 3
  ) +
  scale_x_continuous(
    breaks = seq(2010, 2024, 2)
  ) +
  scale_y_continuous(
    labels = label_number(accuracy = 1)
  ) +
  labs(
    title = "Global Semiconductor Sales",
    subtitle = "Worldwide semiconductor sales, 2010–2025 (USD Billions)",
    x = "Year",
    y = "Sales (USD Billions)",
    caption = paste0(
      event_notes,
      "\n\nSource: World Semiconductor Trade Statistics (WSTS)."
    )
  ) +
  theme_semiconductor()

save_plot(p1, "figure_01_global_semiconductor_sales_EN.png")

regional_palette <- c(
  "East" = "#F8766D",
  "West" = "#00BFC4"
)

p2 <- ggplot(
  regional_sales,
  aes(year, sales, colour = macro_region)
) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2) +
  geom_vline(
    data = event_years,
    aes(xintercept = year),
    linetype = "dashed",
    linewidth = 0.5,
    colour = "grey45"
  ) +
  geom_text(
    data = event_years,
    aes(
      x = year,
      y = min(regional_sales$sales) + 8,
      label = event
    ),
    inherit.aes = FALSE,
    vjust = 1,
    size = 3
  ) +
  scale_colour_manual(values = regional_palette) +
  scale_x_continuous(breaks = seq(2010, 2024, 2)) +
  labs(
    title = "Regional Semiconductor Sales",
    subtitle = "East and West, 2010–2025 (USD Billions)",
    x = "Year",
    y = "Sales (USD Billions)",
    caption = paste0(
      event_notes,
      "\n\nSource: World Semiconductor Trade Statistics (WSTS)."
    )
  ) +
  theme_semiconductor()

save_plot(p2, "figure_02_regional_semiconductor_sales_EN.png")

p3 <- ggplot(
  regional_total,
  aes(year, market_share * 100, colour = macro_region)
) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2) +
  geom_vline(
    data = event_years,
    aes(xintercept = year),
    linetype = "dashed",
    linewidth = 0.5,
    colour = "grey45"
  ) +
  geom_text(
    data = event_years,
    aes(x = year, y = 27.5, label = event),
    inherit.aes = FALSE,
    size = 3
  ) +
  scale_colour_manual(values = regional_palette) +
  scale_x_continuous(breaks = seq(2010, 2024, 2)) +
  scale_y_continuous(
    labels = label_percent(scale = 1),
    limits = c(25, 75)
  ) +
  labs(
    title = "Share of Semiconductor Sales",
    subtitle = "Regional market share 2010–2025",
    x = "Year",
    y = "Market Share",
    caption = paste0(
      event_notes,
      "\n\nSource: World Semiconductor Trade Statistics (WSTS)."
    )
  ) +
  theme_semiconductor()

save_plot(p3, "figure_03_regional_market_share_EN.png")

p4 <- ggplot(
  regional_index,
  aes(year, growth_index, colour = macro_region)
) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2) +
  geom_hline(
    yintercept = 100,
    linetype = "dotted",
    colour = "grey60"
  ) +
  geom_vline(
    data = event_years,
    aes(xintercept = year),
    linetype = "dashed",
    linewidth = 0.5,
    colour = "grey45"
  ) +
  geom_text(
    data = event_years,
    aes(x = year, y = 88, label = event),
    inherit.aes = FALSE,
    size = 3
  ) +
  scale_colour_manual(values = regional_palette) +
  scale_x_continuous(breaks = seq(2010, 2024, 2)) +
  labs(
    title = "Growth Index of Semiconductor Sales: East vs West",
    subtitle = "Indexed growth comparison (2010 = 100)",
    x = "Year",
    y = "Index (2010 = 100)",
    caption = paste0(
      event_notes,
      "\n\nSource: World Semiconductor Trade Statistics (WSTS)."
    )
  ) +
  theme_semiconductor()

save_plot(p4, "figure_04_regional_growth_index_EN.png")

share_comparison <- regional_total %>%
  filter(year %in% c(2010, 2025)) %>%
  mutate(
    year = factor(year),
    label = percent(market_share, accuracy = 0.1)
  )

p5 <- ggplot(
  share_comparison,
  aes(x = "", y = market_share, fill = macro_region)
) +
  geom_col(width = 1, colour = "white", linewidth = 0.4) +
  coord_polar(theta = "y") +
  facet_wrap(~ year) +
  geom_text(
    aes(label = paste0(macro_region, "\n", label)),
    position = position_stack(vjust = 0.5),
    size = 4
  ) +
  scale_fill_manual(values = regional_palette) +
  labs(
    title = "East vs West Share of Semiconductor Sales",
    subtitle = "Comparison between 2010 and 2025",
    x = NULL,
    y = NULL,
    caption = "Source: World Semiconductor Trade Statistics (WSTS)."
  ) +
  theme_void(base_size = 12) +
  theme(
    plot.background = element_rect(fill = "white", colour = NA),
    panel.background = element_rect(fill = "white", colour = NA),
    strip.background = element_rect(fill = "white", colour = NA),
    plot.title = element_text(face = "bold", size = 17),
    plot.subtitle = element_text(size = 11),
    plot.caption = element_text(size = 8, hjust = 0),
    legend.position = "bottom",
    legend.title = element_blank(),
    strip.text = element_text(face = "bold", size = 11)
  )

save_plot(p5, "figure_05_regional_market_share_comparison_EN.png")

gaming <- read_excel(
  file.path(raw_dir, "global_gaming_market_revenue_2012_2025.xlsx")
) %>%
  transmute(
    year = Year,
    gaming = Revenue_usd_billions
  )

smartphones <- read_excel(
  file.path(raw_dir, "global_smartphone_shipments_2012_2025.xlsx")
) %>%
  transmute(
    year = year,
    smartphones = shipments_millions
  )

technology_markets <- global_sales %>%
  filter(year >= 2012) %>%
  inner_join(gaming, by = "year") %>%
  inner_join(smartphones, by = "year") %>%
  rename(semiconductors = semiconductor_sales)

technology_index <- technology_markets %>%
  mutate(
    semiconductors = semiconductors / first(semiconductors) * 100,
    gaming = gaming / first(gaming) * 100,
    smartphones = smartphones / first(smartphones) * 100
  ) %>%
  pivot_longer(
    cols = c(semiconductors, gaming, smartphones),
    names_to = "market",
    values_to = "index"
  ) %>%
  mutate(
    market = recode(
      market,
      semiconductors = "Semiconductors",
      gaming = "Gaming",
      smartphones = "Smartphone"
    )
  )

technology_palette <- c(
  "Gaming" = "#F8766D",
  "Semiconductors" = "#00BA38",
  "Smartphone" = "#619CFF"
)

p6 <- ggplot(
  technology_index,
  aes(year, index, colour = market)
) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2) +
  geom_vline(
    data = event_years,
    aes(xintercept = year),
    linetype = "dashed",
    linewidth = 0.5,
    colour = "grey45"
  ) +
  geom_text(
    data = event_years,
    aes(x = year, y = 88, label = event),
    inherit.aes = FALSE,
    size = 3
  ) +
  scale_colour_manual(values = technology_palette) +
  scale_x_continuous(breaks = seq(2012, 2024, 2)) +
  labs(
    title = "Evolution of Semiconductor, Gaming and Smartphone Markets",
    subtitle = "Indexed growth comparison (2012 = 100)",
    x = "Year",
    y = "Index (2012 = 100)",
    caption = paste0(
      event_notes,
      "\n\nSources: WSTS, Newzoo, Gartner/IDC. Gaming and semiconductor series use revenue; smartphone series uses shipments."
    )
  ) +
  theme_semiconductor()

save_plot(p6, "figure_06_semiconductors_smartphones_gaming_index_EN.png")

scatter_data <- technology_markets %>%
  mutate(
    semiconductor_index = semiconductors / first(semiconductors) * 100,
    gaming_index = gaming / first(gaming) * 100,
    smartphone_index = smartphones / first(smartphones) * 100
  )

highlight_years <- scatter_data %>%
  filter(year %in% c(2012, 2015, 2018, 2021, 2025))

scatter_smartphone <- ggplot(
  scatter_data,
  aes(smartphone_index, semiconductor_index)
) +
  geom_point(aes(colour = year), size = 2.8) +
  scale_colour_gradient(low = "#C9DCF2", high = "#004C99") +
  geom_smooth(
    method = "lm",
    se = FALSE,
    linetype = "dashed",
    linewidth = 0.8,
    colour = "grey45"
  ) +
  geom_text_repel(
    data = highlight_years,
    aes(label = year),
    size = 3,
    colour = "#1F4E79",
    min.segment.length = 0
  ) +
  labs(
    title = "Smartphone Shipments vs. Semiconductor Sales",
    x = "Smartphone Shipments Index",
    y = "Semiconductor Sales Index"
  ) +
  theme_semiconductor() +
  theme(
    legend.position = "none",
    plot.title = element_text(size = 11, face = "bold")
  )

scatter_gaming <- ggplot(
  scatter_data,
  aes(gaming_index, semiconductor_index)
) +
  geom_point(aes(colour = year), size = 2.8) +
  scale_colour_gradient(low = "#C9DCF2", high = "#004C99") +
  geom_smooth(
    method = "lm",
    se = FALSE,
    linetype = "dashed",
    linewidth = 0.8,
    colour = "grey45"
  ) +
  geom_text_repel(
    data = highlight_years,
    aes(label = year),
    size = 3,
    colour = "#1F4E79",
    min.segment.length = 0
  ) +
  labs(
    title = "Gaming Revenue vs. Semiconductor Sales",
    x = "Gaming Market Index",
    y = "Semiconductor Sales Index"
  ) +
  theme_semiconductor() +
  theme(
    legend.position = "none",
    plot.title = element_text(size = 11, face = "bold")
  )

p7 <- (
  scatter_smartphone + scatter_gaming
) +
  plot_annotation(
    title = "Relationship Between Semiconductor Sales and Selected End Markets",
    caption = paste(
      "Sources: WSTS, Newzoo and Gartner.",
      "Note: Point shading indicates time, from 2012 (lighter) to 2025 (darker).",
      "Scatterplots are intended for exploratory analysis and should not be interpreted as evidence of causality.",
      sep = "\n"
    ),
    theme = theme(
      plot.title = element_text(face = "bold", size = 17),
      plot.caption = element_text(size = 8, hjust = 0)
    )
  )

save_plot(p7, "figure_07_scatter_semiconductors_related_markets_EN.png")

company_revenue <- read_excel(
  file.path(
    raw_dir,
    "data_raw_global_semiconductor_firms_revenue_2011_2025.xlsx"
  ),
  sheet = "Company_Revenues_billions"
) %>%
  pivot_longer(
    cols = -year,
    names_to = "company",
    values_to = "revenue"
  )

company_index <- company_revenue %>%
  group_by(company) %>%
  arrange(year) %>%
  mutate(
    revenue_index = revenue / first(revenue) * 100
  ) %>%
  ungroup()

p8 <- ggplot(
  company_index,
  aes(year, revenue_index, colour = company)
) +
  geom_line(linewidth = 1.05) +
  geom_point(size = 1.8) +
  geom_vline(
    data = event_years,
    aes(xintercept = year),
    linetype = "dashed",
    linewidth = 0.5,
    colour = "grey45"
  ) +
  geom_text(
    data = event_years,
    aes(x = year, y = 40, label = event),
    inherit.aes = FALSE,
    size = 3
  ) +
  scale_colour_manual(values = company_colors) +
  scale_x_continuous(breaks = seq(2011, 2025, 2)) +
  scale_y_continuous(labels = label_number(big.mark = ",")) +
  labs(
    title = "Revenue Growth Index of Leading Semiconductor Firms",
    subtitle = "Revenue growth comparison (2011 = 100)",
    x = "Year",
    y = "Index (2011 = 100)",
    caption = paste0(
      event_notes,
      "\n\nSources: Company annual reports and financial statements."
    )
  ) +
  theme_semiconductor()

save_plot(p8, "figure_08_company_revenue_index_EN.png")

company_comparison <- company_revenue %>%
  filter(year %in% c(2011, 2025)) %>%
  mutate(
    year = factor(year),
    company = factor(
      company,
      levels = c("AMD", "ASML", "Intel", "TSMC", "NVIDIA")
    )
  )

p9 <- ggplot(
  company_comparison,
  aes(company, revenue, fill = year)
) +
  geom_col(
    position = position_dodge(width = 0.75),
    width = 0.65
  ) +
  geom_text(
    aes(label = number(revenue, accuracy = 0.1)),
    position = position_dodge(width = 0.75),
    hjust = -0.08,
    size = 3.2
  ) +
  coord_flip() +
  scale_fill_manual(
    values = c("2011" = "#9CB7D9", "2025" = "#003B73")
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0, 0.08))
  ) +
  labs(
    title = "Revenue Comparison of Leading Semiconductor Firms",
    subtitle = "2011 vs 2025 (USD Billions)",
    x = NULL,
    y = "USD Billions",
    caption = "Sources: Company annual reports and financial statements."
  ) +
  theme_semiconductor()

save_plot(p9, "figure_09_company_revenues_2011_2025_EN.png")

revenue_share <- company_revenue %>%
  filter(year %in% c(2011, 2025)) %>%
  group_by(year) %>%
  mutate(
    total_selected_revenue = sum(revenue),
    share = revenue / total_selected_revenue * 100
  ) %>%
  ungroup()

share_change <- revenue_share %>%
  select(year, company, share) %>%
  pivot_wider(
    names_from = year,
    values_from = share,
    names_prefix = "share_"
  ) %>%
  mutate(
    change_pp = share_2025 - share_2011
  )

revenue_share_plot <- revenue_share %>%
  left_join(
    share_change %>% select(company, change_pp),
    by = "company"
  ) %>%
  mutate(
    year = as.numeric(year)
  )

labels_2011 <- revenue_share_plot %>%
  filter(year == 2011) %>%
  mutate(
    label = paste0(
      company, "  ",
      number(share, accuracy = 0.1), "%"
    )
  )

labels_2025 <- revenue_share_plot %>%
  filter(year == 2025) %>%
  mutate(
    label = paste0(
      company, "  ",
      number(share, accuracy = 0.1), "% (",
      if_else(change_pp >= 0, "+", ""),
      number(change_pp, accuracy = 0.1),
      " pp)"
    ),
    label_y = case_when(
      company == "ASML" ~ share + 1.3,
      company == "AMD"  ~ share - 1.3,
      TRUE ~ share
    )
  )

p10 <- ggplot(
  revenue_share_plot,
  aes(year, share, colour = company, group = company)
) +
  geom_line(linewidth = 1.25) +
  geom_point(size = 3.2) +
  geom_text(
    data = labels_2011,
    aes(
      x = 2011,
      y = share,
      label = paste0(company, "  ", number(share, accuracy = 0.1), "%")
    ),
    inherit.aes = FALSE,
    hjust = 1.08,
    size = 3.2,
    fontface = "bold"
  ) +
  geom_text(
    data = labels_2025,
    aes(
      x = 2025,
      y = label_y,
      label = paste0(
        company, "  ",
        number(share, accuracy = 0.1), "%  (",
        if_else(change_pp >= 0, "+", ""),
        number(change_pp, accuracy = 0.1),
        " pp)"
      )
    ),
    inherit.aes = FALSE,
    hjust = -0.08,
    size = 3.2,
    fontface = "bold"
  ) +
  scale_colour_manual(values = company_colors) +
  scale_x_continuous(
    breaks = c(2011, 2025),
    limits = c(2007.8, 2029.2),
    expand = c(0, 0)
  ) +
  scale_y_continuous(
    labels = label_percent(scale = 1),
    limits = c(0, 65),
    breaks = seq(0, 60, 10),
    expand = expansion(mult = c(0.02, 0.04))
  ) +
  labs(
    title = "Revenue Share of Leading Semiconductor Firms",
    subtitle = "Share of total revenue among selected companies, 2011 and 2025",
    x = NULL,
    y = "Share of Total Revenue (%)",
    caption = paste(
      "Note: Values in parentheses indicate the change between 2011 and 2025 in percentage points.",
      "Source: Company annual reports and financial statements.",
      sep = "\n"
    )
  ) +
  theme_semiconductor() +
  theme(
    legend.position = "none",
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(face = "bold"),
    plot.margin = margin(10, 75, 10, 75)
  )

save_plot(p10, "figure_10_company_revenue_share_EN.png")

market_cap_2025 <- read_csv(
  file.path(raw_dir, "company_market_cap_2025.csv"),
  show_col_types = FALSE
) %>%
  transmute(
    company,
    ticker,
    year,
    market_cap_usd_billions,
    source,
    source_page,
    measurement
  )

company_2025 <- company_revenue %>%
  filter(year == 2025) %>%
  select(company, revenue) %>%
  left_join(
    market_cap_2025 %>%
      select(company, market_cap_usd_billions),
    by = "company"
  )

p11 <- market_cap_2025 %>%
  mutate(
    company = fct_reorder(company, market_cap_usd_billions)
  ) %>%
  ggplot(
    aes(company, market_cap_usd_billions)
  ) +
  geom_col(fill = "#003B73", width = 0.65) +
  geom_text(
    aes(
      label = number(
        market_cap_usd_billions,
        accuracy = 1,
        big.mark = ","
      )
    ),
    hjust = -0.08,
    size = 3.4
  ) +
  coord_flip() +
  scale_y_continuous(
    labels = label_number(big.mark = ","),
    expand = expansion(mult = c(0, 0.12))
  ) +
  labs(
    title = "Market Capitalization of Leading Semiconductor Firms",
    subtitle = "2025 (USD Billions)",
    x = NULL,
    y = "USD Billions",
    caption = "Source: CompaniesMarketCap."
  ) +
  theme_semiconductor() +
  theme(legend.position = "none")

save_plot(p11, "figure_11_market_cap_2025_EN.png")

p12 <- ggplot(
  company_2025,
  aes(revenue, market_cap_usd_billions)
) +
  geom_point(
    size = 3.5,
    colour = "#0055A4"
  ) +
  geom_text_repel(
    aes(label = company),
    size = 3.5,
    fontface = "bold",
    min.segment.length = 0
  ) +
  scale_y_continuous(
    labels = label_number(big.mark = ",")
  ) +
  labs(
    title = "Market Capitalization versus Revenue",
    subtitle = "Leading semiconductor firms, 2025",
    x = "Revenue (USD Billions)",
    y = "Market Capitalization (USD Billions)",
    caption = "Sources: CompaniesMarketCap; company annual reports and financial statements."
  ) +
  theme_semiconductor() +
  theme(legend.position = "none")

save_plot(p12, "figure_12_market_cap_vs_revenue_EN.png")

# WSTS should contain 16 annual observations from 2010 through 2025.
stopifnot(nrow(global_sales) == 16)
stopifnot(min(global_sales$year) == 2010)
stopifnot(max(global_sales$year) == 2025)

# East + West must reproduce Worldwide sales, allowing for tiny rounding differences.
regional_validation <- regional_sales %>%
  group_by(year) %>%
  summarise(regional_sum = sum(sales), .groups = "drop") %>%
  left_join(global_sales, by = "year") %>%
  mutate(
    difference = regional_sum - semiconductor_sales
  )

stopifnot(max(abs(regional_validation$difference)) < 0.001)

# Index bases.
stopifnot(
  all(
    regional_index %>%
      filter(year == 2010) %>%
      pull(growth_index) %>%
      round(8) == 100
  )
)

stopifnot(
  all(
    technology_index %>%
      filter(year == 2012) %>%
      pull(index) %>%
      round(8) == 100
  )
)

stopifnot(
  all(
    company_index %>%
      filter(year == 2011) %>%
      pull(revenue_index) %>%
      round(8) == 100
  )
)

# Revenue shares must sum to 100% within each comparison year.
share_check <- revenue_share %>%
  group_by(year) %>%
  summarise(total_share = sum(share), .groups = "drop")

stopifnot(all(abs(share_check$total_share - 100) < 1e-8))

# Market-cap file should contain one 2025 observation for each selected company.
stopifnot(nrow(market_cap_2025) == 5)
stopifnot(all(market_cap_2025$year == 2025))
stopifnot(
  setequal(
    market_cap_2025$company,
    c("NVIDIA", "TSMC", "ASML", "AMD", "Intel")
  )
)
stopifnot(all(!is.na(company_2025$market_cap_usd_billions)))

message("Validation checks passed.")
