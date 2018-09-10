// Table of Contents:
//
// Basic math -----------------------------------------------------------------
// Index selectors ------------------------------------------------------------
// Data manipulation ----------------------------------------------------------
// DOM interaction ------------------------------------------------------------
// Formatting -----------------------------------------------------------------
//   Table formatting
//   Plot formatting
//   Code formatting
// Download files--------------------------------------------------------------
// Plotly ---------------------------------------------------------------------
// Polyfill -------------------------------------------------------------------


// Basic math -----------------------------------------------------------------

function sum(array) {
  var total = 0;
  for (var i=0; i<array.length; i++) {
    total += array[i];
  }
  return total;
}

function mean(array) {
  var arraySum = sum(array);
  return arraySum / array.length;
}


// Index selectors ------------------------------------------------------------

function unique(value, index, self) {
    return self.indexOf(value) === index;
}

function get(Obj, keys) {
  var value = Obj;
  for(var i = 0; i < keys.length; i++) {
    var test = value[keys[[i]]];
    if(test !== undefined){ value = test; }
  }
  var out = typeof value == 'string' ? value : '';
  return out;
}

function getKeys(Obj, keys) {
  if(keys === undefined) {
    keys = [];
  }
  for (var key in Obj){
    keys.push(key);
    var sub = Obj[key];
    if(typeof(sub) == "object") {
      getKeys(sub, keys=keys);
    }
  }
  return(keys);
}

function includesAny(string, array) {
  var sum = 0;
  array.forEach(function(x) {
    sum += (string.match(x) !== null);
  });
  return sum > 0 ? true: false;
}

function grepIndexes(array, args, force) {
  var colIndexes = force || [];
  $.map(array, function(x, indexOf) {
    if(includesAny(x, args)) { colIndexes.push(indexOf); }
  });
  return colIndexes;
}

function selectIndexes(array, indexes) {
  var newArray = [];
  for (var i = 0; i < indexes.length; i++) {
    var index = indexes[i];
    newArray[i] = array[index];
  }
  return newArray;
}

function selectRows(array, indexes) {
  return selectIndexes(array, indexes);
}

function selectCols(array, indexes) {
    var newArrays = [];
    for(var i = 0; i < array.length; i++) {
      var thisItem = array[i];
      newArrays[i] = selectIndexes(thisItem, indexes);
    }
  return newArrays;
}

// Data manipulation ----------------------------------------------------------

function isNull(el) {
  return el === null;
}

function intersectArrays(Arr1, Arr2) {
  var newArr = $.grep(Arr1, function(el) {
    return Arr2.includes(el);
  });
  return newArr;
}

function intersectObjects(Obj1, Obj2) {
  var newObj = {};
  for(var key in Obj1) {
    if(Object.keys(Obj2).includes(key)) {
      newObj[key] = Obj2[key];
    }
  }
  return newObj;
}

function intersection(Item1, Item2) {
  if(Array.isArray(Item1) && Array.isArray(Item2)) {
    return intersectArrays(Item1, Item2);
  } else {
    return(intersectObjects(Item1, Item2));
  }
}


function notIn(array, compare) {
  var hidden = {};
  for(var key in array) {
    if(Object.keys(compare).indexOf(key) < 0) {
      hidden[key] = array[key];
    }
  }
  return hidden;
}

function range(start, end) {
  var Start = Math.min(start, end);
  var End   = Math.max(start, end);
  var numbers = [];
  for (var i = Start; i <= End; i++) {
      numbers.push(i);
  }
  return numbers;
}


function remove(array, element) {
  var filtered = array.filter(function(el) {
    return !element.includes(el);
  });
  return filtered;
}


function transpose(a) {
  return a[0].map(function (_, c) {
    return a.map(function (r) {
      return r[c];
    });
  });
}

function splitArray(array, indexes) {
  var newArray = [];
  var splitAt = [-1].concat(indexes);
  for(var i = 0; i < splitAt.length; i++) {
    var start = splitAt[i]+1;
    var stop  = splitAt[i+1];
    var chunk = array.slice(start, stop);
    if(chunk.length > 0) {
      newArray.push(chunk);
    }
  }
  return newArray;
}

// DOM interaction ------------------------------------------------------------

