

WebivaStatsChart = function(opts) {
  var $ = jQuery;
  var sources = opts.sources;
  var source_types = opts.source_types;
  var source_colors = opts.source_colors;
  var user_levels = opts.user_levels;
  var user_level_types = opts.user_level_types;
  var user_level_colors =  pv.colors(opts.user_level_colors);
  var fontColor = '#603813';
  var backgroundColor = '#F6F6F6';
  var sources_to_display = new Array();
  for(var i=0; i<source_types.length; i++) {
    sources_to_display.push(true);
  }

  function getTextDims(txt, font) {
    var box = $('#webiva-font-box');
    if(box.length == 0) {
      $('<span id="webiva-font-box" style="display:none;"></span>').appendTo('body');
      box = $('#webiva-font-box');
    }
    box.css('font', font);
    box.text(txt);
    return {width: box.width(), height: box.height()};
  }

  var maxUserLevel = 0;

  var maxVisits = 0;
  var visits = new Array();

  var fonts = {
    legend: {font: '12px sans-serif', color: fontColor, margin: 15},
    check: {font: '18px sans-serif', color: '#000000', size: 16, spacing: 4, text: String.fromCharCode(10003)},
    numbers: {font: 'bold 11px sans-serif', color: '#000000'},
    ticks: {font: '11px sans-serif', color: fontColor}
  };

  var dimensions = {
    bar: {width: 150, height: 400, top: 5, bottom: 5},
    pie: {radius: 0, y: 0, area:0},
    padding: 30
  };

  dimensions.pie.radius = dimensions.bar.width / 2 - 8;
  dimensions.pie.area = dimensions.pie.radius * dimensions.pie.radius * Math.PI;

  function load(data) {
    user_levels = data.user_levels;
    sources = data.sources;
    setup();
  }

  function setup() {
    maxUserLevel = 0;
    maxVisits = 0;
    visits = new Array();

    for(var i=0; i<user_levels.length; i++) {
      var sum = 0;
      for(var j=0; j<user_levels[i].length; j++) { sum += user_levels[i][j]; }
      if(maxUserLevel < sum) {
        maxUserLevel = sum;
      }
    }

    for(var i=0; i<sources.length; i++) {
      var sum = 0;
      for(var j=0; j<sources[i].length; j++) { sum += sources[i][j]; }
      if(maxVisits < sum) { maxVisits = sum; }
      visits.push(sum);
    }
  }

  setup();

  function legend(vis, x, y, colors, labels, callback) {
    vis.add(pv.Bar)
      .data(labels)
      .top(function() (labels.length - 1 - this.index) * (fonts.check.size + fonts.check.spacing) + y)
      .width(fonts.check.size)
      .height(fonts.check.size)
      .left(x)
      .fillStyle(colors.by(pv.index))
      .event("click", function() { if(callback) { callback(this.index);} })
      .anchor("center").add(pv.Label)
      .font(fonts.check.font)
      .textStyle(fonts.check.color)
      .text(function() {return callback && sources_to_display[this.index] ? fonts.check.text : ''})
      .anchor("right").add(pv.Label)
      .textMargin(fonts.legend.margin)
      .textAlign("left")
      .font(fonts.legend.font)
      .textStyle(fonts.legend.color)
      .text(function() labels[this.index])
      .events("all")
      .event("click", function() { if(callback) { callback(this.index, true);} });
  }

  function userLevelChart(vis, x, y, colors, data) {
    var total = 0;
    for(var i=0; i<data.length; i++) { total += data[i]; }

    var area = dimensions.pie.area * (total / maxUserLevel);

    var a = pv.Scale.linear(0, pv.sum(data)).range(0, 2 * Math.PI),
        r = Math.sqrt(area / Math.PI);

    vis.add(pv.Bar)
    .top(0)
    .left(0)
    .width(dimensions.bar.width-1)
    .height(dimensions.bar.width-1)
    .fillStyle(backgroundColor)
    .strokeStyle('#666666')
    .lineWidth(1)
    .antialias(false);

    vis.add(pv.Wedge)
    .data(data)
    .top(y + dimensions.bar.width / 2)
    .left(x + dimensions.bar.width / 2)
    .outerRadius(r)
    .angle(a)
    .title(function(d) d)
    .fillStyle(colors.by(pv.index))
    .add(pv.Wedge) // invisible wedge to offset label
    .outerRadius(r)
    .fillStyle(null)
    .anchor("center").add(pv.Label)
    .textAngle(0)
    .font(fonts.numbers.font)
    .textStyle(fonts.numbers.color)
    .text(function(d) d > 0 ? d : '');
  }

  function drawSources(index, canvas) {
    /* Sizing and scales. */
    var x = 0,
        colors = new Array(),
        data = new Array(),
        y = pv.Scale.linear(0, maxVisits).range(0, dimensions.bar.height);

    for(var i=0; i<sources[index].length; i++) {
      if(sources_to_display[i]) {
        data.push([sources[index][i]]);
        colors.push(source_colors[i]);
      }
    }

    colors.push('#EEEEEE');
    var sum = 0;
    for(var i=0; i<sources[index].length; i++) {
      if(! sources_to_display[i]) {
        sum += sources[index][i];
      }
    }

    data.push([sum]);
    colors = pv.colors(colors);

    /* The root panel. */
    var vis = new pv.Panel()
    .width(dimensions.bar.width)
    .height(dimensions.bar.height)
    .top(dimensions.bar.top)
    .bottom(dimensions.bar.bottom)
    .left(0)
    .fillStyle(backgroundColor)
    .canvas(canvas);

    vis.add(pv.Layout.Stack)
    .layers(data)
    .x(x)
    .y(y)
    .layer.add(pv.Bar)
    .width(dimensions.bar.width)
    .fillStyle(colors.by(pv.parent))
    .title(function(d) d)
    .anchor("center").add(pv.Label)
    .font(fonts.numbers.font)
    .textStyle(fonts.numbers.color)
    .text(function(d) d > 0 ? d : '');

    var numTicks = 5;
    if(numTicks > maxVisits) {
      numTicks = maxVisits;
    }

    /* Y-axis ticks. */
    vis.add(pv.Rule)
    .data(y.ticks(numTicks))
    .bottom(y)
    .strokeStyle(function(d) d ? "rgba(255,255,255,.18)" : null);

    vis.render();
  }

  function drawUserLevels(index, canvas) {
    /* The root panel. */
    var vis = new pv.Panel()
    .width(dimensions.bar.width)
    .height(dimensions.bar.width)
    .bottom(0)
    .left(0)
    .fillStyle(backgroundColor)
    .canvas(canvas);

    userLevelChart(vis, 0, 0, user_level_colors, user_levels[index]);

    vis.render();
  }

  function drawRuler(canvas) {
    var y = pv.Scale.linear(0, maxVisits).range(0, dimensions.bar.height);

    var dim = getTextDims('0', fonts.ticks.font);
    var width = maxVisits.toString().length * dim.width + 10;
    var numTicks = 5;
    if(numTicks > maxVisits) {
      numTicks = maxVisits;
    }


    /* The root panel. */
    var vis = new pv.Panel()
    .width(5)
    .height(dimensions.bar.height)
    .top(dimensions.bar.top)
    .bottom(dimensions.bar.bottom)
    .left(width)
    .canvas(canvas);

    /* Y-axis ticks. */
    vis.add(pv.Rule)
        .data(y.ticks(numTicks))
        .bottom(y)
        .add(pv.Rule)
        .left(0)
        .width(5)
        .strokeStyle(fonts.ticks.color)
        .anchor("left").add(pv.Label)
        .textStyle(fonts.ticks.color)
        .font(fonts.ticks.font)
        .text(y.tickFormat);

    vis.render();
  }

  function drawSourcesLegend(canvas) {
    /* The root panel. */
    var vis = new pv.Panel()
    .width(200)
    .height(dimensions.bar.height)
    .top(dimensions.bar.top)
    .bottom(dimensions.bar.bottom)
    .left(0)
    .canvas(canvas);

    legend(vis, 0, 20, pv.colors(source_colors), source_types, function(index, single) {
             if(single) {
               for(var i=0; i<sources_to_display.length; i++) {
                 sources_to_display[i] = false;
               }
               sources_to_display[index] = true;
             } else {
               sources_to_display[index] = ! sources_to_display[index];
             }

             for(var i=0; i<visits.length; i++) {
               drawSources(i, 'chart_bar' + (i+1));
             }

             drawSourcesLegend('chart_bar_legend');
           });

    vis.render();
  }

  function drawUserLevelsLegend(canvas) {
    var vis = new pv.Panel()
    .width(dimensions.bar.width)
    .height(dimensions.bar.width)
    .bottom(0)
    .left(0)
    .canvas(canvas);

    legend(vis, 0, 20, user_level_colors, user_level_types);

    vis.render();
  }

  function draw() {
    drawRuler('chart_bar_ruler');

    for(var i=0; i<visits.length; i++) {
      drawUserLevels(i, 'chart_pie' + (i+1));
      drawSources(i, 'chart_bar' + (i+1));
    }

    drawSourcesLegend('chart_bar_legend');
    drawUserLevelsLegend('chart_pie_legend');
  }

  return {draw: draw, load: load};
};
