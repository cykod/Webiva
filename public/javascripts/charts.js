

WebivaBarChart = function(opts) {
  var $ = jQuery;
  var data = opts.data;
  var labels = opts.labels ? opts.labels : null;
  var columns = opts.columns ? opts.columns : null;
  var urls = opts.urls ? opts.urls : null;
  var sortCol = opts.sortCol ? opts.sortCol : 0;
  var sortDesc = opts.sortDesc ? opts.sortDesc : true;
  var canvas = opts.canvas ? opts.canvas : 'chart_canvas';
  var container = opts.container ? opts.container : null;
  var maxValue = 0;
  var dataTable = new Array();
  var chartWidth = opts.width ? opts.width : 600;
  var chartHeight = opts.height ? opts.height : 600;
  var fontSize = opts.fontSize ? opts.fontSize : 10.5;
  var fontFamily = opts.fontFamily ? opts.fontFamily : 'san-serif';
  var font = fontSize + 'px ' + fontFamily;
  var chartType = opts.type ? opts.type : 'column';
  var currentWidth = 0;

  for(var i=0; i<data.length; i++) {
    maxValue = Math.max(maxValue, data[i].max());
    dataTable.push({data: data[i], url: urls ? urls[i] : null, label: labels ? labels[i] : null});
  }


  function sort(col) {
    if(col != undefined) {
      if(sortCol == col) {
        sortDesc = ! sortDesc;
      } else {
        sortDesc = true;
      }
      sortCol = col;
    }

    dataTable.sort(function(a, b) {
                     if(sortDesc) {
                       return b.data[sortCol] - a.data[sortCol];
                     }
                     return a.data[sortCol] - b.data[sortCol];
                   });
  }

  function canvasWidth() {
    var width = chartWidth;
    if(container) {
      width = $('#' + container).width();
    } else {
      width = $('#' + canvas).width();
    }
    return width > chartWidth ? width : chartWidth;
  }

  function canvasHeight() {
    var height = chartHeight;
    if(container) {
      height = $('#' + container).height();
    } else {
      height = $('#' + canvas).height();
    }
    return height > chartHeight ? height : chartHeight;
  }

  function truncate(str, length) {
    length = length ? length : 25;

    if(str.length > length) {
      return str.substring(0, length-3) + '...';
    }

    return str;
  }

  function gotoUrl(url) {
    if(url) {
      document.location = url;
    }
  }

  function getTextDims(txt) {
    var box = $('#webiva-font-box');
    if(box.length == 0) {
      $('<span id="webiva-font-box" style="display:none; font-size:' + fontSize + 'px; font-family:' + fontFamily + ';"></span>').appendTo('body');
      box = $('#webiva-font-box');
    }
    box.text(txt);
    return {width: box.width(), height: box.height()};
  }

  function draw(force) {
    if(dataTable.length == 0) {
      return;
    }

    var chart = chartType == 'bar' ? drawBarChart(force) : drawColumnChart(force);

    if(container) {
      $(window).resize(function() {draw();});
    }

    return chart;
  }

  function drawBarChart(force) {
    var textDim = getTextDims(new Array((maxValue+'').length+1).join('0'));
    textDim.width += 10;

    var legendDim = {width:5, height:5};
    if(columns) {
      for(var i=0; i<columns.length; i++) {
        dim = getTextDims(columns[i]);
        if(legendDim == null || dim.width > legendDim.width) {
          legendDim = dim;
        }
      }
      legendDim.width += 30;
    }

    var labelDim = getTextDims('X');
    if(labels) {
      for(var i=0; i<labels.length; i++) {
        dim = getTextDims(labels[i]);
        if(labelDim == null || dim.width > labelDim.width) {
          labelDim = dim;
        }
      }
      labelDim.height += 5;
    }

    /* Sizing and scales. */
    var rows = dataTable.length,
        barsPerRow = dataTable[0].data.length,
        marginTop = 5,
        marginBottom = labelDim.height,
        marginLeft = textDim.width,
        marginRight = legendDim.width,
        w = canvasWidth() - (marginLeft + marginRight),
        h = canvasHeight() - (marginTop + marginBottom),
        x = pv.Scale.ordinal(pv.range(rows)).splitBanded(0, w, 4/5),
        y = pv.Scale.linear(0, maxValue).range(0, h)
        legendWidth = marginRight - 5,
        legendX = (w + 5),
        legendSize = 5,
        legendY = 0,
        fontColor = '#603813',
        colors = pv.colors('#C7CB2D', '#754C28');

    if(currentWidth == w) {
      return;
    }
    currentWidth = w;

    /* The root panel. */
    var vis = new pv.Panel()
       .width(w)
       .height(h)
       .bottom(marginBottom)
       .left(marginLeft)
       .right(marginRight)
       .top(marginTop)
       .canvas(canvas);
  
    /* The bars. */
    var bar = vis.add(pv.Panel)
       .data(dataTable)
       .left(function() {return x(this.index);})
       .width(x.range().band)
       .add(pv.Bar)
       .data(function(d) {return d.data;})
       .bottom(0)
       .height(y)
       .left(function() {return this.index * x.range().band / barsPerRow;})
       .width(x.range().band / barsPerRow)
       .fillStyle(colors.by(pv.index))
       .textStyle(fontColor)
       .font(font)
       .text(function(d) {return d + (columns ? ' ' + columns[this.index] : '');})
       .event("mouseover", pv.Behavior.tipsy({gravity: "s", fade: true}));
  
    if(columns) {
      /* The legend. */
      vis.add(pv.Bar)
         .data(columns)
         .top(function() {return this.index * 14 + marginTop;})
         .height(12)
         .left(legendX)
         .width(12)
         .fillStyle(colors.by(pv.index))
         .event("click", function() {sort(this.index); draw(true);})
         .anchor("right").add(pv.Label)
         .textMargin(5)
         .textAlign("left")
         .textStyle(fontColor)
         .font(font)
         .text(function() {return columns[this.index];})
         .events("all")
         .event("click", function() {sort(this.index); draw(true);});
     }

    if(labels) {
      /* The variable label. */
      bar.parent.anchor("bottom").add(pv.Label)
         .textBaseline("top")
         .textMargin(6)
         .textAlign("center")
         .textStyle(fontColor)
         .font(font)
         .text(function() {return truncate(dataTable[this.parent.index].label, 25);})
         .title(function() {return dataTable[this.parent.index].label;})
         .events("all")
         .event("click", function() {gotoUrl(dataTable[this.parent.index].url);});
    }

    var numTicks = 5;
    if(maxValue < 5) {
      numTicks = maxValue;
    }

    /* Y-axis ticks. */
    vis.add(pv.Rule)
        .data(y.ticks(numTicks))
        .bottom(y)
        .strokeStyle(function(d) {return d ? "rgba(255,255,255,.3)" : "#000";})
        .add(pv.Rule)
        .left(function(d) {return d ? -2 : 0;})
        .width(5)
        .strokeStyle(fontColor)
        .anchor("left").add(pv.Label)
        .textStyle(fontColor)
        .font(font)
        .text(y.tickFormat);
  
    /* X-axis ticks. */
    vis.add(pv.Rule)
        .bottom(0)
        .left(0)
        .height(h);

    vis.render();
  }

  function drawColumnChart(force) {
    var textDim = getTextDims(new Array((maxValue+'').length+1).join('0'));
    var legendDim = {width:5, height:5};
    if(columns) {
      for(var i=0; i<columns.length; i++) {
        dim = getTextDims(columns[i]);
        if(legendDim == null || dim.width > legendDim.width) {
          legendDim = dim;
        }
      }
      legendDim.width += 30;
    }

    var labelDim = getTextDims('X');
    if(labels) {
      for(var i=0; i<labels.length; i++) {
        dim = getTextDims(labels[i]);
        if(labelDim == null || dim.width > labelDim.width) {
          labelDim = dim;
        }
      }
      labelDim.width += 10;
    }

    /* Sizing and scales. */
    var rows = dataTable.length,
        barsPerRow = dataTable[0].data.length,
        marginTop = 5,
        marginBottom = textDim.height,
        marginLeft = labelDim.width,
        marginRight = legendDim.width,
        w = canvasWidth() - (marginLeft + marginRight),
        h = (rows * (barsPerRow * 12 + 5)),
        x = pv.Scale.linear(0, maxValue).range(0, w),
        y = pv.Scale.ordinal(pv.range(rows)).splitBanded(0, h, 4/5),
        legendWidth = marginRight - 5,
        legendX = (w + 5),
        legendSize = 5,
        legendY = 0,
        fontColor = '#603813',
        colors = pv.colors('#C7CB2D', '#754C28');


    if(currentWidth == w) {
      return;
    }
    currentWidth = w;

    /* The root panel. */
    var vis = new pv.Panel()
        .width(w)
        .height(h)
        .bottom(marginBottom)
        .left(marginLeft)
        .right(marginRight)
        .top(marginTop)
        .canvas(canvas);
  
    /* The bars. */
    var bar = vis.add(pv.Panel)
       .data(dataTable)
       .top(function() {return y(this.index);})
       .height(y.range().band)
       .add(pv.Bar)
       .data(function(d) {return d.data;})
       .top(function() {return this.index * y.range().band / barsPerRow;})
       .height(y.range().band / barsPerRow)
       .left(0)
       .width(x)
       .fillStyle(colors.by(pv.index))
       .textStyle(fontColor)
       .font(font)
       .text(function(d) {return d + (columns ? ' ' + columns[this.index] : '');})
       .event("mouseover", pv.Behavior.tipsy({gravity: "w", fade: true}));
  
    if(columns) {
      /* The legend. */
      vis.add(pv.Bar)
         .data(columns)
         .top(function() {return this.index * 14 + marginTop;})
         .height(12)
         .left(legendX)
         .width(12)
         .fillStyle(colors.by(pv.index))
         .event("click", function() {sort(this.index); draw(true);})
         .anchor("right").add(pv.Label)
         .textMargin(5)
         .textAlign("left")
         .textStyle(fontColor)
         .font(font)
         .text(function() {return columns[this.index];})
         .events("all")
         .event("click", function() {sort(this.index); draw(true);});
     }

    if(urls) {
      /* The label urls. */
      bar.parent.add(pv.Bar)
         .left(-marginLeft)
         .height(y.range().band)
         .width(marginLeft-1)
         .fillStyle('#FFF')
         .event("click", function() {gotoUrl(dataTable[this.parent.index].url);});
    }

    if(labels) {
      /* The variable label. */
      bar.parent.anchor("left").add(pv.Label)
         .textMargin(5)
         .textAlign("right")
         .textStyle(fontColor)
         .font(font)
         .text(function() {return truncate(dataTable[this.parent.index].label, 40);})
         .title(function() {return dataTable[this.parent.index].label;})
         .events("all");
    }

    var numTicks = 5;
    if(maxValue < 5) {
      numTicks = maxValue;
    }

    /* X-axis ticks. */
    vis.add(pv.Rule)
        .data(x.ticks(numTicks))
        .left(x)
        .strokeStyle(function(d) {return d ? "rgba(255,255,255,.3)" : "#000";})
        .add(pv.Rule)
        .bottom(0)
        .height(5)
        .strokeStyle(fontColor)
        .anchor("bottom").add(pv.Label)
        .textStyle(fontColor)
        .font(font)
        .text(x.tickFormat);
  
    vis.render();
  }

  return {draw: draw, sort: sort};
};


WebivaBarChart.fetch = function(url, opts) {
  if(opts == undefined) { opts = {}; }
  $j.getJSON(url, function(res) {
               opts.data = res.data;
               opts.columns = res.columns;
               var chart = WebivaBarChart(opts);
               if(opts.sortCol) { chart.sort(opts.sortCol); }
               chart.draw();
             });
};
