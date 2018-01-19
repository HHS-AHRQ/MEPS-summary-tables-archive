isPivot = true; initCols = [
      { title: "Year",   className: "sub", "visible": false},
      { title: "rowGrp", className: "sub", "visible": false},
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

      {title: "", className: "se", searchable: false, render: seDisplay}]; initLevels = []; subLevels = ["Physician office visits","Non-physician office visits","Physician hosp. visits","Non-physician hosp. visits"]; adjustStat = {totPOP: 'in thousands', totEXP: 'in millions', totEVT: 'in thousands', meanEVT: '', meanEXP: '', meanEXP0: '', medEXP: '', pctEXP: '', pctPOP: '', avgEVT: ''};
