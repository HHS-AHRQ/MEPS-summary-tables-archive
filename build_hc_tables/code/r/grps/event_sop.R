# Add aggregate sources of payment for all event types
  evt <- c("TOT","RX","DVT","OBV","OBD",
           "OPF","OPD","OPV","OPS",
           "ERF","ERD","IPF","IPD","HHA","HHN",
           "VIS","OTH")

  if(year <= 1999)
    FYC[,sprintf("%sTRI.yy.",evt)] <- FYC[,sprintf("%sCHM.yy.", evt)]

  FYC[,sprintf("%sPTR.yy.",evt)] <-
    FYC[,sprintf("%sPRV.yy.",evt)]+
    FYC[,sprintf("%sTRI.yy.",evt)]

  FYC[,sprintf("%sOTH.yy.",evt)] <-
    FYC[,sprintf("%sOFD.yy.",evt)]+
    FYC[,sprintf("%sSTL.yy.",evt)]+
    FYC[,sprintf("%sOPR.yy.",evt)]+
    FYC[,sprintf("%sOPU.yy.",evt)]+
    FYC[,sprintf("%sOSR.yy.",evt)]

  FYC[,sprintf("%sOTZ.yy.",evt)] <-
    FYC[,sprintf("%sOTH.yy.",evt)]+
    FYC[,sprintf("%sVA.yy.",evt)]+
    FYC[,sprintf("%sWCP.yy.",evt)]

# Add aggregate event variables for all sources of payment
  sop <- c("EXP","SLF","PTR","MCR","MCD","OTZ")

  FYC[,sprintf("OMA%s.yy.",sop)] = FYC[,sprintf("VIS%s.yy.",sop)]+FYC[,sprintf("OTH%s.yy.",sop)]
  FYC[,sprintf("HHT%s.yy.",sop)] = FYC[,sprintf("HHA%s.yy.",sop)]+FYC[,sprintf("HHN%s.yy.",sop)]
  FYC[,sprintf("ERT%s.yy.",sop)] = FYC[,sprintf("ERF%s.yy.",sop)]+FYC[,sprintf("ERD%s.yy.",sop)]
  FYC[,sprintf("IPT%s.yy.",sop)] = FYC[,sprintf("IPF%s.yy.",sop)]+FYC[,sprintf("IPD%s.yy.",sop)]

  FYC[,sprintf("OPT%s.yy.",sop)] = FYC[,sprintf("OPF%s.yy.",sop)]+FYC[,sprintf("OPD%s.yy.",sop)]
  FYC[,sprintf("OPY%s.yy.",sop)] = FYC[,sprintf("OPV%s.yy.",sop)]+FYC[,sprintf("OPS%s.yy.",sop)]
  
