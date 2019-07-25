var appKey = 'hc_ins';

var pufNames = {"1996":[{"Year":"1996","PIT":"h01","FYC":"h12","Conditions":"hc006r","PMED":"hc10a","Jobs":"hc007","PRPL":"h24","Longitudinal":"-","CLNK":"hc10if1","RXLK":"hc10if2","Multum":"h68f1","MOS":"-","RX":"hc10a","DV":"hc10bf1","OM":"hc10cf1","IP":"hc10df1","ER":"hc10ef1","OP":"hc10ff1","OB":"hc10gf1","MV":"hc10gf1","HH":"hc10hf1"}],"1997":[{"Year":"1997","PIT":"hc005xf","FYC":"h20","Conditions":"h18","PMED":"h16a","Jobs":"hc19","PRPL":"h47f1","Longitudinal":"h23","CLNK":"h16if1","RXLK":"h16if2","Multum":"h68f2","MOS":"-","RX":"h16a","DV":"hc16bf1","OM":"hc16cf1","IP":"hc16df1","ER":"hc16ef1","OP":"hc16ff1","OB":"hc16gf1","MV":"hc16gf1","HH":"hc16hf1"}],"1998":[{"Year":"1998","PIT":"hc009xf","FYC":"h28","Conditions":"h27","PMED":"h26a","Jobs":"h25","PRPL":"h47f2","Longitudinal":"h35","CLNK":"h26if1","RXLK":"h26if2","Multum":"h68f3","MOS":"-","RX":"h26a","DV":"hc26bf1","OM":"h26cf1","IP":"h26df1","ER":"h26ef1","OP":"h26ff1","OB":"h26gf1","MV":"h26gf1","HH":"h26hf1"}],"1999":[{"Year":"1999","PIT":"hc013xf","FYC":"h38","Conditions":"h37","PMED":"h33a","Jobs":"h32","PRPL":"h47f3","Longitudinal":"h48","CLNK":"h33if1","RXLK":"h33if2","Multum":"h68f4","MOS":"-","RX":"h33a","DV":"h33b","OM":"h33c","IP":"h33d","ER":"h33e","OP":"h33f","OB":"h33g","MV":"h33g","HH":"h33h"}],"2000":[{"Year":"2000","PIT":"h22","FYC":"h50","Conditions":"h52","PMED":"h51a","Jobs":"h40","PRPL":"h47f4","Longitudinal":"h58","CLNK":"h51if1","RXLK":"h51if2","Multum":"h68f5","MOS":"-","RX":"h51a","DV":"h51b","OM":"h51c","IP":"h51d","ER":"h51e","OP":"h51f","OB":"h51g","MV":"h51g","HH":"h51h"}],"2001":[{"Year":"2001","PIT":"h34","FYC":"h60","Conditions":"h61","PMED":"h59a","Jobs":"h56","PRPL":"h57","Longitudinal":"h65","CLNK":"h59if1","RXLK":"h59if2","Multum":"h68f6","MOS":"-","RX":"h59a","DV":"h59b","OM":"h59c","IP":"h59d","ER":"h59e","OP":"h59f","OB":"h59g","MV":"h59g","HH":"h59h"}],"2002":[{"Year":"2002","PIT":"h53","FYC":"h70","Conditions":"h69","PMED":"h67a","Jobs":"h63","PRPL":"h66","Longitudinal":"h71","CLNK":"h67if1","RXLK":"h67if2","Multum":"h68f7","MOS":"-","RX":"h67a","DV":"h67b","OM":"h67c","IP":"h67d","ER":"h67e","OP":"h67f","OB":"h67g","MV":"h67g","HH":"h67h"}],"2003":[{"Year":"2003","PIT":"h64","FYC":"h79","Conditions":"h78","PMED":"h77a","Jobs":"h74","PRPL":"h76","Longitudinal":"h80","CLNK":"h77if1","RXLK":"h77if2","Multum":"h68f8","MOS":"-","RX":"h77a","DV":"h77b","OM":"h77c","IP":"h77d","ER":"h77e","OP":"h77f","OB":"h77g","MV":"h77g","HH":"h77h"}],"2004":[{"Year":"2004","PIT":"h75","FYC":"h89","Conditions":"h87","PMED":"h85a","Jobs":"h83","PRPL":"h88","Longitudinal":"h86","CLNK":"h85if1","RXLK":"h85if2","Multum":"h68f9","MOS":"-","RX":"h85a","DV":"h85b","OM":"h85c","IP":"h85d","ER":"h85e","OP":"h85f","OB":"h85g","MV":"h85g","HH":"h85h"}],"2005":[{"Year":"2005","PIT":"h84","FYC":"h97","Conditions":"h96","PMED":"h94a","Jobs":"h91","PRPL":"h95","Longitudinal":"h98","CLNK":"h94if1","RXLK":"h94if2","Multum":"h68f10","MOS":"-","RX":"h94a","DV":"h94b","OM":"h94c","IP":"h94d","ER":"h94e","OP":"h94f","OB":"h94g","MV":"h94g","HH":"h94h"}],"2006":[{"Year":"2006","PIT":"h93","FYC":"h105","Conditions":"h104","PMED":"h102a","Jobs":"h100","PRPL":"h103","Longitudinal":"h106","CLNK":"h102if1","RXLK":"h102if2","Multum":"h68f11","MOS":"-","RX":"h102a","DV":"h102b","OM":"h102c","IP":"h102d","ER":"h102e","OP":"h102f","OB":"h102g","MV":"h102g","HH":"h102h"}],"2007":[{"Year":"2007","PIT":"h101","FYC":"h113","Conditions":"h112","PMED":"h110a","Jobs":"h108","PRPL":"h111","Longitudinal":"h114","CLNK":"h110if1","RXLK":"h110if2","Multum":"h68f12","MOS":"-","RX":"h110a","DV":"h110b","OM":"h110c","IP":"h110d","ER":"h110e","OP":"h110f","OB":"h110g","MV":"h110g","HH":"h110h"}],"2008":[{"Year":"2008","PIT":"h109","FYC":"h121","Conditions":"h120","PMED":"h118a","Jobs":"h116","PRPL":"h119","Longitudinal":"h122","CLNK":"h118if1","RXLK":"h118if2","Multum":"h68f13","MOS":"-","RX":"h118a","DV":"h118b","OM":"h118c","IP":"h118d","ER":"h118e","OP":"h118f","OB":"h118g","MV":"h118g","HH":"h118h"}],"2009":[{"Year":"2009","PIT":"h117","FYC":"h129","Conditions":"h128","PMED":"h126a","Jobs":"h124","PRPL":"h127","Longitudinal":"h130","CLNK":"h126if1","RXLK":"h126if2","Multum":"h68f14","MOS":"-","RX":"h126a","DV":"h126b","OM":"h126c","IP":"h126d","ER":"h126e","OP":"h126f","OB":"h126g","MV":"h126g","HH":"h126h"}],"2010":[{"Year":"2010","PIT":"h125","FYC":"h138","Conditions":"h137","PMED":"h135a","Jobs":"h133","PRPL":"h136","Longitudinal":"h139","CLNK":"h135if1","RXLK":"h135if2","Multum":"h68f15","MOS":"-","RX":"h135a","DV":"h135b","OM":"h135c","IP":"h135d","ER":"h135e","OP":"h135f","OB":"h135g","MV":"h135g","HH":"h135h"}],"2011":[{"Year":"2011","PIT":"h134","FYC":"h147","Conditions":"h146","PMED":"h144a","Jobs":"h142","PRPL":"h145","Longitudinal":"h148","CLNK":"h144if1","RXLK":"h144if2","Multum":"h68f16","MOS":"-","RX":"h144a","DV":"h144b","OM":"h144c","IP":"h144d","ER":"h144e","OP":"h144f","OB":"h144g","MV":"h144g","HH":"h144h"}],"2012":[{"Year":"2012","PIT":"h143","FYC":"h155","Conditions":"h154","PMED":"h152a","Jobs":"h150","PRPL":"h153","Longitudinal":"h156","CLNK":"h152if1","RXLK":"h152if2","Multum":"h68f17","MOS":"-","RX":"h152a","DV":"h152b","OM":"h152c","IP":"h152d","ER":"h152e","OP":"h152f","OB":"h152g","MV":"h152g","HH":"h152h"}],"2013":[{"Year":"2013","PIT":"h151","FYC":"h163","Conditions":"h162","PMED":"h160a","Jobs":"h158","PRPL":"h161","Longitudinal":"h164","CLNK":"h160if1","RXLK":"h160if2","Multum":"h68f18","MOS":"-","RX":"h160a","DV":"h160b","OM":"h160c","IP":"h160d","ER":"h160e","OP":"h160f","OB":"h160g","MV":"h160g","HH":"h160h"}],"2014":[{"Year":"2014","PIT":"h159","FYC":"h171","Conditions":"h170","PMED":"h168a","Jobs":"h166","PRPL":"h169","Longitudinal":"h172","CLNK":"h168if1","RXLK":"h168if2","Multum":"h68f18","MOS":"-","RX":"h168a","DV":"h168b","OM":"h168c","IP":"h168d","ER":"h168e","OP":"h168f","OB":"h168g","MV":"h168g","HH":"h168h"}],"2015":[{"Year":"2015","PIT":"h167","FYC":"h181","Conditions":"h180","PMED":"h178a","Jobs":"h176","PRPL":"h179","Longitudinal":"h183","CLNK":"h178if1","RXLK":"h178if2","Multum":"h68f18","MOS":"h182","RX":"h178a","DV":"h178b","OM":"h178c","IP":"h178d","ER":"h178e","OP":"h178f","OB":"h178g","MV":"h178g","HH":"h178h"}],"2016":[{"Year":"2016","PIT":"h177","FYC":"h192","Conditions":"h190","PMED":"h188a","Jobs":"h185","PRPL":"h191","Longitudinal":"h193","CLNK":"h188if1","RXLK":"h188if2","Multum":"h68f18","MOS":"h187","RX":"h188a","DV":"h188b","OM":"h188c","IP":"h188d","ER":"h188e","OP":"h188f","OB":"h188g","MV":"h188g","HH":"h188h"}],"2017":[{"Year":"2017","PIT":"","FYC":"","Conditions":"","PMED":"","Jobs":"h195","PRPL":"","Longitudinal":"","CLNK":"","RXLK":"","Multum":"h68f18","MOS":"","RX":"","DV":"h197b","OM":"h197c","IP":"h197d","ER":"h197e","OP":"h197f","OB":"h197g","MV":"h197g","HH":"h197h"}]};

