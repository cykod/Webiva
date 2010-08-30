/* 

A column chart made out of money, using the Google Visalization API.

Data Format
  First column string (label)
  Second column number (value)
  or
  Onw row of numbers

Configuration options:
  min: The minimal value (default=0)
  max: The maximal value (default=actual maximal value)
  title: Text for a title above the chart (default=none)
  canSelect: Boolean, if true (default), users can click on bars
  currency: USD or EUR

Methods
  setSelection
  getSelection

Events
  select

*/

PilesOfMoney = function(container) {
  this.container = container;
  
  this.bars = [];
  this.uid = PilesOfMoney.nextId++;
  this.selection = [];
};

// Global constant to prevent namespace collision between 2 chart
PilesOfMoney.nextId = 0;

PilesOfMoney.prototype.draw = function(data, options) {
  var options = options || {};
  var container = this.container;

  var rows = data.getNumberOfRows();
  if (rows < 1) {
    container.innerHTML = '<span class="pilesofmoney-error">Piles-of-Money Error: No data (no rows)</span>';
    return; 
  }

  var bars = [];
  this.bars = bars;        
  var cols = data.getNumberOfColumns();
  if (cols >= 2 && data.getColumnType(0) == 'string' && data.getColumnType(1) == 'number') {
    // Labels column and values column
    for (var rowInd = 0; rowInd < rows; rowInd++) {
      var v = data.getValue(rowInd, 1);
      if (v >= 0) {
        bars.push({value: v, formatted: data.getFormattedValue(rowInd, 1), 
            label: data.getValue(rowInd, 0), dataRow: rowInd});
      }
    }
  } else {
    // Column labels and a single values row
    for (var colInd = 0; colInd < cols; colInd++) {
      if (data.getColumnType(colInd) == 'number') {
        var v = data.getValue(0, colInd);
        if (v >= 0) {
          bars.push({value: v, formatted: data.getFormattedValue(0, colInd),
             label: data.getColumnLabel(colInd), dataCol: colInd});
        }
      }
    }
  }
        
  if (bars.length < 1) {
    container.innerHTML = '<span class="pilesofmoney-error">Piles-of-Money Error: Expecting some numeric values</span>';
    return;
  }
        
  var minValue = 0;
  var maxValue = bars[0].value;
  for (var i = 1; i < bars.length; i++) {
    maxValue = Math.max(maxValue, bars[i].value);
  }

  var prefMinValue = options['min'];
  var prefMaxValue = options['max'];
  if (prefMinValue != null || prefMaxValue != null) {
    var min = prefMinValue || 0;
    var max = prefMaxValue || maxValue;
    if (min >= 0 && max > 0 && min < max) {
      minValue = min;
      maxValue = max;
    }
  }

  var range = maxValue - minValue;
        
  var IMG_FULL_HEIGHT = 134;
  var IMG_MIN_HEIGHT = 25;
  var IMG_DIFF_HEIGHT = IMG_FULL_HEIGHT - IMG_MIN_HEIGHT;

  var html = [];
        
  var header = options['title'];

  html.push('<table>');
  if (header) {
    html.push('<tr><td colspan="', bars.length, '" class="pilesofmoney-title">', 
        this.escapeHtml(header), '</td></tr>');
  }
  html.push('<tr valign="bottom" align="center">');

  var imgPref = 'dollar_';
  if (options['currency'] == 'EUR') {
    imgPref = 'euro_';
  }
  for (var i = 0; i < bars.length; i++) {
    var bar = bars[i];
    var v = Math.max(0, bar.value);
    var pct = range == 0 ? 0 : Math.min(1, (v - minValue) / range);
    var h = Math.round(pct * IMG_DIFF_HEIGHT + IMG_MIN_HEIGHT);
    var w = 120;
    var img = '1';
    if (h <= 114) { img = '2'; w = 121; }
    if (h <= 93)  { img = '3'; w = 86; }
    if (h <= 73)  { img = '4'; w = 72; }
    if (h <= 56)  { img = '5'; w = 61; }
    if (h <= 44)  { img = '6'; w = 50; }
    if (h <= 35)  { img = '7'; w = 44; }
    if (h <= 29)  { img = '8'; w = 39; }

    var barDomId = 'pilesofmoney-b-' + this.uid + '-' + i; 
    bars[i].domId = barDomId;
    html.push('<td class="pilesofmoney-bar" id="', barDomId, '">');
    html.push('<b>', this.escapeHtml(bar.label), '</b><br />'); 
    html.push(this.escapeHtml(bar.formatted)); 
    html.push('<br />');
    html.push('<img src="http://visapi-gadgets.googlecode.com/svn/trunk/image/', imgPref, img, '.png" width="', w, '" height="', h, '" />');
    html.push('</td>');
  }

  html.push('</tr>')
  html.push('</table>')

  container.innerHTML = html.join('');
  
  // Attach event handlers if clickable
  if (options.canSelect !== false) {
    for (var i = 0; i < bars.length; i++) {
      var bar = bars[i];
      var td = document.getElementById(bar.domId);
      td.style.cursor = 'pointer';
      td.onclick = this.createListener(td, bar.dataRow, bar.dataCol);
    }  
  }
};

PilesOfMoney.prototype.createListener = function(td, row, col) {
  var self = this;
  return function() { self.handleClick(row, col); }
};

PilesOfMoney.prototype.handleClick = function(row, col) {
  this.setSelection([{row:row, col:col}]);
  google.visualization.events.trigger(this, 'select', {});
};

PilesOfMoney.prototype.getSelection = function() {
  return this.selection;
};

PilesOfMoney.prototype.setSelection = function(coords) {
  if (!coords) {
    coords = [];
  }
  this.selection = coords;
  var bars = this.bars;
  for (var i = 0; i < bars.length; i++) {
    var bar = bars[i];
    var className = 'pilesofmoney-bar';
    for (var c = 0; c < coords.length; c++) {
      var rowInd = coords[c].row;
      var colInd = coords[c].col;
    if ((rowInd != null && bar.dataRow == rowInd) || 
        (colInd != null && bar.dataCol == colInd)) {
      className += 'hi';
      break;
    }  
    }
    var td = document.getElementById(bar.domId);
    if (td.className != className) {
      td.className = className;
    }
  }
}

PilesOfMoney.prototype.escapeHtml = function(text) {
  if (text == null) {
    return '';
  }
  return text.replace(/&/g, '&amp;').
      replace(/</g, '&lt;').
      replace(/>/g, '&gt;').
      replace(/"/g, '&quot;');
};