function createCheckboxGroup(rc, choices, selected) {
    var newHTML = '';
    for (var key in choices) {
      var rowId = key;
      var rowNm = choices[key];

      var check = selected === undefined ? 'checked' :
        Object.keys(selected).includes(rowId) ? 'checked' : '';

      var thisHTML =
      '<li> <input id = _id_ type = "checkbox" name = "rowLevels" value = _id_ _check_>  ' +
        '<label for = _id_ > _name_ </label> </li>';

      newHTML = newHTML + '\n' +
        thisHTML
          .replaceAll("_id_", rowId)
          .replaceAll("_name_", rowNm)
          .replaceAll("_check_", check);
    }

    $('#'+rc+'Levels ul').html(newHTML);
    $('#'+rc+'Levels ul li label').each(function() {
      var thisGrp = $(this).text().trim();
      if(subLevels.includes(thisGrp)) {
        $(this).css('font-style', 'italic');
      }
    });
}

function checkList(id) {
  var sel = {};
  $(id + ' input:checked').each(function() {
   var thisId = $(this).attr('id');
   var thisNm = $(this).next('label').text().trim();
   sel[thisId] = thisNm;
  });
  return sel;
}

function selectRowLevels(table, rowLevels, selectedLevels, rowSelect) {
  var rowRegex;
  var selLev = selectedLevels[rowSelect];
  if(selLev !== undefined) {
    var rowLev = intersection(rowLevels, selLev);
    rowRegex = Object.keys(rowLev).join("|");
  } else {
    rowRegex = "";
  }
  return table.columns(3).search(rowRegex, true, false);
}

function selectColLevels(table, colLevels, selectedLevels, colSelect, colNames) {
  var selLev = selectedLevels[colSelect];
  if(selLev !== undefined) {
    var colLev = intersection(colLevels, selLev);
    var colArray = getValues(colLev);

    var cc = table.columns().header().toJQuery();
    cc.each( function(index) {
      if(colNames[index] == null) { // Hide extra cols
         $(this).removeClass("showDT");
      } else {
        var colNm = $(this).text();
        if(colArray.includes(colNm)) {
          $(this).addClass('showDT ') ;
        } else {
          $(this).removeClass('showDT');
        }
      }
    });
  }
}

// Formatting -----------------------------------------------------------------

// Camelcase
function camelCase(txt) {
  return txt.charAt(0).toUpperCase() + txt.slice(1).toLowerCase();
}

// Extend array to specified length
function fill(array, length) {
  for(var i = array.length; i < length; i++) { array.push(null); }
  return(array);
}

// Today's date
function shortDate() {
  var today = new Date();
  var dd = today.getDate();
  var mm = today.getMonth() + 1;
  var yy = today.getFullYear();
  return [yy,mm,dd].join("-");
}

// Table formatting ------------------------------------

  // Number format
  function formatNum(num) {
    if(num === null) return "--";
    return num;
  }

  function toNumber(str) {
    if(str === null) return str;
    if(!isNaN(str)) return str*1;
    var newstr = str.replaceAll(",","").replace("*","");
    return newstr*1;
  }

  // Format for coef display
  function coefDisplay(data, type, row, meta) {
    if(type == "display") {
        return formatNum(data);
      } else {
        return toNumber(data);
      }
    }

  // Format for se display
  function seDisplay(data, type, row, meta) {
    if(type === "display") {
      return formatNum(row[meta.col-1]) + " (" + formatNum(data) +")";
    } else {
      return toNumber(row[meta.col-1]);
    }
  }

// Plot formatting -------------------------------------

  // Line break in 'Inapplicable' level
  function editLabel(label) {
    if(!isNaN(label)) {
      return label;
    } else {
      var newlabel = label
        .replaceAll("Inapplicable \\(", "Inapplicable<br>(")
        .replaceAll("hysician", "hys.")
        .replaceAll("Emergency room", "ER");
      return newlabel;
    }
  }

  function wrap(str, width) {
    if(!isNaN(str)) {
      return str + "";
    } else {
      var spaceReplacer = '<br>';
      var brkpoints = ["/"," ","-"];
      if (str.indexOf(spaceReplacer) > 0) { return str; }
      if (str.length > width) {
          var p = width;
          for (; p>0 && (brkpoints.indexOf(str[p]) < 0); p--) {
            // count backwards from desired width to find breakpoint
          }
          if (p > 0) {
              var left = str.substring(0, p+1);
              var right = str.substring(p+1);
              return left + spaceReplacer + wrap(right, width);
          }
      }
      return str;
    }
  }

  function wrap15(str) {
    return wrap(str, width = 20);
  }

  function wrap70(str) {
    return wrap(str, width = 70);
  }

  function countBreaks(arr) {
    var n_rows = 0;
    for(var i = 0; i < arr.length; i++) {
      var wrapped = wrap15(arr[i]);
      var n_breaks = (wrapped.match(/<br>/g) || []).length;
      n_rows = n_rows + n_breaks + 1;
    }
    return n_rows;
  }

