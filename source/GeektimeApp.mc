import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class GeektimeApp extends Application.AppBase {
  var watchfaceView as GeektimeView? = null;

  function initialize() {
    AppBase.initialize();
  }

  // onStart() is called on application start up
  function onStart(state as Dictionary?) as Void {
    if (watchfaceView != null) {
      watchfaceView.loadState();
    }
  }

  // onStop() is called when your application is exiting
  function onStop(state as Dictionary?) as Void {
    watchfaceView.saveState();
  }

  // Return the initial view of your application here
  function getInitialView() as Array<Views or InputDelegates>? {
    watchfaceView = new GeektimeView();
    return [watchfaceView] as Array<Views or InputDelegates>;
  }

  function onSettingsChanged() {
    watchfaceView.loadProperties();
    watchfaceView.initValues();
    WatchUi.requestUpdate(); // update the view to reflect changes
  }
}

function getApp() as GeektimeApp {
  return Application.getApp() as GeektimeApp;
}
