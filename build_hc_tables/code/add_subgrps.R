
# Age groups ------------------------------------------------------------------
  if(year == 1996) 
    FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)
  
  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")), ~replace(., .< 0, NA)) %>%
    mutate(AGELAST = coalesce(AGEX, AGE42X, AGE31X))
  
  FYC <- FYC %>%
    mutate(agegrps = cut(
      AGELAST,
      breaks = c(-1, 4.5, 17.5, 44.5, 64.5, Inf),
      labels = c("Under 5","5-17","18-44","45-64","65+"))) %>%
    
    mutate(agegrps_v2X = cut(
      AGELAST,
      breaks = c(-1, 17.5 ,64.5, Inf),
      labels = c("Under 18","18-64","65+"))) %>%
    
    mutate(agegrps_v3X = cut(
      AGELAST,
      breaks = c(-1, 4.5, 6.5, 12.5, 17.5, 18.5, 24.5, 29.5, 34.5, 44.5, 54.5, 64.5, Inf),
      labels = c("Under 5", "5-6", "7-12", "13-17", "18", "19-24", "25-29",
                 "30-34", "35-44", "45-54", "55-64", "65+")))
  
# Census region ---------------------------------------------------------------
  if(year == 1996)
    FYC <- FYC %>% mutate(REGION42 = REGION2, REGION31 = REGION1)

    FYC <- FYC %>%
    mutate_at(vars(starts_with("REGION")), ~replace(., .< 0, NA)) %>%
    mutate(region = coalesce(REGION, REGION42, REGION31)) %>%
    mutate(region = recode_factor(
      region, 
      .default = "Missing", 
      .missing = "Missing", 
      "1" = "Northeast",
      "2" = "Midwest",
      "3" = "South",
      "4" = "West"))
  
# Marital status --------------------------------------------------------------
  if(year == 1996){
    FYC <- FYC %>%
      mutate(MARRY42X = ifelse(MARRY2X <= 6, MARRY2X, MARRY2X-6),
             MARRY31X = ifelse(MARRY1X <= 6, MARRY1X, MARRY1X-6))
  }
  
  FYC <- FYC %>%
    mutate_at(vars(starts_with("MARRY")), ~replace(., .< 0, NA)) %>%
    mutate(married = coalesce(MARRYX, MARRY42X, MARRY31X)) %>%
    mutate(married = recode_factor(
      married, 
      .default = "Missing", 
      .missing = "Missing", 
      "1" = "Married",
      "2" = "Widowed",
      "3" = "Divorced",
      "4" = "Separated",
      "5" = "Never married",
      "6" = "Inapplicable (age < 16)"))
    
  
# Race / ethnicity ------------------------------------------------------------
# Starting in 2012, RACETHX replaced RACEX;
  if(year >= 2012){
    FYC <- FYC %>%
      mutate(
        white_oth=F,
        hisp   = (RACETHX == 1),
        white  = (RACETHX == 2),
        black  = (RACETHX == 3),
        native = (RACETHX > 3 & RACEV1X %in% c(3,6)),
        asian  = (RACETHX > 3 & RACEV1X %in% c(4,5)))
    
  }else if(year >= 2002){
    FYC <- FYC %>%
      mutate(
        white_oth=0,
        hisp   = (RACETHNX == 1),
        white  = (RACETHNX == 4 & RACEX == 1),
        black  = (RACETHNX == 2),
        native = (RACETHNX >= 3 & RACEX %in% c(3,6)),
        asian  = (RACETHNX >= 3 & RACEX %in% c(4,5)))
    
  }else{
    FYC <- FYC %>%
      mutate(
        hisp = (RACETHNX == 1),
        black = (RACETHNX == 2),
        white_oth = (RACETHNX == 3),
        white = 0,native=0,asian=0)
  }
  
  FYC <- FYC %>% mutate(
    race = 1*hisp + 2*white + 3*black + 4*native + 5*asian + 9*white_oth,
    race = recode_factor(
      race, .default = "Missing", .missing = "Missing", 
      "1" = "Hispanic",
      "2" = "White",
      "3" = "Black",
      "4" = "Amer. Indian, AK Native, or mult. races",
      "5" = "Asian, Hawaiian, or Pacific Islander",
      "9" = "White and other"))