// Code formatting ----------------------------------------

  // Rsub
  function rsub(string, dict, lang) {
    var beg = lang == "R" ? "\\." : "\\&";
    for(var key in dict) {
      string = string.replaceAll(beg + key + "\\.", dict[key]);
    }
    return string;
  }

  // FORMAT string for SAS code
  function makeFMT(name) {
    return name + " " + name + ".";
  }


// Download files--------------------------------------------------------------
function convertArrayOfObjectsToCSV(args) {
  var result, ctr, keys, cnames, columnDelimiter, lineDelimiter, data;

  data = args.data || null;
  if (data === null || !data.length) { return null;}

  columnDelimiter = ',';
  lineDelimiter = '\n';

  cnames = args.colnames;
  keys = Object.keys(data[0]);

  result = '';
  result += '"'+cnames.join('"'+columnDelimiter+'"')+'"';
  result += lineDelimiter;

  data.forEach(function(item) {
    ctr = 0;
    keys.forEach(function(key) {
      if (ctr > 0) result += columnDelimiter;
      //result += item[key];
      result += "\" " + item[key] + "\"";
      ctr++;
    });
    result += lineDelimiter;
  });
  return result;
}

function downloadFile(args) {
  var link;
  var file = args.file;
  var filename = args.filename;
  if (file === null) return;

  var blob = new Blob([file], {type: "text/csv;charset=utf-8;"});
  if(navigator.msSaveBlob) {
    navigator.msSaveOrOpenBlob(blob,filename);
  } else {
    link = document.createElement("a");
    if(link.download !== undefined) {
      var url = URL.createObjectURL(blob);
      link.setAttribute("href",url);
      link.setAttribute("download",filename);
      link.style = "visibility:hidden";
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    }
  }
}


function downloadPlot(args) {
  var filename = args.filename;
  var footnotes = args.footnotes;
  var height = args.height;

  var dlPlot = document.getElementById('meps-plot');

  // Use canvg if IE11
  if(navigator.msSaveBlob) {
    // Get svg elements from plotly
    var svg0 = dlPlot.getElementsByClassName('main-svg')[0]; // graph
    var svg1 = dlPlot.getElementsByClassName('main-svg')[1]; // legend and title
    var data0 = svg0.outerHTML;
    var data1 = svg1.outerHTML;

    var canvas = document.createElement('canvas'); // Create a Canvas element.
    canvas.setAttribute('width', '700px');
    canvas.setAttribute('height', height+'px');

    var ctx = canvas.getContext('2d'); // For Canvas returns 2D graphic.

    // Set background rectangle
    canvg(canvas, '<svg> <rect width = "100%" height = "100%" style="fill: rgb(255,255,255)"/> </svg>');

    // Add svg layers
    ctx.drawSvg(data1);
    ctx.drawSvg(data0);

    ctx.font = '14px sans-serif';
    var multi_foots = footnotes.split("<br>");
    var line = height-50;
    for (var i = 0; i < multi_foots.length; i++) {
      ctx.fillText(multi_foots[i], 20, line);
      line = line + 20;
    }

    var blob = canvas.msToBlob();
    window.navigator.msSaveOrOpenBlob(blob, filename + '.png');

  } else {

    Plotly.downloadImage(dlPlot, {
      format: 'png',
      width: 700,
      height: height,
      filename: filename
    });
  }
}


// Plotly ---------------------------------------------------------------------

// Initialize colors
var all_colors = [
   '31,120,180',  '51,160,44',   '227,26,28',  '255,127,0',
   '106,61,154',  '177,89,40', '166,206,227','178,223,138',
  '251,154,153','253,191,111', '202,178,214','255,255,153'];

var acolors = [], colors = [];
for(var k = 0; k < all_colors.length; k++) {
 colors[k]  = "rgb("   + all_colors[k],")";
 acolors[k] = "rgba(" + all_colors[k] + ", 0.4)";
}

function nullIndexes(array) {
  var nulls = [];
  for(var i = 0; i < array.length; i++) {
    if(array[i] === null) {nulls.push(i);}
  }
  return nulls;
}

