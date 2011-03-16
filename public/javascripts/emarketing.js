RealTimeStatsViewer = {
  from: null,
  stats: new Array(),
  lastStatsIdx: 0,
  current: null,
  playbackTicker: 60,
  statsLayerId: 'real_time_stats',
  maxStats: 1000,
  playbackTickerStart: 60,
  chart: { range: 5, intervals: 10, from: null, to: null, uniques: new Array(), hits: new Array(), labels: new Array() },
  chartTimer: null,

  addStats: function(stats) {
    var twoToneClass = RealTimeStatsViewer.lastStatsIdx % 2 == 0 ? 'even' : 'odd';
    var div = Builder.node('div', {className: 'row ' + twoToneClass},
			   [Builder.node('div', {className: 'stats clearfix'},
			    [Builder.node('div', {className: 'who'},
					  [Builder.node('a', {href: 'javascript:void(0);', onclick:'RealTimeStatsViewer.detail("' + stats.id + '");'},
							stats.user || stats.ip)
					   ]),
			     Builder.node('div', {className: 'when'}, stats.occurred_at),
			     Builder.node('div', {className: 'page'}, [Builder.node('a', {target: '_blank', href: stats.url}, stats.url)])
			     ])
			    ]);
  
    if( stats.action ) {
      div.appendChild(Builder.node('div', {className: 'action'}, '[' + stats.action + ']'));
    }

    var realTimeStatsLayer = $(RealTimeStatsViewer.statsLayerId);
    while( realTimeStatsLayer.children.length >= RealTimeStatsViewer.maxStats ) {
      realTimeStatsLayer.children[0].remove();
    }

    realTimeStatsLayer.insert( div );

    RealTimeStatsViewer.lastStatsIdx++;
  },

  scrollToBottom: function() {
    var realTimeStatsLayer = $(RealTimeStatsViewer.statsLayerId);
    var scrollHeight = realTimeStatsLayer.scrollHeight;
    var height = realTimeStatsLayer.getHeight();
    scrollTop = scrollHeight - height;
    if( scrollTop < 0 ) { return; }
    realTimeStatsLayer.scrollTop = scrollTop;
  },

  playback: function() {
    var realTimeStatsLayer = $(RealTimeStatsViewer.statsLayerId);
    occurred = RealTimeStatsViewer.stats[0].occurred;

    if( occurred == null ) {
      var remainingData = RealTimeStatsViewer.stats.shift();
      if( remainingData.remaining > 0 ) {
        var div = document.createElement( 'div' );
        div.setAttribute( 'class', 'remaining' );
        div.appendChild( document.createTextNode(remainingData.remaining + ' remaining') );
	realTimeStatsLayer.insert( div );
      }
    } else {
      RealTimeStatsViewer.playbackTicker--;

      var scrollTop = realTimeStatsLayer.scrollTop;
      var scrollHeight = realTimeStatsLayer.scrollHeight;
      var height = realTimeStatsLayer.getHeight();
      var scrollToBottom = (scrollTop == 0 && scrollHeight <= height) || (scrollTop+height) == scrollHeight;

      while( occurred != null ) {
	var diff = RealTimeStatsViewer.current - occurred;

        if( diff < RealTimeStatsViewer.playbackTicker ) { break; }

        RealTimeStatsViewer.addStats( RealTimeStatsViewer.stats.shift() );

        if( RealTimeStatsViewer.stats.length == 0 ) {
   	  break;
        }

        occurred = RealTimeStatsViewer.stats[0].occurred;
     }

      if( scrollToBottom ) {
        setTimeout( 'RealTimeStatsViewer.scrollToBottom();', 10 );
      }
    }

    if( RealTimeStatsViewer.stats.length > 0 ) {
      setTimeout( 'RealTimeStatsViewer.playback();', 1000 );
    } 
  },

  realTimeStatsUrl: function() {
    var url = "/website/emarketing/real_time_stats_request";
    if( RealTimeStatsViewer.current != null )
      url += '?from=' + RealTimeStatsViewer.current;
    return url;
  },

  realTimeStatsOnComplete: function(transport) {
    data = transport.responseText.evalJSON();
    RealTimeStatsViewer.playbackTicker = RealTimeStatsViewer.playbackTickerStart;

    var startPlaybackTimer = RealTimeStatsViewer.stats.length == 0;
    RealTimeStatsViewer.current = data[0];

    for( var i=0; i<data[1].length; i++ ) {
      RealTimeStatsViewer.stats.push(data[1][i]);
    }

    if( startPlaybackTimer && RealTimeStatsViewer.stats.length > 0 ) {
      RealTimeStatsViewer.playback();
    }

    setTimeout( 'RealTimeStatsViewer.requestRealTimeStats();', RealTimeStatsViewer.playbackTickerStart*1000 );
  },

  requestRealTimeStats: function() {
    new Ajax.Request(RealTimeStatsViewer.realTimeStatsUrl(),
		     { onComplete: RealTimeStatsViewer.realTimeStatsOnComplete
		     });
  },

  changeChartRange: function(range) {
    if( RealTimeStatsViewer.chart.range == range )
      return;

    if( RealTimeStatsViewer.chartTimer ) {
      clearTimeout( RealTimeStatsViewer.chartTimer );
      RealTimeStatsViewer.chartTimer = null;
    }

    RealTimeStatsViewer.chart.range = range;
    RealTimeStatsViewer.requestRealTimeCharts();
  },

  renderChart: function() {
    $('real_time_charts').update('');

    var width = RealTimeStatsViewer.chart.intervals * 67;
    var height = 320;
    var maxValue = Math.max.apply(Math, RealTimeStatsViewer.chart.hits);
    if(maxValue % 10) {
      maxValue += 10 - (maxValue % 10);
    } else if(maxValue == 0) {
      maxValue = 10;
    }

    var data = new google.visualization.DataTable();
    data.addColumn('string', 'Time');
    data.addColumn('number', 'Visitors');
    data.addColumn('number', 'Hits');
    data.addRows(RealTimeStatsViewer.chart.intervals);
    for( var i=0; i<RealTimeStatsViewer.chart.intervals; i++ ) {
        data.setValue(i, 0, RealTimeStatsViewer.chart.labels[i]);
        data.setValue(i, 1, RealTimeStatsViewer.chart.uniques[i]);
        data.setValue(i, 2, RealTimeStatsViewer.chart.hits[i]);
    }
    var chart = new google.visualization.ColumnChart(document.getElementById('real_time_charts'));
    var color = '#754C28';
    chart.draw(data, {width: width,
                      height: height,
                      title: RealTimeStatsViewer.chart.from + ' - ' + RealTimeStatsViewer.chart.to,
                      legend: 'right',
                      colors: ['#C7CB2D', color],
                      backgroundColor: '#F2F7E3',
                      legendTextStyle: {color: color},
                      titleTextStyle: {color: color},
                      vAxis: {title: 'Visitors / Hits', minValue: 0, maxValue: maxValue, baselineColor: '#603813', textStyle: {color: color}, titleTextStyle: {color: color}},
                      hAxis: {title: 'Every ' + RealTimeStatsViewer.chart.range + ' minutes', textStyle: {color: color}, titleTextStyle: {color: color}}
                     });
  },

  realTimeChartsOnComplete: function(transport) {
    data = transport.responseText.evalJSON();

    if( typeof(data.range) == 'undefined' ) { return; }
    if( data.range != RealTimeStatsViewer.chart.range ) { return; }

    RealTimeStatsViewer.chart.from = data.from;
    RealTimeStatsViewer.chart.to = data.to;

    while( data.uniques.length > 0 )
      RealTimeStatsViewer.chart.uniques.unshift(data.uniques.pop());
    while( RealTimeStatsViewer.chart.uniques.length > RealTimeStatsViewer.chart.intervals )
      RealTimeStatsViewer.chart.uniques.pop();

    while( data.hits.length > 0 )
      RealTimeStatsViewer.chart.hits.unshift(data.hits.pop());
    while( RealTimeStatsViewer.chart.hits.length > RealTimeStatsViewer.chart.intervals )
      RealTimeStatsViewer.chart.hits.pop();

    while( data.labels.length > 0 )
      RealTimeStatsViewer.chart.labels.unshift(data.labels.pop());
    while( RealTimeStatsViewer.chart.labels.length > RealTimeStatsViewer.chart.intervals )
      RealTimeStatsViewer.chart.labels.pop();

    RealTimeStatsViewer.renderChart();

    if( RealTimeStatsViewer.chartTimer ) {
      clearTimeout(RealTimeStatsViewer.chartTimer);
      RealTimeStatsViewer.chartTimer = null;
    }
    RealTimeStatsViewer.chartTimer = setTimeout( 'RealTimeStatsViewer.requestRealTimeCharts(true);', RealTimeStatsViewer.chart.range*60*1000 );
  },

  realTimeChartsUrl: function(update, site_node_id) {
    var url = "/website/emarketing/real_time_charts_request";
    url += '?range=' + RealTimeStatsViewer.chart.range + '&intervals=' + RealTimeStatsViewer.chart.intervals;

    if(typeof(update) != 'undefined') { url += '&update=1'; }

    if(site_node_id) { url += "&site_node_id=" + site_node_id }

    return url;
  },

  requestRealTimeCharts: function(update, site_node_id) {
    new Ajax.Request(RealTimeStatsViewer.realTimeChartsUrl(update, site_node_id),
		     { onComplete: RealTimeStatsViewer.realTimeChartsOnComplete
		     });
  },

  onLoad: function () {
    RealTimeStatsViewer.requestRealTimeStats();
    RealTimeStatsViewer.requestRealTimeCharts();
  },

  closeDetailOverlay: function() {
    SCMS.closeOverlay();
  },

  detailOverlay: function(transport) {
    var html = '<div class="cms_form">';
    html += '<p align="right"><a href="javascript:void(0);" onclick="RealTimeStatsViewer.closeDetailOverlay();">[x] close</a></p>';
    html += transport.responseText;
    html += '</div>';
    SCMS.overlay( html );
  },

  detail: function(entry_id) {
    new Ajax.Request("/website/emarketing/visitor_detail/" + entry_id,
		     { method: 'get',
		       onComplete: RealTimeStatsViewer.detailOverlay
		     });
  }
}