# Sex -------------------------------------------------------------------------
  FYC <- FYC %>%
    mutate(sex = recode_factor(
      SEX, .default = "Missing", .missing = "Missing", 
      "1" = "Male",
      "2" = "Female"))
  
# Race x Sex ------------------------------------------------------------------  
  FYC <- FYC %>% mutate(
    racesex = paste0(sex, ", ", race)
  )
  
# Education -------------------------------------------------------------------
  if(year %in% 1996:1998) 
    FYC <- FYC %>% mutate(EDUCYR = EDUCYR)
  
  if(year %in% 1999:2004) 
    FYC <- FYC %>% mutate(EDUCYR = EDUCYEAR)
  
  if(year %in% 2012:2015){
    FYC <- FYC %>%
      mutate(
        less_than_hs = (0 <= EDRECODE & EDRECODE < 13),
        high_school  = (EDRECODE == 13),
        some_college = (EDRECODE > 13))
  } else {
    FYC <- FYC %>%
      mutate(
        less_than_hs = (0 <= EDUCYR & EDUCYR < 12),
        high_school  = (EDUCYR == 12),
        some_college = (EDUCYR > 12))
  }
  
  FYC <- FYC %>% mutate(
    education = 1*less_than_hs + 2*high_school + 3*some_college,
    education = replace(education, AGELAST < 18, 9),
    education = recode_factor(
      education, 
      .default = "Missing", 
      .missing = "Missing",
      "1" = "Less than high school",
      "2" = "High school",
      "3" = "Some college",
      "9" = "Inapplicable (age < 18)",
      "0" = "Missing"))

# Employment Status -----------------------------------------------------------
  if(year == 1996)
    FYC <- FYC %>% 
      mutate(EMPST53 = EMPST, EMPST42 = EMPST2, EMPST31 = EMPST1)
  
  FYC <- FYC %>%
    mutate_at(vars(EMPST53, EMPST42, EMPST31), ~replace(., .< 0, NA)) %>%
    mutate(employ_last = coalesce(EMPST53, EMPST42, EMPST31))
  
  FYC <- FYC %>% mutate(
    employed = 1*(employ_last==1) + 2*(employ_last > 1),
    employed = replace(employed, is.na(employed) & AGELAST < 16, 9),
    employed = recode_factor(
      employed, 
      .default = "Missing", 
      .missing = "Missing", 
      "1" = "Employed",
      "2" = "Not employed",
      "9" = "Inapplicable (age < 16)"))
  
# Insurance coverage ----------------------------------------------------------
  if(year == 1996){
    FYC <- FYC %>%
      mutate(MCDEV = MCDEVER, MCREV = MCREVER,
             OPAEV = OPAEVER, OPBEV = OPBEVER)
  }
  
  if(year %in% 1996:2010){
    FYC <- FYC %>%
      mutate(
        public   = (MCDEV==1|OPAEV==1|OPBEV==1),
        medicare = (MCREV==1),
        private  = (INSCOV==1),
        
        mcr_priv = (medicare &  private),
        mcr_pub  = (medicare & !private & public),
        mcr_only = (medicare & !private & !public),
        no_mcr   = (!medicare),
        
        ins_gt65 = 4*mcr_only + 5*mcr_priv + 6*mcr_pub + 7*no_mcr,
        INSURC = ifelse(AGELAST < 65, INSCOV, ins_gt65)
      )
  }
  
  FYC <- FYC %>%
    mutate(insurance = recode_factor(
      INSCOV, 
      .default = "Missing", 
      .missing = "Missing", 
      "1" = "Any private, all ages",
      "2" = "Public only, all ages",
      "3" = "Uninsured, all ages")) %>%
    
    mutate(insurance_v2X = recode_factor(
      INSURC, 
      .default = "Missing", 
      .missing = "Missing",
      "1" = "<65, Any private",
      "2" = "<65, Public only",
      "3" = "<65, Uninsured",
      "4" = "65+, Medicare only",
      "5" = "65+, Medicare and private",
      "6" = "65+, Medicare and other public",
      "7" = "65+, No medicare",
      "8" = "65+, No medicare"))
  
# Poverty status --------------------------------------------------------------
  FYC <- FYC %>%
    mutate(poverty = recode_factor(
      POVCAT, 
      .default = "Missing", 
      .missing = "Missing", 
      "1" = "Negative or poor",
      "2" = "Near-poor",
      "3" = "Low income",
      "4" = "Middle income",
      "5" = "High income"))

