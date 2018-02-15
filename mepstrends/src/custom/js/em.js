// Table of contents:
//
// Interactive functionality --------------------------------------------------
// Data tables initialization -------------------------------------------------
//
// DATA: update ---------------------------------------------------------------
// Levels selection -----------------------------------------------------------
// Row highlighting - Pivot tables only ---------------------------------------
// Show SEs (+check control totals) -------------------------------------------
//
// TABLE TAB ------------------------------------------------------------------
//  Export table to csv
//
// PLOT TAB -------------------------------------------------------------------
//  Export plot to png
//
// CODE TAB -------------------------------------------------------------------
//  Export code to text files
//
// Caption, Citation, Notes ---------------------------------------------------
// Trigger --------------------------------------------------------------------

$(document).ready(function() {

  /* Do not do this
  $.ajaxSetup({ async: false });
  */

$('#meps-table').hide(); // hide until new data is imported

// Interactive functionality --------------------------------------------------

  var isTrend = true;
  $('#data-view').change(function(){
    isTrend = $(this).find('input[value="trend"]').is(':checked');
    if(isTrend){
      $('.hide-if-trend').slideUp('slow');
      $('.year-start').animate({width: '100%'},400);
      $('.year-main label').text('to:');
    }else{
      $('.hide-if-trend').slideDown('slow');
      $('.year-start').animate({width:'0%'},400);
      $('.year-main label').text('Year:');
    }
  });

  // Prevent 'reset' button from closing dropdown
  $('.dropdown-menu').on('click', function(e) {
    if($(this).hasClass('dropdown-menu-form')) { e.stopPropagation(); }
  });

  // Custom search box
  $('#search').on('keyup change', function() {
    table.column(2).search($(this).val()).draw();
  });

  // Reactivity based on active tab
  var activeTab = 'table-pill';
  $('#meps-tabs li a').on('click', function(){
    // guard against plotting when disabled
    if(!$(this).hasClass('disabled')) { activeTab = $(this).attr('id'); }
    switch(activeTab) {
      case 'table-pill': $(document).trigger("updateTable"); break;
      case 'plot-pill' : $(document).trigger("updatePlot");  break;
      case 'code-pill' : $(document).trigger("updateCode");  break;
    }
  });

// Data tables initialization -------------------------------------------------
  // Options that we're not using:
    //scrollY: "500px", scrollX: true, scrollCollapse: true,
    //paging: isPivot, // this will slow initiation
    //select: {style: 'multi'},
    //autoWidth: true,
    //deferRender: true,
    //searching: false,

// var table = $('#meps-table').DataTable();

  // Get year range
  var nrows = 0;
  $("#year option").each(function(){nrows = nrows + 1;});

  // Initiate data tables
  var ncols = initCols.length;
  var selectedLevels = Object.assign({}, initLevels);
  var initData = [Array.apply(null, Array(ncols)).map(function(x) {return null;})];
  var table = $('#meps-table').DataTable( {
      data: initData,
      dom: 'lrtp',
      orderClasses: false,
      lengthChange: false,
      ordering: isPivot,
      pageLength: isPivot ? 10 : nrows,
      columns: initCols
    });

  $('.dataTable').wrap('<div class="dataTables_scroll" />');
  $('#loading').hide();
  $('#dl-table').show();

  if(!isPivot) {
    $('.dataTables_paginate').addClass('hidden');
  }

// DATA: update ---------------------------------------------------------------
  var newData, colNames, colClasses, stat, colGrp, colX, rowGrp, rowX;
  var year, yearStart, rowYears, colYears;
  var rcEqual = false, highlightedRows = {};

  $('#stat, #colGrp, #rowGrp, #year, #year-start, #data-view').on('change', function() {
    $(document).trigger("updateValues");
  });

  $(document).on('updateValues', function() {
    stat = $('#stat').val();

    year = $('#year').val();
    yearStart = $('#year-start').val();
    var yearsRegex = range(yearStart, year).join("|");
    var yrX  = isTrend ? yearsRegex : year;
    rowYears = isPivot ? 'All': yrX;
    colYears = isPivot ? yrX : '__';

    colGrp = $('#colGrp').val();
    colX = isTrend &&  isPivot ? 'ind' : colGrp;

    rowGrp = $('#rowGrp').val();
    rowX = isTrend && !isPivot ? 'ind' : rowGrp;

    rcEqual = (rowX == colX && rowX != 'ind');
    if(rcEqual) { rowX = 'ind'; }

    $(document).trigger("updateData");
    if(activeTab == 'code-pill'){ $(document).trigger("updateCode"); }
  });

  var colLevels = {}, rowLevels = {};

  $(document).on('updateData', function() {
    $('#updating-overlay').show();
    var filename = 'json/data/' + stat + '__' + rowX + '__' + colX + '.json';
    $.getJSON(filename, function(data) {
      $('#updating-overlay').hide();
      newData = data.data;
      var newNames = data.names;
      var newClasses = data.classes;

      // Subset to year cols (for pivot)
      var showCols = grepIndexes(newClasses, [colYears], force = [0, 1, 2, 3, 4]);
      colNames = selectIndexes(newNames, showCols);
      colClasses = selectIndexes(newClasses, showCols);

      // Update table
      var subData = selectCols(newData, showCols);
      subData.map(function(x) {return fill(x, ncols);});
      table.clear().rows.add(subData);

      // Add highlighted rows from cache (for pivot)
      var hlRows = highlightedRows[rowX];
      if(hlRows !== undefined) {
        table.rows().every(function() {
          if(hlRows.includes(this.data()[2])){ this.select(); }
        });
      }

      // Get row indexes that include shown years
      var yrIndexes = table.rows().eq(0).filter(function(idx) {
        var yr = table.cell(idx, 0).data();
        return rowYears.includes(yr) ? true: false;
      });

      // Edit column names and generate colLevels
      colLevels = {};
      var tabCols = table.columns().header().toJQuery();
      tabCols.each( function(index) {
        if(colNames[index] === undefined) {
          $(this).removeClass("showDT");
        } else {
          $(this).addClass("showDT");
          $(this).text(colNames[index]);

           // Generate colLevels
           if($(this).hasClass('coef')) {
              colData = table.cells(yrIndexes, index).data().toArray();
              skip_missing_cols = (appKey == 'use' && colData.every(isNull));
              if(!skip_missing_cols) {
                var colNm = colNames[index];
                var colKey = colClasses[index].split("__")[1];
                colLevels[colKey]  = colNm;
              }
           }
        }
      });

      // Change group column name
      var grpName = rowX == 'ind' ? 'Year' : $('#rowGrp option:selected').text();
      table.columns(2).header().toJQuery().text(grpName);

      // For 'use' app, convert header to statistic label if no colgrp selected
      var colgrpName = $('#stat option:selected').text();
      if(colGrp == 'ind' && !isPivot) {
         table.columns(5).header().toJQuery().text(colgrpName);
         table.columns(6).header().toJQuery().text(colgrpName);
      }

      // Select rows by year and generate rowLevels;
      table.columns(0).search(rowYears, true, false);
      rowLevels = {};
      table.rows(yrIndexes).every( function(index) {
        var el = this.data();
        var rowKey = el[3], rowNm = el[2];
        rowLevels[rowKey] = rowNm;
      });

      $(document).trigger('updateRowLevels');
      $(document).trigger('updateColLevels');

      selectColLevels(table, colLevels, selectedLevels, colX, colNames);
      selectRowLevels(table, rowLevels, selectedLevels, rowX);

     $(document).trigger("newHighlighted");
     $(document).trigger("checkControlTotals");
     $(document).trigger('updateNotes');

      $('#meps-table').show();
    });
  });


// Levels selection -----------------------------------------------------------

    // Switch rows and cols (use app only)
    $('#switchRC').on('click', function() {
      var currentRow = $('#rowGrp').val();
      var currentCol = $('#colGrp').val();
      $('#colGrp').val(currentRow);
      $('#rowGrp').val(currentCol);
      $(document).trigger('updateValues');
    });

    // Update levels checkbox groups
    $(document).on('updateRowLevels', function() {
       createCheckboxGroup('row', rowLevels, selectedLevels[rowGrp]);
       if(rowGrp == 'ind' || rcEqual) {
         $('#rowDrop').slideUp('fast');
       } else {
         $('#rowDrop').slideDown('fast');
       }
    });
    $(document).on('updateColLevels', function() {
       createCheckboxGroup('col', colLevels, selectedLevels[colGrp]);
       if (colGrp == 'ind') {
         $('#colDrop').slideUp('fast');
       } else {
         $('#colDrop').slideDown('fast');
       }
    });

    // Reset checkboxes
    $('#rowReset').on('click', function() {
      createCheckboxGroup('row', rowLevels, initLevels[rowGrp]);
      $(document).trigger("selectRowLevels");
    });
    $('#colReset').on('click', function() {
       createCheckboxGroup('col', colLevels, initLevels[colGrp]);
       $(document).trigger("selectColLevels");
    });

    // Cache selected levels on click
    $('#rowLevels ul').on('click', function() { $(document).trigger("selectRowLevels");});
    $('#colLevels ul').on('click', function() { $(document).trigger("selectColLevels");});

    // Search rows based on selected levels
    $(document).on("selectRowLevels", function() {
      var checkedLevels = checkList('#rowLevels');
      var currentSelected = selectedLevels[rowGrp];
      var hidden = notIn(currentSelected, rowLevels);
      $.extend(checkedLevels, hidden);

      selectedLevels[rowGrp] = checkedLevels;
      selectRowLevels(table, rowLevels, selectedLevels, rowX);
      if(activeTab == 'table-pill') { $(document).trigger("updateTable");}
      if(activeTab == 'plot-pill')  { $(document).trigger("updatePlot");}
      $(document).trigger('updateNotes');
    });

    // Show/hide columns based on selected levels
    $(document).on("selectColLevels", function() {
      var checkedLevels = checkList('#colLevels');
      var currentSelected = selectedLevels[colGrp];
      var hidden = notIn(currentSelected, colLevels);
      $.extend(checkedLevels, hidden);

      selectedLevels[colGrp] = checkedLevels;
      selectColLevels(table, colLevels, selectedLevels, colX, colNames);
      if(activeTab == 'table-pill') { $(document).trigger("updateTable"); }
      if(activeTab == 'plot-pill')  { $(document).trigger("updatePlot");}
      $(document).trigger('updateNotes');
    });

    // Prevent unchecking all group levels
    $('#rowLevels ul').on("click", "li input", function(e) {
      var n_checked = $('#rowLevels').find('input:checked').length;
      var this_checked = $(this).is(":checked");
      if(!this_checked && n_checked === 0) {
        e.preventDefault();
        return false;
      }
    });

    $('#colLevels ul').on("click", "li input", function(e) {
      var n_checked = $('#colLevels').find('input:checked').length;
      var this_checked = $(this).is(":checked");
      if(!this_checked && n_checked === 0) {
        e.preventDefault();
        return false;
      }
    });


// Row highlighting - Pivot tables only ---------------------------------------

  if(isPivot) {
    var nSelected = 0;
    $('#plot-pill').attr('data-toggle','');
    $('#plot-pill').addClass('disabled');

    // Highlight selected rows
    $('#meps-table tbody').on('click', 'tr', function () {
      // Limit to 10 selections
      if(nSelected < 10 || $(this).hasClass('selected')) {
        $(this).toggleClass('selected');
      }
      $(document).trigger('newHighlighted');
      if(activeTab == 'plot-pill') { $(document).trigger("updatePlot");}
    });

    // Clear selected rows
    $('#deselect').on('click', function() {
    //  table.cells('.selected', 4).every(function(el) {this.data(0);});
      table.rows().deselect();
      $(document).trigger('newHighlighted');
      if(activeTab == 'plot-pill') { $(document).trigger("updatePlot");}
    });

    // Update cached selection
    $(document).on('newHighlighted', function() {
      table.cells('', 4).every(function(el) {this.data(0);});
      table.cells('.selected', 4).every(function(el) { this.data(1); });
      highlightedRows[rowX] = table.cells('.selected', 2).data().toArray();
    });

    // Sort by selected rows
    $('#sort-selected').on('click', function() {
      order_col = 'selected';
      order_dir = 'desc';
      $(document).trigger("updateTable");
    });

    // Disable or enable plot tab based on selected rows
    $(document).on('newHighlighted',function() {
      nSelected = table.rows('.selected').count();
      if(nSelected === 0){
        $('#plot-pill').attr('data-toggle','');
        $('#plot-pill').addClass('disabled');
        $('#select-rows-message').show();
        $('#meps-plot').hide();
      } else {
        $('#plot-pill').attr('data-toggle','tab');
        $('#plot-pill').removeClass('disabled');
        $('#select-rows-message').hide();
        $('#meps-plot').show();
      }
      $(document).trigger("updateNotes"); // for plot footnotes
    });

  } // end of ifPivot -- row highlighting


// Show SEs (+check control totals) -------------------------------------------
    var checkedSEs = false, showSEs = false, ctype = '.coef', controlTotals = false;
    $('#showSEs').on('change', function() {
      checkedSEs =  $('#showSEs').is(":checked");
      $(document).trigger("checkControlTotals");
    });

    // Update control totals message
    $(document).on('checkControlTotals', function() {
      var ctVars = ['ind', 'agegrps', 'race', 'sex', 'poverty', 'region'];

      controlTotals = (ctVars.includes(rowX) && ctVars.includes(colX) && stat == 'totPOP');
      if(checkedSEs && controlTotals) {
        showSEs = false;
        $('#control-totals').slideDown('fast');
      } else {
        showSEs = checkedSEs;
        $('#control-totals').slideUp('fast');
      }

      ctype = showSEs ? '.se' : '.coef';
      $(document).trigger("updateNotes");
      if(activeTab == 'table-pill') { $(document).trigger("updateTable");}
      if(activeTab == 'plot-pill')  { $(document).trigger("updatePlot");}
    });


// TABLE TAB ------------------------------------------------------------------
  var order_col = undefined, order_dir = 'asc';
  $('#meps-table thead').on('click', 'th', function () {
    order_col = $(this).text();
    order_dir = table.order()[0][1];
  });

  // Redraw table
  $(document).on("updateTable", function() {
    // Get ordering column if applicable
    if(isPivot) {
      var order_index = table.columns().header().toJQuery().map(function(el) {
        if($(this).text() == order_col) { return(el); }
      })[0];

      if(order_index === undefined) {
        order_index = 2; // row category
        order_dir = 'asc';
      }
      table.order([order_index, order_dir]);
    }

    table
     .columns().visible(false)
     .columns('.main, .showDT'+ctype).visible(true)
     .draw();
  });

  // Export table to csv --------------------------
  $('#dl-table').on('click', function() {
    var coefCols = table.columns('.main, .showDT.coef', {search : 'applied'}).data().toArray();
    var seCols   = table.columns('.main, .showDT.se', {search : 'applied'}).data().toArray();

    var coefRows = transpose(coefCols).map(function(el) { return el.map(formatNum);});
    var seRows   = transpose(seCols).map(function(el) { return el.map(formatNum);});

    var headers = table.columns('.main, .showDT.coef').header().toJQuery();
    var cNames  = headers.map(function() {return $(this).text();}).toArray();

    var coefCSV = convertArrayOfObjectsToCSV({data: coefRows, colnames: cNames});
    var seCSV   = convertArrayOfObjectsToCSV({data: seRows, colnames: cNames});

    var seCaption = "Standard errors for " +
        newCaption.charAt(0).toLowerCase() + newCaption.slice(1);

    if(controlTotals) {
      seCaption = $('#control-totals').text();
      seCSV = "";
    }

    var dlSource = newSource.replace('<b>','').replace('</b>','');

    var csv = $.grep(
      ['"'+newCaption.replace(" (standard errors)","")+'"', coefCSV,
       '"'+seCaption.replace(" (standard errors)","") +'"', seCSV,
       $('#suppress').text(),
       $('#RSE').text(),
       '"'+dlSource+'"'], Boolean).join("\n");

    downloadFile({file: csv, filename: 'meps-table-' + shortDate() + '.csv'});
  });


// PLOT TAB -------------------------------------------------------------------
  var plotFootnotes;

  var config = {
    fillframe: true,
    displayModeBar: false,
    displaylogo: false,
    modeBarButtonsToRemove: ['toImage','sendDataToCloud', 'zoom2d', 'pan2d',
    'select2d', 'lasso2d', 'zoomIn2d', 'zoomOut2d', 'autoScale2d',
    'resetScale2d', 'hoverClosestCartesian', 'hoverCompareCartesian',
    'hoverClosest3d', 'toggleSpikelines']
  };

  var meps_source = {
      xref: 'paper', x: 0, xanchor: 'left',
      yref: 'paper', y: -0.16, yanchor: 'bottom',
      showarrow: false, font: {size: 12}, align: 'left',
      text: 'MEPS' , visible: true
    };

  var legend_title = {
      xref: 'paper', x: 1.02, xanchor: 'left',
      yref: 'paper', y: 1, yanchor: 'top',
      showarrow: false, font: {size: 12}, align: 'left',
      text: 'Legend title'
    };

  // Change plot height depending on needed height for legend
  var layout = {
    width: 700, height: 600, autosize: true, hovermode: 'closest',
    font: {family: "Arial", size: 12},
    margin: {l: 100, r: 50, b: 110, t: 100},
    legend: {y: 0.92, tracegroupgap: 5, traceorder: 'grouped'}
  };

  $(document).on('updatePlot', function() {
    var headers = table.columns('.showDT.coef').header().toJQuery();
    var x, y, y_se, y_names, labelRows, hideLegend, hideYaxis, plotTraces;

    if(isPivot) {
      // if pivot, use selected rows only and transpose data
       var coef_cols = table.columns('.showDT.coef', {order: 'index'}).data().toArray();
       var se_cols   = table.columns('.showDT.se',   {order: 'index'}).data().toArray();
       selectedIndexes  = table.rows('.selected').indexes();

      x  = headers.map(function() {return $(this).text();}).toArray();
      y  = selectRows(transpose(coef_cols), selectedIndexes);
      y_se = selectRows(transpose(se_cols), selectedIndexes);
      y_names = table.cells('.selected', 2).data().toArray();

    } else {
      x  = table.columns(2, {search : 'applied'}).data().toArray()[0];
      y  = table.columns('.showDT.coef', {search : 'applied'}).data().toArray();
      y_se = table.columns('.showDT.se', {search : 'applied'}).data().toArray();
      y_names  = headers.map(function() {return $(this).text();}).toArray();
    }

    x = x.map(editLabel);
    y_names = y_names.map(editLabel);

    var legendText = isPivot ? colName : rowName;
    var legendTitle = camelCase(wrap(legendText, 20));
    var hoverfmt = stat.slice(0,3) == 'pct' ? '0,.1f' : '0,.0f';

    if(isTrend) {
      plotTraces = linePlotData(
        x_values = x,
        y_values = y,
        y_ses = y_se,
        y_labels = y_names,
        showSEs = showSEs);

      labelRows = countBreaks(y_labels);
      hideLegend = (rowX == 'ind' && colX == 'ind');
      hideYaxis = false;
      layout.yaxis = {tickformat: '0,.5', hoverformat: hoverfmt};
      layout.margin.l = 60;
      layout.xaxis = x.length < 5 ? {tickvals: x_values} : {};

    } else {
      plotTraces = barPlotData(
        x_values = y_names,
        y_values = transpose(y),
        y_ses = transpose(y_se),
        y_labels = x,
        showSEs = showSEs);

      labelRows = Math.max(countBreaks(y_labels), countBreaks(x_values));
      hideLegend = isPivot ? (colX == 'ind') : (rowX == 'ind');
      hideYaxis  = isPivot ? (rowX == 'ind') : (colX == 'ind');
      layout.xaxis = {showline: false, zeroline: false, hoverformat: hoverfmt, tickformat: '0,.5'};
      layout.yaxis = {autorange: 'reversed', //visible: !hideYaxis,
        showline: false, zeroline: false, showticklabels: false};
      layout.margin.l = hideYaxis? 20 : 140;
    }

    layout.xaxis.fixedrange = true;
    layout.yaxis.fixedrange = true;

    if(plotTraces === null) {
      $('.plot-dependent').hide();
      $('#plot-warning').show();

    } else {
      var plotData = plotTraces.data;
      var ylabels  = hideYaxis ? null : plotTraces.ylabels;

      var extraHeight = Math.max(0, (labelRows-16)*30);
      layout.height = 600 + extraHeight;

      layout.title =  wrap70(plotCaption);
      layout.showlegend = !hideLegend;
      layout.annotations = [meps_source, legend_title].concat(ylabels);
      //layout.annotations[0].visible = false;

      // Need to remove <b> tags for IE to work, for some reason
      var pltSource = newSource.replaceAll('<b>','').replaceAll('</b>','');
      var pltFoot = plotSuppress ? $('#plot-suppress').text()+"<br>" : "";

      plotFootnotes = pltFoot + wrap(pltSource, 100);

      layout.annotations[0].text = plotFootnotes;
      layout.annotations[0].visible = false;
      layout.annotations[1].text = legendTitle;

      $('.plot-dependent').show();
      $('#plot-warning').hide();
      Plotly.newPlot('meps-plot', plotData, layout, config);
    }
  });

  // Export plot to png ---------------------------

  $('#dl-plot').on('click', function() {
    var fName = 'meps-plot-' + shortDate();
    layout.annotations[0].visible = true;
    downloadPlot({filename: fName, footnotes: plotFootnotes, height: layout.height});
    layout.annotations[0].visible = false;
  });


// CODE TAB -------------------------------------------------------------------
  var codeText, lang = "R";

  $('#code-language').on("change", function(){
    lang = $('#code-language').val();
    $(document).trigger('updateCode');
  });

  $(document).on('updateCode', function() {
    var row = rowX, col = colX;
    var rowD = row.split("_")[0];
    var colD = col.split("_")[0];

    var grps = [row, col];

    var is_evt_stat = ['meanEVT','avgEVT','totEVT'].includes(stat);

    var is_evt = grps.includes('event');
    var is_sop = grps.includes('sop');
    var sKey = (is_evt && is_sop) ? ['event_sop'] : grps;

    /*
    dsgn
      - demo, event, sop, default
      - adult, diab, demo
      - RXDRGNAM, TC1name

    stats
      - demo, event, sop, event_sop
      - insurance, ins_lt65, ins_gt65
      - adult_explain, child_listen, diab_foot,...
      - RXDRGNAM, TC1name
    */

    var dsgnKey = intersection([rowD, colD], getKeys(dsgnCode)).filter(unique).join('');
    var statKey = intersection(sKey, getKeys(statCode)).filter(unique).join('');

    if(dsgnKey === "") {dsgnKey = "demo";}
    if(statKey === "") {statKey = "demo";}

     var loadC = get(loadCode, [lang, stat]);
     var rowC  = ['event', 'sop'].includes(row) && is_evt_stat ? '' : get(grpCode, [lang, row]);
     var colC  = ['event', 'sop'].includes(col) && is_evt_stat ? '' : get(grpCode, [lang, col]);

     var grpC  = is_evt && is_sop && !is_evt_stat ?
        get(grpCode, [lang, 'event_sop']) :
        [colC, rowC].filter(unique).join("\n");

     var dsgnC = lang == "R" ?  get(dsgnCode, [lang, stat, dsgnKey]) : '';
     var codeC = get(statCode, [lang, stat, statKey]);

    var byGrps;
    switch(byVars) {
      case 'row': byGrps = [row]; break;
      case 'col': byGrps = [col]; break;
      default: byGrps = [row, col].filter(unique);
    }

    byGrps = remove(byGrps, ['event', 'sop']);
    if(byGrps.length === 0){
      byGrps = ['ind'];
    }

    var fmt = byGrps.map(makeFMT).join(" ");
    var gp  = byGrps.join(" ");
    var yearC = isTrend ?  Math.max(year, yearStart)+"" : year;

    var subgrps = grps.concat('ind').filter(unique);
    subgrps = remove(subgrps, ['sop', 'event', 'Condition']);

    var subList = {
      /* R */
        "subgrps": subgrps.join(","),
        "by": byGrps.filter(unique).join(" + "),
        "var": col,
      /* SAS */
        "domain": byGrps.join("*"),
        "fmt": fmt,
        "format": "FORMAT " + fmt,
        "gp": gp,
        // "gp_star": byGrps.join('*')+"*",
        "where": "and " + gp + " ne .",
      "PUFdir": lang == "SAS" ? "C:\\MEPS" : "C:/MEPS",
      "year": yearC,
      "yy": yearC.substr(2,3),
      "ya": (yearC*1 + 1 + "").substr(2,3),
      "yb": (yearC*1 - 1 + "").substr(2,3)
      };


    codeText = $.grep(
      [loadPkgs[lang], loadFYC[lang], grpC, loadC, dsgnC, codeC], Boolean)
      .join("\n");
    //codeText = [grpC, dsgnC, codeC].join("\n");

    codeText = rsub(codeText, subList, lang = lang);
    codeText = rsub(codeText, pufNames[yearC][0], lang = lang);
    codeText = codeText.replace("\n\n\n","\n\n");

    $('#code').html(codeText);
    $('#updating-overlay').hide(); // Remove 'updating' overlay faster for code
  });

  // Export code to text files --------------------
  $('#dl-code').on('click', function() {
    var fName = 'meps-code-' + shortDate() + '.'+lang;
    downloadFile({file: codeText, filename: fName});
  });


// Caption, Citation, Notes ---------------------------------------------------
    var newCaption, plotCaption, newSource, rowName, colName;
    var plotSuppress = false;

    // Footnotes
    $(document).on('updateNotes', function() {

      if(isPivot) {
        var cellData = table.cells('.selected','.showDT.coef').data().toArray();
      } else {
        var cellData = table.cells({search: 'applied'},'.showDT.coef').data().toArray();
      }

      plotSuppress = false; /* Reset to false */
      for(var i = 0; i < cellData.length; i++) {
        var el_i = cellData[i];
        plotSuppress = (el_i===null || el_i=="NA") ? true : plotSuppress;
        if(plotSuppress) {break;}
      }
      plotSuppress ? $('#plot-suppress').show() : $('#plot-suppress').hide();
    });

    $(document).on('updateNotes', function() {
      var statName = $('#stat option:selected').text().replace(/ *\([^)]*\) */g, "") ;
      var seName = showSEs ? " (standard errors)" : "";
      var adjName = adjustStat[stat] === undefined ? "" : adjustStat[stat] ;

      colName = colX == "ind" ? "" :
          $('#colGrp option:selected').text().toLowerCase();

      rowName = rowX == "ind" ? "" :
          $('#rowGrp option:selected').text().toLowerCase();

      var grpNames = $.grep([rowName,colName],Boolean).join(" and ");
      //var byGrps = grpNames == "(none)" ? "" : " by " + grpNames;
      var byGrps = grpNames === "" ? "" : " by " + grpNames;

      var yearName = isTrend ? [year, yearStart].filter(unique).sort().join("-") : year;

      // Caption
      var statExtra = "", statNote = "";
      if(appKey == 'use' && stat == 'totPOP') {
        statExtra =
          [rowX, colX].includes('sop') ?   ' with an expense' :
          [rowX, colX].includes('event') ? ' with an event' : "";
      }

      statNote = mepsNotes[appKey][stat];
      if(appKey == 'care') {
        // Difficulty and reasons for difficulty don't need statement on 'percents may not add to 100'
        if(colX.includes('rsn') || colX == "difficulty") {
          statNote = "";
        }
        var byRow = rowName === "" ? "" : " by " + rowName;
        newCaption = careCaption[colGrp] + ", " + statName.toLowerCase() + " " +
          adjName + seName + byRow + ", United States, " + yearName;
      } else {
        newCaption = statName + " " + adjName + statExtra + seName + byGrps +
          ", United States, " + yearName;
      }

      newCaption = newCaption.replaceAll("  "," ").replaceAll(" ,",",");
      $('#table-caption').text(newCaption);

      plotCaption = newCaption.replace(" (standard errors)"," (95% confidence intervals)");
      $('#plot-caption').text(plotCaption);

      // Citation
      var AHRQ = "Agency for Healthcare Research and Quality";
      var MEPS = "Medical Expenditure Panel Survey";
      var CFACT = "Center for Financing, Access and Cost Trends";
      var today = new Date();
      var newCitation = AHRQ+". "+newCaption+". "+MEPS+
          ". Generated interactively: "+today.toDateString() +".";

      newSource = "<b>Source:</b> "+CFACT+", "+AHRQ+", "+MEPS+", "+yearName;

      var newNotes = $.grep(
        [statNote,
         mepsNotes[appKey][rowX], mepsNotes[rowX],
         mepsNotes[appKey][colX], mepsNotes[colX]], Boolean).join("\n");

      $('#source').html(newSource);
      $('#notes').html(newNotes);
      $('#citation').text(newCitation);
    });


// Trigger --------------------------------------------------------------------
// trigger on load too -- must be at end;
    $('#stat, #code-language, #data-view').trigger('change');
});