var mepsNotes = {"pctPOP":"\nPercentages may not sum to 100 due to rounding.\n","agegrps":"\n<h4>Age groups<\/h4>\nRespondents were asked to report the age of each family member as of the date of each interview for each round of data collection. The age variable used to create these estimates is based on the sample person's age as of the end of the year. If data were not collected during a round because the sample person was out of scope (e.g., deceased or institutionalized), then age at the time of the previous round was used.\n","region":"\n<h4>Region<\/h4>\nThe census region variable is based on the location of the household at the end of the year. If missing, the most recent location available is used.\n<ul>\n  <li><i>Northeast:<\/i> Maine, New Hampshire, Vermont, Massachusetts, Rhode Island, Connecticut, New York, New Jersey, and Pennsylvania.<\/li>\n\n  <li><i>Midwest:<\/i> Ohio, Indiana, Illinois, Michigan, Wisconsin, Minnesota, Iowa, Missouri, North Dakota, South Dakota, Nebraska, and Kansas.<\/li>\n\n  <li><i>South:<\/i><\/i> Delaware, Maryland, District of Columbia, Virginia, West Virginia, North Carolina, South Carolina, Georgia, Florida, Kentucky, Tennessee, Alabama, Mississippi, Arkansas, Louisiana, Oklahoma, and Texas.<\/li>\n\n  <li><i>West:<\/i> Montana, Idaho, Wyoming, Colorado, New Mexico, Arizona, Utah, Nevada, Washington, Oregon, California, Alaska, and Hawaii.<\/li>\n<\/ul>\n","health":"\n<h4>Perceived health status<\/h4>\n<p>The MEPS respondent was asked to rate the health of each person in the family at the time of the interview according to the following categories: excellent, very good, good, fair, and poor. For persons with missing health status in a round, the response for health status at the previous round was used, if available. A small percentage of persons (< 2 percent) had a missing response for <i>perceived health status<\/i>.<\/p>\n","mnhlth":"\n<h4>Perceived mental health<\/h4>\n<p>The MEPS respondent was asked to rate the mental health of each person in the family at the time of the interview according to the following categories: excellent, very good, good, fair, and poor. For persons with missing mental health status in a round, the response for mental health status at the previous round was used, if available. A small percentage of persons (< 2 percent) had a missing response for <i>perceived mental health status<\/i>.<\/p>\n","married":"\n<h4>Marital status<\/h4>\nMarital status is based on the person's marital status at the end of the year. If missing, the most recent non-missing marital status variable is used. A small percentage of persons (< 2 percent) had a missing value for <i>marital status<\/i>.\n","education":"\n<h4>Education<\/h4>\nEducation for each person is based on the highest education level completed when entering MEPS. A small percentage of persons (< 2 percent) had a missing response for <i>education<\/i>.\n","employed":"\n<h4>Employment status<\/h4>\nEmployment status is based on the person's employment status at the end of the year. If missing, the most recent non-missing employment status variable is used. A small percentage of persons (< 2 percent) had a missing response for <i>employment status<\/i>.\n","ins_ge65":"\n<h4>Insurance coverage<\/h4>\n<ul>\n<li><i>Uninsured:<\/i>\nIndividuals who did not have health insurance coverage for the entire calendar year were classified as uninsured. The uninsured were defined as people not covered by Medicaid, Medicare, TRICARE (Armed Forces-related coverage), other public hospital/physician programs, private hospital/physician insurance (including Medigap coverage) or insurance purchased through health insurance Marketplaces. People covered only by non-comprehensive State-specific programs (e.g., Maryland Kidney Disease Program) or private single service plans such as coverage for dental or vision care only, or coverage for accidents or specific diseases, were considered uninsured.\n<\/li>\n\n<li><i>Any private:<\/i>\nIndividuals classified as having any private health insurance coverage had private insurance that provided coverage for hospital and physician care (including Medigap coverage and TRICARE) at some point during the year.<\/li>\n\n<li><i>Public only:<\/i>\nIndividuals are considered to have public only health insurance coverage if they were not covered by private insurance or TRICARE and they were covered by Medicare, Medicaid, or other public hospital and physician coverage at some point during the year.<\/li>\n\n<li><i>65+, No Medicare:<\/i>\nIndividuals classified as <i>65+, No Medicare<\/i> either had private coverage at some point during the year that is not identified as Medigap coverage or were uninsured throughout the year.<\/li>\n<\/ul>\n","ins_lt65":"\n<h4>Insurance coverage<\/h4>\n<ul>\n<li><i>Uninsured:<\/i>\nIndividuals who did not have health insurance coverage for the entire calendar year were classified as uninsured. The uninsured were defined as people not covered by Medicaid, Medicare, TRICARE (Armed Forces-related coverage), other public hospital/physician programs, private hospital/physician insurance (including Medigap coverage) or insurance purchased through health insurance Marketplaces. People covered only by non-comprehensive State-specific programs (e.g., Maryland Kidney Disease Program) or private single service plans such as coverage for dental or vision care only, or coverage for accidents or specific diseases, were considered uninsured.\n<\/li>\n\n<li><i>Any private:<\/i>\nIndividuals classified as having any private health insurance coverage had private insurance that provided coverage for hospital and physician care (including Medigap coverage and TRICARE) at some point during the year.<\/li>\n\n<li><i>Public only:<\/i>\nIndividuals are considered to have public only health insurance coverage if they were not covered by private insurance or TRICARE and they were covered by Medicare, Medicaid, or other public hospital and physician coverage at some point during the year.<\/li>\n\n<li><i>65+, No Medicare:<\/i>\nIndividuals classified as <i>65+, No Medicare<\/i> either had private coverage at some point during the year that is not identified as Medigap coverage or were uninsured throughout the year.<\/li>\n<\/ul>\n","insurance":"\n<h4>Insurance coverage<\/h4>\n<ul>\n<li><i>Uninsured:<\/i>\nIndividuals who did not have health insurance coverage for the entire calendar year were classified as uninsured. The uninsured were defined as people not covered by Medicaid, Medicare, TRICARE (Armed Forces-related coverage), other public hospital/physician programs, private hospital/physician insurance (including Medigap coverage) or insurance purchased through health insurance Marketplaces. People covered only by non-comprehensive State-specific programs (e.g., Maryland Kidney Disease Program) or private single service plans such as coverage for dental or vision care only, or coverage for accidents or specific diseases, were considered uninsured.\n<\/li>\n\n<li><i>Any private:<\/i>\nIndividuals classified as having any private health insurance coverage had private insurance that provided coverage for hospital and physician care (including Medigap coverage and TRICARE) at some point during the year.<\/li>\n\n<li><i>Public only:<\/i>\nIndividuals are considered to have public only health insurance coverage if they were not covered by private insurance or TRICARE and they were covered by Medicare, Medicaid, or other public hospital and physician coverage at some point during the year.<\/li>\n\n<li><i>65+, No Medicare:<\/i>\nIndividuals classified as <i>65+, No Medicare<\/i> either had private coverage at some point during the year that is not identified as Medigap coverage or were uninsured throughout the year.<\/li>\n<\/ul>\n","poverty":"\n<h4>Poverty status<\/h4>\n<p>Each sample person was classified according to the total annual income of his or her family. Possible sources of income included annual earnings from wages, salaries, bonuses, tips, and commissions; business and farm gains and losses; unemployment and Worker's Compensation; interest and dividends; alimony, child support, and other private cash transfers; private pensions, individual retirement account (IRA) withdrawals, Social Security, and Department of Veterans Affairs payments; Supplemental Security Income and cash welfare payments from public assistance, Aid to Families with Dependent Children and Aid to Dependent Children; gains or losses from estates, trusts, partnerships, S corporations, rent, and royalties; and a small amount of 'other' income. Poverty status is the ratio of family income to the corresponding federal poverty thresholds, which control for family size and age of the head of family. Categories are defined as follows:<\/p>\n<ul>\n  <li><i>Negative or Poor<\/i>: Household income below the Federal poverty line.<\/li>\n\n  <li><i>Near poor<\/i>: Household income over the poverty line through 125 percent of the poverty line.<\/li>\n\n  <li><i>Low income<\/i>: Household income 125 percent through 200 percent of the poverty line.<\/li>\n\n  <li><i>Middle income<\/i>: over 200 percent to 400 percent of the poverty line.<\/li>\n\n  <li><i>High income<\/i>: over 400 percent of the poverty line.<\/li>\n<\/ul>\n","racesex":"\n<h4>Race/ethnicity<\/h4>\n<p>Classification by race and ethnicity is based on information reported for each family member. Starting in 2002, specifications changed so that individuals could report multiple races. Respondents were asked if the race of the sample person was best described as American Indian, Alaska Native, Asian or Pacific Islander, black, white, or other. Prior to 2002, race categories in the tables for American Indian, Alaska Native, Asian or Pacific Islander, multiple races, white, and other are collapsed into the single category of <i>White and other<\/i>.<\/p>\n\n<p>For all years, respondents were asked if the sample person's main national origin or ancestry was Puerto Rican; Cuban; Mexican, Mexicano, Mexican American, or Chicano; other Latin American; or other Spanish. All persons whose main national origin or ancestry was reported in one of these Hispanic groups, regardless of racial background, are classified as Hispanic. Since the Hispanic grouping can include black Hispanic, white Hispanic, and other Hispanic, the race categories of black, white, and other do not include Hispanic people.<\/p>\n","race":"\n<h4>Race/ethnicity<\/h4>\n<p>Classification by race and ethnicity is based on information reported for each family member. Starting in 2002, specifications changed so that individuals could report multiple races. Respondents were asked if the race of the sample person was best described as American Indian, Alaska Native, Asian or Pacific Islander, black, white, or other. Prior to 2002, race categories in the tables for American Indian, Alaska Native, Asian or Pacific Islander, multiple races, white, and other are collapsed into the single category of <i>White and other<\/i>.<\/p>\n\n<p>For all years, respondents were asked if the sample person's main national origin or ancestry was Puerto Rican; Cuban; Mexican, Mexicano, Mexican American, or Chicano; other Latin American; or other Spanish. All persons whose main national origin or ancestry was reported in one of these Hispanic groups, regardless of racial background, are classified as Hispanic. Since the Hispanic grouping can include black Hispanic, white Hispanic, and other Hispanic, the race categories of black, white, and other do not include Hispanic people.<\/p>\n"};