# Perceived health status -----------------------------------------------------
  if(year == 1996)
    FYC <- FYC %>% mutate(
      RTHLTH53 = RTEHLTH2, RTHLTH42 = RTEHLTH2, RTHLTH31 = RTEHLTH1)
  
  FYC <- FYC %>%
    mutate_at(vars(starts_with("RTHLTH")), ~replace(., .< 0, NA)) %>%
    mutate(
      health = coalesce(RTHLTH53, RTHLTH42, RTHLTH31),
      health = recode_factor(
        health, 
        .default = "Missing", 
        .missing = "Missing", 
        "1" = "Excellent",
        "2" = "Very good",
        "3" = "Good",
        "4" = "Fair",
        "5" = "Poor"))

# Perceived mental health -----------------------------------------------------
  if(year == 1996)
    FYC <- FYC %>% mutate(
      MNHLTH53 = MNTHLTH2, MNHLTH42 = MNTHLTH2, MNHLTH31 = MNTHLTH1)
  
  FYC <- FYC %>%
    mutate_at(vars(starts_with("MNHLTH")), ~replace(., .< 0, NA)) %>%
    mutate(mnhlth = coalesce(MNHLTH53, MNHLTH42, MNHLTH31)) %>%
    mutate(mnhlth = recode_factor(
      mnhlth, 
      .default = "Missing", 
      .missing = "Missing", 
      "1" = "Excellent",
      "2" = "Very good",
      "3" = "Good",
      "4" = "Fair",
      "5" = "Poor"))
  
  
# Add aggregate event variables -----------------------------------------------
  FYC <- FYC %>% mutate(
    HHTEXP = HHAEXP + HHNEXP, # Home Health Agency + Independent providers
    ERTEXP = ERFEXP + ERDEXP, # Dr. + Facility for OP, ER, IP events
    IPTEXP = IPFEXP + IPDEXP,
    OPTEXP = OPFEXP + OPDEXP, # All Outpatient
    OPYEXP = OPVEXP + OPSEXP, # Physician only
    OMAEXP = VISEXP + OTHEXP) # Other medical equipment and services
  
  FYC <- FYC %>% mutate(
    TOTUSE = (
      (DVTOT > 0) + (RXTOT > 0) + (OBTOTV > 0) +
        (OPTOTV > 0) + (ERTOT > 0) + (IPDIS > 0) +
        (HHTOTD > 0) + (OMAEXP > 0))
  )

  
# Add aggregate sources of payment for all event types ------------------------
  evt <- c("TOT","RX","DVT","OBV","OBD",
           "OPF","OPD","OPV","OPS", 
           "ERF","ERD","IPF","IPD","HHA","HHN",
           "VIS","OTH")
  
  if(year <= 1999) FYC[,p(evt,"TRI")] <- FYC[,p(evt,"CHM")]
  
  FYC[,p(evt,"PTR")] <- FYC[,p(evt,"PRV")] + FYC[,p(evt,"TRI")]
  
  FYC[,p(evt,"OTH")] <-
    FYC[,p(evt,"OFD")] + FYC[,p(evt,"STL")] + FYC[,p(evt,"OPR")] + 
    FYC[,p(evt,"OPU")] + FYC[,p(evt,"OSR")]
  
  FYC[,p(evt,"OTZ")] <- 
    FYC[,p(evt,"OTH")] + FYC[,p(evt,"VA")] + FYC[,p(evt,"WCP")]
  
  
# Add aggregate event variables for all sources of payment --------------------
  sop <- c("EXP","SLF","PTR","MCR","MCD","OTZ")
  
  FYC[,p("OMA",sop)] = FYC[,p("VIS",sop)] + FYC[,p("OTH",sop)]
  FYC[,p("HHT",sop)] = FYC[,p("HHA",sop)] + FYC[,p("HHN",sop)]
  FYC[,p("ERT",sop)] = FYC[,p("ERF",sop)] + FYC[,p("ERD",sop)]
  FYC[,p("IPT",sop)] = FYC[,p("IPF",sop)] + FYC[,p("IPD",sop)]
  
  FYC[,p("OPT",sop)] = FYC[,p("OPF",sop)] + FYC[,p("OPD",sop)]
  FYC[,p("OPY",sop)] = FYC[,p("OPV",sop)] + FYC[,p("OPS",sop)]
  
