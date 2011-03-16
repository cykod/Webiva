
WebivaExperiment = {
  submitted: false,

  success: function(experiment_id, delay) {
    if(delay) {
      setTimeout( function() { WebivaExperiment.finished(experiment_id); }, delay * 1000 );
    } else {
      WebivaExperiment.finished(experiment_id);
    }
  },

  finished: function(experiment_id) {
    if(! experiment_id || WebivaExperiment.submitted) { return; }
    WebivaExperiment.submitted = true;
    var script = document.createElement('script');
    script.src = '/website/editor/action/exp/' + experiment_id;
    document.documentElement.firstChild.appendChild(script);
  },

  onclick: function(experiment_id, link) {
    WebivaExperiment.finished(experiment_id);
    setTimeout(function() { document.location = link.href; }, 100);
    return false;
  }
};
