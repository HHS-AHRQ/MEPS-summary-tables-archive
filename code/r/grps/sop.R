# Add aggregate sources of payment
  if(year <= 1999)
    FYC <- FYC %>% mutate(TOTTRI.yy. = TOTCHM.yy.)

  FYC <- FYC %>% mutate(
    TOTOTH.yy. = TOTOFD.yy. + TOTSTL.yy. + TOTOPR.yy. + TOTOPU.yy. + TOTOSR.yy.,
    TOTOTZ.yy. = TOTOTH.yy. + TOTWCP.yy. + TOTVA.yy.,
    TOTPTR.yy. = TOTPRV.yy. + TOTTRI.yy.)
