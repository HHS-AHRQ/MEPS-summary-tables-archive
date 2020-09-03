
# Load RX file ----------------------------------------------------------------
RX <- read_MEPS(year = year, type = "RX") 
colnames(RX) <- colnames(RX) %>% gsub(yr,"",.)

if(year <= 1998) RX <- RX %>% rename(PERWTF = WTDPER)

# For 1996-2013, merge with RX Multum Lexicon Addendum files
if(year <= 2013) {
  Multum <- read_MEPS(year = year, type = "Multum") 
  RX <- RX %>%
    select(-starts_with("TC"), -one_of("PREGCAT", "RXDRGNAM")) %>%
    left_join(Multum, by = c("DUPERSID", "RXRECIDX"))
}


# Define TC1 names (from Codebook documentation) 
RX <- RX %>%
  mutate(count = 1) %>%
  mutate(TC1name = recode_factor(
    TC1,
    .default = "Missing",
    .missing = "Missing",
    "-15" = "Not Ascertained", 
    "-9" = "Not Ascertained",
    "1" = "Anti-Infectives",
    "19" = "Antihyperlipidemic_agents",
    "20" = "Antineoplastics",
    "28" = "Biologicals",
    "40" = "Cardiovascular Agents",
    "57" = "Central Nervous System Agents",
    "81" = "Coagulation Modifiers",
    "87" = "Gastrointestinal Agents",
    "97" = "Hormones/Hormone Modifiers",
    "105" = "Miscellaneous Agents",
    "113" = "Genitourinary Tract Agents",
    "115" = "Nutritional Products",
    "122" = "Respiratory Agents",
    "133" = "Topical Agents",
    "218" = "Alternative Medicines",
    "242" = "Psychotherapeutic Agents",
    "254" = "Immunologic Agents",
    "358" = "Metabolic Agents")
  )