function nonEmptyRowIndexes(rows) {
  var indexes = [];
  for(var i = 0; i < rows.length; i++) {
    if(!rows[i].every(isNull)) { indexes.push(i); }
  }
  return indexes;
}

function barPlotData(x_values, y_values, y_ses, y_labels, showSEs, hideYaxis) {
    var plotdata = [];

    // Remove empty rows
    var keep_i = nonEmptyRowIndexes(y_values);
    var y_i   = selectIndexes(y_values, keep_i);
    var ses_i = selectIndexes(y_ses, keep_i);
    var y_lab = selectIndexes(y_labels, keep_i);
    if(y_i.length == 0) { return null; }

    // Remove empty cols
    var keep_j = nonEmptyRowIndexes(transpose(y_i));
    var y_j   = selectIndexes(transpose(y_i), keep_j);
    var ses_j = selectIndexes(transpose(ses_i), keep_j);
    var x_lab = selectIndexes(x_values, keep_j).map(wrap15);

    // Transpose back to original orientation
    var y  = transpose(y_j);
    var ses = transpose(ses_j);
    if(y.length == 0) {return null; }

    for(var j = 0; j < y.length; j++) {
      var newtrace = {
        x: y[j].map(toNumber),
        y: x_lab,
        name: wrap15(y_lab[j]),
        legendgroup: wrap15(y_lab[j]),
        orientation: 'h',
        type: 'bar',
        marker: {
          color: colors[j], width: 1,
          line: {color: 'white', width: 2},
        },
        error_x: {
          type: 'data', visible: showSEs,
          array: ses[j].map(toNumber).map(function(x) {return x*1.96;})
        },
        hoverinfo: "x"
      };
      plotdata[j] = newtrace;
    }

    // Set y-labels as annotations for correct vertical alignment
    var annotations = [];
    for(var k = 0; k < x_lab.length; k++) {
      var new_ylabel = {
        xref: 'paper', yref: 'y',
        x : 0,
        y: x_lab[k],
        text: x_lab[k],
        showarrow: false,
        xanchor: 'right',
        align: 'right'
      };
      annotations.push(new_ylabel);
    }

    return {data: plotdata, ylabels: annotations};
}


function linePlotData(x_values, y_values, y_ses, y_labels, showSEs) {
  var newdata = [], newSE = [];
  var x = x_values.map(toNumber);

  // Remove empty rows
  var keep_i = nonEmptyRowIndexes(y_values);
  var y_i   = selectIndexes(y_values, keep_i);
  var ses_i = selectIndexes(y_ses, keep_i);
  var y_lab = selectIndexes(y_labels, keep_i);

  for(var j = 0; j < y_i.length; j++) {

    var y  = y_i[j].map(toNumber);
    var se = ses_i[j].map(toNumber);

    // SE ribbon: split into non-null pieces
    var null_i  = nullIndexes(y);
    var y_split = splitArray(y, null_i);
    var x_split = splitArray(x, null_i);
    var se_split = splitArray(se, null_i);

    for (var k = 0; k < y_split.length; k++) {
      var y_segment = y_split[k];
      var x_segment = x_split[k];
      var se_segment = se_split[k];

      var LCL = y_segment.map(function(num, idx) {return num - 1.96*se_segment[idx];});
      var UCL = y_segment.map(function(num, idx) {return num + 1.96*se_segment[idx];});

      var x_se = x_segment.concat(x_segment.slice().reverse());
      var y_se = LCL.concat(UCL.reverse());

      var CI_color = y_segment.length > 1 ? "transparent" : colors[j];

      var newtrace = {
        x: x_segment, y: y_segment,
        type: 'scatter',
        name: wrap15(y_lab[j]),
        legendgroup: wrap15(y_lab[j]),
        showlegend: (k == 0), // prevent duplicate legend entries
        line: {width: 4, color: colors[j]},
        mode: 'lines+markers',
        marker: {size: 10, symbol: j},
        color: colors[j],
        error_y: {type: 'data', visible: showSEs, color: CI_color,
          array: se_segment.map(function(x) {return x*1.96;})
        },
        hoverinfo: "y"
      };
      newdata.push(newtrace);

      var seRibbon = {
        x: x_se, y: y_se,
        fill: "toself",
        fillcolor: acolors[j],
        line: {color: "transparent"},
        name: wrap15(y_lab[j]),
        legendgroup: wrap15(y_lab[j]),
        showlegend: false,
        type: "scatter",
        hoverinfo: "none"
      };
      newSE.push(seRibbon);
    }
  }

  if(newdata.length == 0) {
    return null;
  }

  // Hidden point to force ylab to zero (default plotly options not so good)
  var hiddenX = x_values.length > 1 ? mean(x) : x[0];
  var hiddenTrace = { x: [hiddenX], y: [0],
    showlegend: false, marker: {color: "transparent"}, hoverinfo: 'none'
  };

  newdata = newdata.concat(hiddenTrace);
  var plotdata = showSEs ? $.merge(newSE,newdata) : newdata;

  return {data: plotdata, ylabels: null};
}




