
WebivaExporter = function(opts) {
  var $ = jQuery;
  var buttonId = opts.button;
  var statusId = opts.status ? opts.status : buttonId + '_status';
  var generateUrl = opts.url;
  var frm = opts.frm;
  var statusUrl = opts.statusUrl ? opts.statusUrl : '/website/file/export_status';
  var downloadUrl = opts.downloadUrl ? opts.downloadUrl : '/website/file/export_file';
  var onComplete = opts.onComplete;

  function showButton() {
    if(buttonId) {
      $(buttonId).show();
    }

    $(statusId).hide();

    if(onComplete) {
      onComplete();
    }
  }

  function download() {
    $(statusId).html("Starting Download");
    document.location = downloadUrl;
    setTimeout(function(){showButton();}, 3000);
  }

  function failure() {
    $(statusId).html("Download Failed");
    setTimeout(function(){showButton();}, 3000);
  }

  function status() {
    $.get(statusUrl, function(data) {
      if(data.completed) {
        download();
      } else if(data.failed) {
        failure();
      } else {
        $(statusId).html('Still Exporting...');
        setTimeout(function() {status();}, 1000);
      }
    });
  }

  if(buttonId && generateUrl) {
    $(buttonId).click(function() {
      $(buttonId).hide();
      $(statusId).show();
      $(statusId).html('Exporting File');
  
      var data = frm ? $(frm).serialize() : null;
      $.post(generateUrl, data, function(data) {
        $(statusId).html('Generating File');
        status();
      });
    });
  } else if(statusId) {
    setTimeout(function() {status();}, 500);
  }
};
