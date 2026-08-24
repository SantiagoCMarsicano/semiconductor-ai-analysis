# ==================================================
# Semiconductor Industry Analysis
# Part II - Firm Analysis
# Author: Santiago Castillo Marsicano
# ==================================================

library(readxl)
library(tidyverse)

# Import data

firms <- read_excel(
      "data/raw/data_raw_global_semiconductor_firms_revenue_2011_2025" )

glimpse(firms)




