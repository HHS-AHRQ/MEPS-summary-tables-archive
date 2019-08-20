var isPivot = false; var initCols = [
                      { title: "Year", className: "sub", "visible": false},
                      { title: "row_var", className: "sub", "visible": false},
                      { title: "rowLevels" , className: "main"},
                      { title: "rowLevNum" , className: "sub", "visible": false},
                      { title: "selected",   className: "sub", "visible" : false},
                      
                  {title: "", className: "coef", searchable: false, render: coefDisplay},

                {title: "", className: "se", searchable: false, render: seDisplay},

                  {title: "", className: "coef", searchable: false, render: coefDisplay},

                {title: "", className: "se", searchable: false, render: seDisplay},

                  {title: "", className: "coef", searchable: false, render: coefDisplay},

                {title: "", className: "se", searchable: false, render: seDisplay},

                  {title: "", className: "coef", searchable: false, render: coefDisplay},

                {title: "", className: "se", searchable: false, render: seDisplay},

                  {title: "", className: "coef", searchable: false, render: coefDisplay},

                {title: "", className: "se", searchable: false, render: seDisplay},

                  {title: "", className: "coef", searchable: false, render: coefDisplay},

                {title: "", className: "se", searchable: false, render: seDisplay},

                  {title: "", className: "coef", searchable: false, render: coefDisplay},

                {title: "", className: "se", searchable: false, render: seDisplay},

                  {title: "", className: "coef", searchable: false, render: coefDisplay},

                {title: "", className: "se", searchable: false, render: seDisplay},

                  {title: "", className: "coef", searchable: false, render: coefDisplay},

                {title: "", className: "se", searchable: false, render: seDisplay},

                  {title: "", className: "coef", searchable: false, render: coefDisplay},

                {title: "", className: "se", searchable: false, render: seDisplay},

                  {title: "", className: "coef", searchable: false, render: coefDisplay},

                {title: "", className: "se", searchable: false, render: seDisplay},

                  {title: "", className: "coef", searchable: false, render: coefDisplay},

                {title: "", className: "se", searchable: false, render: seDisplay},

                  {title: "", className: "coef", searchable: false, render: coefDisplay},

                {title: "", className: "se", searchable: false, render: seDisplay},

                  {title: "", className: "coef", searchable: false, render: coefDisplay},

                {title: "", className: "se", searchable: false, render: seDisplay},

                  {title: "", className: "coef", searchable: false, render: coefDisplay},

                {title: "", className: "se", searchable: false, render: seDisplay},

                  {title: "", className: "coef", searchable: false, render: coefDisplay},

                {title: "", className: "se", searchable: false, render: seDisplay},

                  {title: "", className: "coef", searchable: false, render: coefDisplay},

                {title: "", className: "se", searchable: false, render: seDisplay},

                  {title: "", className: "coef", searchable: false, render: coefDisplay},

                {title: "", className: "se", searchable: false, render: seDisplay},

                  {title: "", className: "coef", searchable: false, render: coefDisplay},

                {title: "", className: "se", searchable: false, render: seDisplay},

                  {title: "", className: "coef", searchable: false, render: coefDisplay},

                {title: "", className: "se", searchable: false, render: seDisplay},

                  {title: "", className: "coef", searchable: false, render: coefDisplay},

                {title: "", className: "se", searchable: false, render: seDisplay}]; var initLevels = {"adult_explain":{"adult_explainA":"Always","adult_explainB":"Usually","adult_explainC":"Sometimes/Never","adult_explainD":"Don't know/Non-response"},"adult_illness":{"adult_illnessA":"Always","adult_illnessB":"Usually","adult_illnessC":"Sometimes/Never","adult_illnessD":"Don't know/Non-response"},"adult_listen":{"adult_listenA":"Always","adult_listenB":"Usually","adult_listenC":"Sometimes/Never","adult_listenD":"Don't know/Non-response"},"adult_respect":{"adult_respectA":"Always","adult_respectB":"Usually","adult_respectC":"Sometimes/Never","adult_respectD":"Don't know/Non-response"},"adult_routine":{"adult_routineA":"Always","adult_routineB":"Usually","adult_routineC":"Sometimes/Never","adult_routineD":"Don't know/Non-response"},"adult_time":{"adult_timeA":"Always","adult_timeB":"Usually","adult_timeC":"Sometimes/Never","adult_timeD":"Don't know/Non-response"},"child_explain":{"child_explainA":"Always","child_explainB":"Usually","child_explainC":"Sometimes/Never","child_explainD":"Don't know/Non-response"},"child_illness":{"child_illnessA":"Always","child_illnessB":"Usually","child_illnessC":"Sometimes/Never","child_illnessD":"Don't know/Non-response"},"child_listen":{"child_listenA":"Always","child_listenB":"Usually","child_listenC":"Sometimes/Never","child_listenD":"Don't know/Non-response"},"child_respect":{"child_respectA":"Always","child_respectB":"Usually","child_respectC":"Sometimes/Never","child_respectD":"Don't know/Non-response"},"child_routine":{"child_routineA":"Always","child_routineB":"Usually","child_routineC":"Sometimes/Never","child_routineD":"Don't know/Non-response"},"child_time":{"child_timeA":"Always","child_timeB":"Usually","child_timeC":"Sometimes/Never","child_timeD":"Don't know/Non-response"},"adult_nosmok":{"adult_nosmokA":"Told to quit","adult_nosmokB":"Not told to quit"},"child_dental":{"child_dentalA":"One or more dental visits","child_dentalB":"No dental visits in past year"},"diab_a1c":{"diab_a1cA":"Had measurement","diab_a1cB":"Did not have measurement","diab_a1cC":"Don't know/Non-response"},"diab_chol":{"diab_cholA":"In the past year","diab_cholB":"More than 1 year ago","diab_cholC":"Never had cholesterol checked","diab_cholD":"Don't know/Non-response"},"diab_eye":{"diab_eyeA":"In the past year","diab_eyeB":"More than 1 year ago","diab_eyeC":"Never had eye exam","diab_eyeD":"Don't know/Non-response"},"diab_flu":{"diab_fluA":"In the past year","diab_fluB":"More than 1 year ago","diab_fluC":"Never had flu shot","diab_fluD":"Don't know/Non-response"},"diab_foot":{"diab_footA":"In the past year","diab_footB":"More than 1 year ago","diab_footC":"No exam in past year","diab_footD":"Never had feet checked","diab_footE":"Don't know/Non-response"},"difficulty":{"difficultyA":"Any care","difficultyB":"Medical care","difficultyC":"Dental care","difficultyD":"Prescription medicines"},"education":{"educationB":"Less than high school","educationC":"High school","educationD":"Some college","educationE":"Inapplicable (age < 18)"},"employed":{"employedB":"Employed","employedC":"Not employed","employedD":"Inapplicable (age < 16)"},"married":{"marriedB":"Inapplicable (age < 16)","marriedC":"Married","marriedD":"Widowed","marriedE":"Divorced","marriedF":"Separated","marriedG":"Never married"},"health":{"healthB":"Excellent","healthC":"Very good","healthD":"Good","healthE":"Fair","healthF":"Poor"},"mnhlth":{"mnhlthB":"Excellent","mnhlthC":"Very good","mnhlthD":"Good","mnhlthE":"Fair","mnhlthF":"Poor"},"insurance":{"insuranceB":"Any private, all ages","insuranceC":"Public only, all ages","insuranceD":"Uninsured, all ages"},"poverty":{"povertyB":"Negative or poor","povertyC":"Near-poor","povertyD":"Low income","povertyE":"Middle income","povertyF":"High income"},"race":{"raceB":"Hispanic","raceC":"White","raceD":"Black","raceE":"Amer. Indian, AK Native, or mult. races","raceF":"Asian, Hawaiian, or Pacific Islander"},"region":{"regionB":"Northeast","regionC":"Midwest","regionD":"South","regionE":"West"},"rsn_ANY":{"rsn_ANYA":"Couldn't afford","rsn_ANYB":"Insurance related","rsn_ANYC":"Other"},"rsn_DN":{"rsn_DNA":"Couldn't afford","rsn_DNB":"Insurance related","rsn_DNC":"Other"},"rsn_MD":{"rsn_MDA":"Couldn't afford","rsn_MDB":"Insurance related","rsn_MDC":"Other"},"rsn_PM":{"rsn_PMA":"Couldn't afford","rsn_PMB":"Insurance related","rsn_PMC":"Other"},"sex":{"sexB":"Male","sexC":"Female"},"usc":{"uscA":"No usual source of health care","uscB":"Office-based","uscC":"Hospital (not ER)","uscD":"Emergency room"},"agegrps":{"agegrpsB":"Under 18","agegrpsE":"18-64","agegrpsH":"65+"},"adult_rating":{"adult_ratingA":"9-10 rating","adult_ratingB":"7-8 rating","adult_ratingC":"0-6 rating","adult_ratingD":"Don't know/Non-response"},"child_rating":{"child_ratingA":"9-10 rating","child_ratingB":"7-8 rating","child_ratingC":"0-6 rating","child_ratingD":"Don't know/Non-response"}}; var subLevels = ["Physician office visits","Physician outpatient visits"];
