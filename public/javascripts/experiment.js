
WebivaExperiment = {
  success: function(experiment_id, delay) {
    if(delay) {
      setTimeout( function() { WebivaExperiment.finished(experiment_id); }, delay * 1000 );
    } else {
      WebivaExperiment.finished(experiment_id);
    }
  },

  finished: function(experiment_id) {
    alert( 'experiment: ' + experiment_id + ' was completed' );
  }
};
