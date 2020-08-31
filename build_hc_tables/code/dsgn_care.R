# svydesigns for CARE tables

SAQdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~SAQWTF,
  data = FYC,
  nest = TRUE)

DIABdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~DIABWF,
  data = FYC,
  nest = TRUE)

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWTF,
  data = FYC,
  nest = TRUE)