// Polyfill -------------------------------------------------------------------

function getValues(obj) {
  var values = Object.keys(obj).map(function(e) {
    return obj[e];
  });
  return(values);
}

String.prototype.replaceAll = function(search, replacement) {
    var target = this;
    return target.replace(new RegExp(search, 'g'), replacement);
};

Object.defineProperty(SVGElement.prototype, 'outerHTML', {
    get: function () {
        var $node, $temp;
        $temp = document.createElement('div');
        $node = this.cloneNode(true);
        $temp.appendChild($node);
        return $temp.innerHTML;
    },
    enumerable: false,
    configurable: true
});

if (!Object.keys) {
  Object.keys = (function() {
    'use strict';
    var hasOwnProperty = Object.prototype.hasOwnProperty,
        hasDontEnumBug = !({ toString: null }).propertyIsEnumerable('toString'),
        dontEnums = [
          'toString',
          'toLocaleString',
          'valueOf',
          'hasOwnProperty',
          'isPrototypeOf',
          'propertyIsEnumerable',
          'constructor'
        ],
        dontEnumsLength = dontEnums.length;

    return function(obj) {
      if (typeof obj !== 'function' && (typeof obj !== 'object' || obj === null)) {
        throw new TypeError('Object.keys called on non-object');
      }

      var result = [], prop, i;

      for (prop in obj) {
        if (hasOwnProperty.call(obj, prop)) {
          result.push(prop);
        }
      }

      if (hasDontEnumBug) {
        for (var i = 0; i < dontEnumsLength; i++) {
          if (hasOwnProperty.call(obj, dontEnums[i])) {
            result.push(dontEnums[i]);
          }
        }
      }
      return result;
    };
  }());
}

if (typeof Object.assign != 'function') {
  Object.assign = function(target) {
    'use strict';
    if (target == null) {
      throw new TypeError('Cannot convert undefined or null to object');
    }

    target = Object(target);
    for (var index = 1; index < arguments.length; index++) {
      var source = arguments[index];
      if (source != null) {
        for (var key in source) {
          if (Object.prototype.hasOwnProperty.call(source, key)) {
            target[key] = source[key];
          }
        }
      }
    }
    return target;
  };
}


if (!String.prototype.includes) {
  String.prototype.includes = function(search, start) {
    'use strict';
    if (typeof start !== 'number') {
      start = 0;
    }

    if (start + search.length > this.length) {
      return false;
    } else {
      return this.indexOf(search, start) !== -1;
    }
  };
}


if (!Array.prototype.includes) {
  Object.defineProperty(Array.prototype, 'includes', {
    value: function(searchElement, fromIndex) {

      if (this == null) {
        throw new TypeError('"this" is null or not defined');
      }

      // 1. Let O be ? ToObject(this value).
      var o = Object(this);

      // 2. Let len be ? ToLength(? Get(O, "length")).
      var len = o.length >>> 0;

      // 3. If len is 0, return false.
      if (len === 0) {
        return false;
      }

      // 4. Let n be ? ToInteger(fromIndex).
      //    (If fromIndex is undefined, this step produces the value 0.)
      var n = fromIndex | 0;

      // 5. If n ??? 0, then
      //  a. Let k be n.
      // 6. Else n < 0,
      //  a. Let k be len + n.
      //  b. If k < 0, let k be 0.
      var k = Math.max(n >= 0 ? n : len - Math.abs(n), 0);

      function sameValueZero(x, y) {
        return x === y || (typeof x === 'number' && typeof y === 'number' && isNaN(x) && isNaN(y));
      }

      // 7. Repeat, while k < len
      while (k < len) {
        // a. Let elementK be the result of ? Get(O, ! ToString(k)).
        // b. If SameValueZero(searchElement, elementK) is true, return true.
        if (sameValueZero(o[k], searchElement)) {
          return true;
        }
        // c. Increase k by 1.
        k++;
      }

      // 8. Return false
      return false;
    }
  });
}
