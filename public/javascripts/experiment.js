
WebivaExperiment = {
  success: function(experiment_id, delay) {
    if(delay) {
      setTimeout( function() { WebivaExperiment.finished(experiment_id); }, delay * 1000 );
    } else {
      WebivaExperiment.finished(experiment_id);
    }
  },

  finished: function(experiment_id) {
    if(! experiment_id) { return; }
    var script = document.createElement('script');
    script.src = '/website/editor/action/exp/' + experiment_id;
    document.documentElement.firstChild.appendChild(script);
  }
};
