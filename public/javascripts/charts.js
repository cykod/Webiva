

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
  var currentWidth = 0;
  var chartWidthMinimum = opts.min_size ? opts.min_size : 600;

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
    var width = chartWidthMinimum;
    if(container) {
      width = $('#' + container).width();
    } else {
      width = $('#' + canvas).width();
    }
    return width > chartWidthMinimum ? width : chartWidthMinimum;
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

  function draw(force) {
    if(dataTable.length == 0) {
      return;
    }

    /* Sizing and scales. */
    var rows = dataTable.length,
        barsPerRow = dataTable[0].data.length,
        marginTop = 5,
        marginBottom = 20,
        marginLeft = 190,
        marginRight = 100,
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

    /* No need to redraw unless we are changing the size of the graph */
    if(force == undefined && currentWidth == w) {
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
       .top(function() y(this.index))
       .height(y.range().band)
       .add(pv.Bar)
       .data(function(d) d.data)
       .top(function() this.index * y.range().band / barsPerRow)
       .height(y.range().band / barsPerRow)
       .left(0)
       .width(x)
       .fillStyle(colors.by(pv.index))
       .textStyle(fontColor)
       .text(function(d) d + (columns ? ' ' + columns[this.index] : ''))
       .event("mouseover", pv.Behavior.tipsy({gravity: "w", fade: true}));
  
    if(columns) {
      /* The legend. */
      vis.add(pv.Bar)
         .data(columns)
         .top(function() this.index * 14 + marginTop)
         .height(12)
         .left(legendX)
         .width(12)
         .fillStyle(colors.by(pv.index))
         .event("click", function() {sort(this.index); draw(true);})
         .anchor("right").add(pv.Label)
         .textMargin(5)
         .textAlign("left")
         .textStyle(fontColor)
         .text(function() columns[this.index])
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
         .text(function() truncate(dataTable[this.parent.index].label, 40))
         .title(function() dataTable[this.parent.index].label)
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
        .strokeStyle(function(d) d ? "rgba(255,255,255,.3)" : "#000")
        .add(pv.Rule)
        .bottom(0)
        .height(5)
        .strokeStyle(fontColor)
        .anchor("bottom").add(pv.Label)
        .textStyle(fontColor)
        .text(x.tickFormat);
  
    vis.render();

    if(container) {
      $(window).resize(function() {draw();});
    }
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
