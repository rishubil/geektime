using Toybox.Activity as Activity;
using Toybox.ActivityMonitor as ActivityMonitor;
using Toybox.Application as Application;
using Toybox.Application.Storage as Storage;
using Toybox.Application.Properties as Properties;
using Toybox.Graphics as Graphics;
using Toybox.Lang as Lang;
using Toybox.System as System;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.WatchUi as WatchUi;
using Toybox.Weather as Weather;

// TODO: Handle very long weather condition string - marquee?

class GeektimeView extends WatchUi.WatchFace {
  var nwGalmuri11BoldNum as Graphics.FontType? = null;
  var nwGalmuriMono7Num as Graphics.FontType? = null;
  var nwFade as Graphics.FontType? = null;

  // BEGIN PROPERTIES
  var stepGraphDurationSec = Gregorian.SECONDS_PER_MINUTE * 15;
  var stepGraphBarWidth = 2;
  var stepGraphBarGap = 1;
  var breathGraphDurationSec = Gregorian.SECONDS_PER_MINUTE * 15;
  var breathGraphPointGap = 3;
  var oxygenGraphDurationSec = Gregorian.SECONDS_PER_MINUTE * 15;
  // END PROPERTIES

  // BEGIN VALUES
  var lastStep as Lang.Number = 0;
  var lastStepAt as Time.Moment = Time.now();
  var maxStepDiff as Lang.Number = 0;
  var stepDiffs as Lang.Array<Lang.Number?> = [];

  var lastBreathAt as Time.Moment = Time.now();
  var minBreath as Lang.Number = 255;
  var maxBreath as Lang.Number = 0;
  var breathSamples as Lang.Array<Lang.Number?> = [];

  var lastOxygenAt as Time.Moment = Time.now();
  var minOxygen as Lang.Number = 255;
  var oxygenSamples as Lang.Array<Lang.Number?> = [];
  // END VALUES

  function initValues() as Void {
    var stepGraphBarCount = getStepGraphBarCount();
    stepDiffs = resizeNumberArray(stepDiffs, stepGraphBarCount, null);

    var breathGraphPointCount = getBreathGraphPointCount();
    breathSamples = resizeNumberArray(
      breathSamples,
      breathGraphPointCount,
      null
    );

    oxygenSamples = resizeNumberArray(oxygenSamples, OXYGEN_GRAPH_COUNT, null);

    lastStepAt = Time.now().subtract(new Time.Duration(stepGraphDurationSec));
    lastBreathAt = Time.now().subtract(
      new Time.Duration(breathGraphDurationSec)
    );
    lastOxygenAt = Time.now().subtract(
      new Time.Duration(oxygenGraphDurationSec)
    );
  }

  function initialize() {
    WatchFace.initialize();

    loadProperties();
    initValues();
  }

  // Load your resources here
  function onLayout(dc as Graphics.Dc) as Void {
    setLayout(Rez.Layouts.WatchFace(dc));

    nwGalmuri11BoldNum = WatchUi.loadResource(Rez.Fonts.NWGalmuri11BoldNum);
    nwGalmuriMono7Num = WatchUi.loadResource(Rez.Fonts.NWGalmuriMono7Num);
    nwFade = WatchUi.loadResource(Rez.Fonts.NWFade);
  }

  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() as Void {
    loadState();
  }

  // Update the view
  function onUpdate(dc as Graphics.Dc) as Void {
    var deviceSetting = System.getDeviceSettings();
    var now = Time.now();
    var today = Time.today();
    var nowGregorian = Gregorian.info(now, Time.FORMAT_SHORT);
    var nowUtcGregorian = Gregorian.utcInfo(now, Time.FORMAT_SHORT);
    var stat = System.getSystemStats();
    var nowWeather = Weather.getCurrentConditions();
    var todayWeather = getTodayWeather(today);
    var activityInfo = Activity.getActivityInfo();
    var activityMonitorInfo = ActivityMonitor.getInfo();
    var hrIterator = ActivityMonitor.getHeartRateHistory(
      HR_GRAPH_POINT_COUNT,
      false
    );

    updateStepInfo(now, activityMonitorInfo);
    updateBreathInfo(now, activityMonitorInfo);
    updateOxygenInfo(now, activityInfo);

    // BEGIN UPDATE LABELS

    var battString = "";
    if (stat.charging) {
      battString = Lang.format("$1$%", [stat.battery.format("%3d")]);
    } else {
      battString = Lang.format("$1$D", [stat.batteryInDays.format("%2.1f")]);
    }
    (View.findDrawableById("battLabel") as WatchUi.Text).setText(battString);

    var hrMaxString = "-";
    var hrMinString = "-";
    var hrString = "-";
    var hrMax = hrIterator.getMax();
    var hrMin = hrIterator.getMin();
    if (hrMax != null && hrMax != ActivityMonitor.INVALID_HR_SAMPLE) {
      hrMaxString = hrMax.format("%d");
    }
    if (hrMin != null && hrMin != ActivityMonitor.INVALID_HR_SAMPLE) {
      hrMinString = hrMin.format("%d");
    }
    if (activityInfo != null && activityInfo.currentHeartRate != null) {
      hrString = activityInfo.currentHeartRate.format("%d");
    }
    (View.findDrawableById("hrMaxLabel") as WatchUi.Text).setText(hrMaxString);
    (View.findDrawableById("hrMinLabel") as WatchUi.Text).setText(hrMinString);
    (View.findDrawableById("hrLabel") as WatchUi.Text).setText(hrString);

    var notiString = shortFourNumber(deviceSetting.notificationCount);
    (View.findDrawableById("notiLabel") as WatchUi.Text).setText(notiString);

    var dateString = Lang.format("$1$-$2$-$3$ ($4$)", [
      nowGregorian.year,
      nowGregorian.month.format("%02d"),
      nowGregorian.day.format("%02d"),
      getDayOfWeekString(nowGregorian.day_of_week),
    ]);
    (View.findDrawableById("dateLabel") as WatchUi.Text).setText(dateString);

    var timeString = Lang.format("$1$:$2$", [
      nowGregorian.hour.format("%02d"),
      nowGregorian.min.format("%02d"),
    ]);
    (View.findDrawableById("timeLabel") as WatchUi.Text).setText(timeString);

    var timeOffset = System.getClockTime().timeZoneOffset; // in seconds
    var timeOffsetHour = (timeOffset / 3600).abs();
    var timeOffsetMin = ((timeOffset % 3600) / 60).abs();
    var timeOffsetString = Lang.format("$1$$2$$3$", [
      timeOffset >= 0 ? "+" : "-",
      timeOffsetHour.format("%02d"),
      timeOffsetMin.format("%02d"),
    ]);
    (View.findDrawableById("timeOffsetLabel") as WatchUi.Text).setText(
      timeOffsetString
    );

    var utcPreString = Lang.format("$1$-$2$-$3$ $4$:$5$:", [
      nowUtcGregorian.year,
      nowUtcGregorian.month.format("%02d"),
      nowUtcGregorian.day.format("%02d"),
      nowUtcGregorian.hour.format("%02d"),
      nowUtcGregorian.min.format("%02d"),
    ]);
    (View.findDrawableById("utcPreLabel") as WatchUi.Text).setText(
      utcPreString
    );

    var nowTempString = "-";
    var nowWeatherString = "-";
    if (nowWeather != null) {
      if (nowWeather.temperature != null) {
        nowTempString = Lang.format("$1$°", [
          getTemperature(
            nowWeather.temperature,
            deviceSetting.temperatureUnits
          ).format("%d"),
        ]);
      }
      if (nowWeather.condition != null) {
        var conditionString = getWeatherConditionString(nowWeather.condition);
        if (conditionString != null) {
          nowWeatherString = conditionString;
        }
      }
    }
    (View.findDrawableById("nowTempLabel") as WatchUi.Text).setText(
      nowTempString
    );
    (View.findDrawableById("nowWeatherLabel") as WatchUi.Text).setText(
      nowWeatherString
    );

    var todayTempString = "-/-";
    var todayWeatherString = "-";
    if (todayWeather != null) {
      todayTempString = Lang.format("$1$°/$2$°", [
        todayWeather.highTemperature != null
          ? getTemperature(
              // cast to Lang.Number to avoid type error (sdk bug?)
              todayWeather.highTemperature as Lang.Number,
              deviceSetting.temperatureUnits
            ).format("%d")
          : "-",
        todayWeather.lowTemperature != null
          ? getTemperature(
              todayWeather.lowTemperature,
              deviceSetting.temperatureUnits
            ).format("%d")
          : "-",
      ]);
      if (todayWeather.condition != null) {
        var conditionString = getWeatherConditionString(todayWeather.condition);
        if (conditionString != null) {
          todayWeatherString = conditionString;
        }
      }
    }
    (View.findDrawableById("todayTempLabel") as WatchUi.Text).setText(
      todayTempString
    );
    (View.findDrawableById("todayWeatherLabel") as WatchUi.Text).setText(
      todayWeatherString
    );

    var stepString = "-";
    if (activityMonitorInfo.steps != null) {
      stepString = shortSixNumber(activityMonitorInfo.steps);
    }
    (View.findDrawableById("stepLabel") as WatchUi.Text).setText(stepString);

    var breathString = "-";
    if (activityMonitorInfo.respirationRate != null) {
      breathString = activityMonitorInfo.respirationRate.format("%d");
    }
    (View.findDrawableById("breathLabel") as WatchUi.Text).setText(
      breathString
    );

    var oxygenString = "-";
    if (activityInfo != null && activityInfo.currentOxygenSaturation != null) {
      oxygenString = Lang.format("$1$%", [
        activityInfo.currentOxygenSaturation.format("%d"),
      ]);
    }
    (View.findDrawableById("oxygenLabel") as WatchUi.Text).setText(
      oxygenString
    );

    // END UPDATE LABELS

    // BEGIN UPDATE ICONS

    (View.findDrawableById("connIcon") as WatchUi.Bitmap).setBitmap(
      deviceSetting.connectionAvailable
        ? Rez.Drawables.ConnOnIcon
        : Rez.Drawables.ConnOffIcon
    );

    (View.findDrawableById("dndIcon") as WatchUi.Bitmap).setBitmap(
      deviceSetting.doNotDisturb
        ? Rez.Drawables.DndOnIcon
        : Rez.Drawables.DndOffIcon
    );

    (View.findDrawableById("battIcon") as WatchUi.Bitmap).setBitmap(
      stat.charging ? Rez.Drawables.BattOnIcon : Rez.Drawables.BattOffIcon
    );

    (View.findDrawableById("notiIcon") as WatchUi.Bitmap).setBitmap(
      deviceSetting.notificationCount > 0
        ? Rez.Drawables.NotiOnIcon
        : Rez.Drawables.NotiOffIcon
    );

    // END UPDATE ICONS

    // Call the parent onUpdate function to redraw the layout
    View.onUpdate(dc);

    // BEGIN UPDATE GRAPHS

    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

    drawLineChart(
      dc,
      hrIterator.getMax(),
      hrIterator.getMin(),
      getHrSamples(hrIterator, HR_GRAPH_POINT_COUNT),
      {
        "chartX" => HR_GRAPH_RIGHT,
        "chartY" => HR_GRAPH_TOP,
        "pointMaxHeight" => HR_GRAPH_POINT_MAX_HEIGHT,
        "pointGap" => HR_GRAPH_POINT_GAP,
        "pointWidth" => HR_GRAPH_POINT_WIDTH,
        "lineWidth" => HR_GRAPH_LINE_WIDTH,
      }
    );

    drawBarChart(
      dc,
      maxStepDiff,
      stepDiffs,
      STEP_GRAPH_RIGHT,
      STEP_GRAPH_TOP,
      STEP_GRAPH_BAR_MAX_HEIGHT,
      stepGraphBarWidth,
      stepGraphBarGap
    );

    drawLineChart(dc, maxBreath, minBreath, breathSamples, {
      "chartX" => BREATH_GRAPH_RIGHT,
      "chartY" => BREATH_GRAPH_TOP,
      "pointMaxHeight" => BREATH_GRAPH_POINT_MAX_HEIGHT,
      "pointGap" => breathGraphPointGap,
      "pointWidth" => BREATH_GRAPH_POINT_WIDTH,
      "lineWidth" => BREATH_GRAPH_LINE_WIDTH,
    });

    drawFadeChart(
      dc,
      nwFade,
      minOxygen,
      oxygenSamples,
      OXYGEN_GRAPH_RIGHT,
      OXYGEN_GRAPH_TOP
    );

    // END UPDATE GRAPHS

    // BEGIN UPDATE SEC
    var secString = nowGregorian.sec.format("%02d");
    var utcSecString = nowUtcGregorian.sec.format("%02d");

    drawSec(dc, secString, utcSecString);
    // END UPDATE SEC
  }

  function onPartialUpdate(dc as Graphics.Dc) as Void {
    var now = Time.now();
    var nowGregorian = Gregorian.info(now, Time.FORMAT_SHORT);
    var nowUtcGregorian = Gregorian.utcInfo(now, Time.FORMAT_SHORT);
    var secString = nowGregorian.sec.format("%02d");
    var utcSecString = nowUtcGregorian.sec.format("%02d");

    drawSec(dc, secString, utcSecString);
  }

  // Called when this View is removed from the screen. Save the
  // state of this View here. This includes freeing resources from
  // memory.
  function onHide() as Void {
    saveState();
  }

  // The user has just looked at their watch. Timers and animations may be started here.
  function onExitSleep() as Void {}

  // Terminate any active timers and prepare for slow updates.
  function onEnterSleep() as Void {}

  function saveState() as Void {
    Storage.setValue("lastStep", lastStep);
    Storage.setValue("lastStepAt", lastStepAt.value());
    Storage.setValue("maxStepDiff", maxStepDiff);
    Storage.setValue("stepDiffs", stepDiffs);
    Storage.setValue("lastBreathAt", lastBreathAt.value());
    Storage.setValue("minBreath", minBreath);
    Storage.setValue("maxBreath", maxBreath);
    Storage.setValue("breathSamples", breathSamples);
    Storage.setValue("lastOxygenAt", lastOxygenAt.value());
    Storage.setValue("minOxygen", minOxygen);
    Storage.setValue("oxygenSamples", oxygenSamples);
  }

  function loadState() as Void {
    var gvLastStep = Storage.getValue("lastStep");
    if (gvLastStep != null) {
      lastStep = gvLastStep;
    }
    var gvLastStepAt = Storage.getValue("lastStepAt");
    if (gvLastStepAt != null) {
      lastStepAt = new Time.Moment(gvLastStepAt);
    }
    var gvMaxStepDiff = Storage.getValue("maxStepDiff");
    if (gvMaxStepDiff != null) {
      maxStepDiff = gvMaxStepDiff;
    }
    var gvStepDiffs = Storage.getValue("stepDiffs");
    if (gvStepDiffs != null) {
      stepDiffs = gvStepDiffs;
    }
    var gvLastBreathAt = Storage.getValue("lastBreathAt");
    if (gvLastBreathAt != null) {
      lastBreathAt = new Time.Moment(gvLastBreathAt);
    }
    var gvMinBreath = Storage.getValue("minBreath");
    if (gvMinBreath != null) {
      minBreath = gvMinBreath;
    }
    var gvMaxBreath = Storage.getValue("maxBreath");
    if (gvMaxBreath != null) {
      maxBreath = gvMaxBreath;
    }
    var gvBreathSamples = Storage.getValue("breathSamples");
    if (gvBreathSamples != null) {
      breathSamples = gvBreathSamples;
    }
    var gvLastOxygenAt = Storage.getValue("lastOxygenAt");
    if (gvLastOxygenAt != null) {
      lastOxygenAt = new Time.Moment(gvLastOxygenAt);
    }
    var gvMinOxygen = Storage.getValue("minOxygen");
    if (gvMinOxygen != null) {
      minOxygen = gvMinOxygen;
    }
    var gvOxygenSamples = Storage.getValue("oxygenSamples");
    if (gvOxygenSamples != null) {
      oxygenSamples = gvOxygenSamples;
    }
  }

  function loadProperties() as Void {
    try {
      stepGraphDurationSec = Properties.getValue("stepGraphDurationSec");
    } catch (e) {
      // ignore
    }
    try {
      stepGraphBarWidth = Properties.getValue("stepGraphBarWidth");
    } catch (e) {
      // ignore
    }
    try {
      stepGraphBarGap = Properties.getValue("stepGraphBarGap");
    } catch (e) {
      // ignore
    }
    try {
      breathGraphDurationSec = Properties.getValue("breathGraphDurationSec");
    } catch (e) {
      // ignore
    }
    try {
      breathGraphPointGap = Properties.getValue("breathGraphPointGap");
    } catch (e) {
      // ignore
    }
    try {
      oxygenGraphDurationSec = Properties.getValue("oxygenGraphDurationSec");
    } catch (e) {
      // ignore
    }
  }

  (:inline)
  function getStepGraphBarCount() {
    return (
      (STEP_GRAPH_RIGHT - STEP_GRAPH_LEFT) /
      (stepGraphBarWidth + stepGraphBarGap)
    );
  }

  (:inline)
  function getBreathGraphPointCount() {
    return (BREATH_GRAPH_RIGHT - BREATH_GRAPH_LEFT) / breathGraphPointGap;
  }

  function getTodayWeather(today as Time.Moment) as Weather.DailyForecast? {
    var dailyWeathers = Weather.getDailyForecast();
    if (dailyWeathers != null) {
      var oneDay = new Time.Duration(Gregorian.SECONDS_PER_DAY);
      var dailyWeathersSize = dailyWeathers.size();
      for (var i = 0; i < dailyWeathersSize; i++) {
        var forcastTime = dailyWeathers[i].forecastTime;
        if (forcastTime == null) {
          continue;
        }
        if (oneDay.greaterThan(forcastTime.subtract(today))) {
          return dailyWeathers[i];
        }
      }
    }
    return null;
  }

  function updateStepInfo(
    now as Time.Moment,
    activityMonitorInfo as ActivityMonitor.Info
  ) as Void {
    var steps = activityMonitorInfo.steps;
    var stepDuration = now.subtract(lastStepAt) as Time.Duration;
    if (
      stepDuration.compare(new Time.Duration(stepGraphDurationSec)) == 0 ||
      stepDuration.greaterThan(new Time.Duration(stepGraphDurationSec))
    ) {
      lastStepAt = now;
      if (steps != null) {
        if (lastStep == 0) {
          lastStep = steps;
        }
        // stepDuration is not exact, so we need to calculate the factor
        var factor =
          stepDuration.value().toFloat() /
          (new Time.Duration(stepGraphDurationSec)).value();
        var stepDiff = (steps - lastStep) / factor;
        lastStep = steps;
        stepDiffs = shiftLeftNumberArray(stepDiffs, stepDiff.toNumber());
      } else {
        stepDiffs = shiftLeftNumberArray(stepDiffs, null);
      }
    }
    maxStepDiff = 0;
    for (var i = 0; i < stepDiffs.size(); i++) {
      if (stepDiffs[i] == null) {
        continue;
      }
      if (stepDiffs[i] > maxStepDiff) {
        maxStepDiff = stepDiffs[i];
      }
    }
  }

  function updateBreathInfo(
    now as Time.Moment,
    activityMonitorInfo as ActivityMonitor.Info
  ) as Void {
    var breath = activityMonitorInfo.respirationRate;
    var breathDuration = now.subtract(lastBreathAt) as Time.Duration;
    if (
      breathDuration.compare(new Time.Duration(breathGraphDurationSec)) == 0 ||
      breathDuration.greaterThan(new Time.Duration(breathGraphDurationSec))
    ) {
      lastBreathAt = now;
      if (breath != null) {
        breathSamples = shiftLeftNumberArray(breathSamples, breath.toNumber());
      } else {
        breathSamples = shiftLeftNumberArray(breathSamples, null);
      }
    }
    minBreath = 100;
    maxBreath = 0;
    for (var i = 0; i < breathSamples.size(); i++) {
      if (breathSamples[i] == null) {
        continue;
      }
      if (breathSamples[i] < minBreath) {
        minBreath = breathSamples[i];
      }
      if (breathSamples[i] > maxBreath) {
        maxBreath = breathSamples[i];
      }
    }
  }

  function updateOxygenInfo(
    now as Time.Moment,
    activityInfo as Activity.Info?
  ) as Void {
    var oxygen =
      activityInfo != null ? activityInfo.currentOxygenSaturation : null;
    var oxygenDuration = now.subtract(lastOxygenAt) as Time.Duration;
    if (
      oxygenDuration.compare(new Time.Duration(oxygenGraphDurationSec)) == 0 ||
      oxygenDuration.greaterThan(new Time.Duration(oxygenGraphDurationSec))
    ) {
      lastOxygenAt = now;
      if (oxygen != null) {
        oxygenSamples = shiftLeftNumberArray(oxygenSamples, oxygen.toNumber());
      } else {
        oxygenSamples = shiftLeftNumberArray(oxygenSamples, null);
      }
    }
    minOxygen = 100;
    for (var i = 0; i < oxygenSamples.size(); i++) {
      if (oxygenSamples[i] == null) {
        continue;
      }
      if (oxygenSamples[i] < minOxygen) {
        minOxygen = oxygenSamples[i];
      }
    }
  }

  function getHrSamples(
    hrIterator as ActivityMonitor.HeartRateIterator,
    size as Lang.Number
  ) as Lang.Array<Lang.Number?> {
    var hrSamples = new Lang.Array<Lang.Number?>[size];
    for (var i = 0; i < size; i++) {
      var sample = hrIterator.next();
      if (sample == null) {
        break;
      }
      if (sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
        hrSamples.add(sample.heartRate);
      } else {
        hrSamples.add(null);
      }
    }
    return hrSamples;
  }

  function drawSec(
    dc as Graphics.Dc,
    secString as Lang.String,
    utcSecString as Lang.String
  ) as Void {
    if (nwGalmuri11BoldNum != null) {
      dc.setClip(SEC_X, SEC_Y, SEC_W, SEC_H);
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
      dc.clear();
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
      dc.drawText(
        SEC_X,
        SEC_Y,
        nwGalmuri11BoldNum,
        secString,
        Graphics.TEXT_JUSTIFY_LEFT
      );
      dc.clearClip();
    }
    if (nwGalmuriMono7Num != null) {
      dc.setClip(UTC_SEC_X, UTC_SEC_Y, UTC_SEC_W, UTC_SEC_H);
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
      dc.clear();
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
      dc.drawText(
        UTC_SEC_X,
        UTC_SEC_Y,
        nwGalmuriMono7Num,
        utcSecString,
        Graphics.TEXT_JUSTIFY_LEFT
      );
      dc.clearClip();
    }
  }

  function drawBarChart(
    dc as Graphics.Dc,
    maxValue as Lang.Number,
    values as Lang.Array<Lang.Number?>,
    chartX as Lang.Number, // right of the chart
    chartY as Lang.Number, // top of the chart
    barMaxHeight as Lang.Number,
    barWidth as Lang.Number,
    barGap as Lang.Number
  ) as Void {
    if (maxValue > 0) {
      for (var i = 0; i < values.size(); i++) {
        var value = values[values.size() - i - 1];
        if (value == null) {
          continue;
        }
        var height = ((value.toFloat() / maxValue) * barMaxHeight).toNumber();
        var width = barWidth;
        var x = chartX - i * (barWidth + barGap);
        var y = chartY + barMaxHeight - height;
        dc.fillRectangle(x, y, width, height);
      }
    }
  }

  function drawLineChart(
    dc as Graphics.Dc,
    maxValue as Lang.Number,
    minValue as Lang.Number,
    values as Lang.Array<Lang.Number?>,
    options as Lang.Dictionary
  ) as Void {
    var chartX = options.get("chartX") as Lang.Number; // right of the chart
    var chartY = options.get("chartY") as Lang.Number; // top of the chart
    var pointMaxHeight = options.get("pointMaxHeight") as Lang.Number;
    var pointGap = options.get("pointGap") as Lang.Number;
    var pointWidth = options.get("pointWidth") as Lang.Number;
    var lineWidth = options.get("lineWidth") as Lang.Number;
    if (maxValue == minValue) {
      return;
    }
    dc.setPenWidth(lineWidth);
    var lastX = null;
    var lastY = null;
    var lastLastX = null;
    var lastLastY = null;
    for (var i = 0; i < values.size(); i++) {
      var value = values[values.size() - i - 1];
      if (value == null) {
        if (
          lastX != null &&
          lastY != null &&
          lastLastX == null &&
          lastLastY == null
        ) {
          dc.fillCircle(lastX as Lang.Number, lastY as Lang.Number, pointWidth);
        }
        lastLastX = lastX;
        lastLastY = lastY;
        lastX = null;
        lastY = null;
        continue;
      }
      var height = (
        ((value - minValue).toFloat() / (maxValue - minValue)) *
        pointMaxHeight
      ).toNumber();
      var x = chartX - i * pointGap;
      var y = chartY + pointMaxHeight - height;
      if (lastX != null && lastY != null) {
        dc.drawLine(lastX as Lang.Number, lastY as Lang.Number, x, y);
      }
      lastLastX = lastX;
      lastLastY = lastY;
      lastX = x;
      lastY = y;
    }
    dc.setPenWidth(1);
  }

  function drawFadeChart(
    dc as Graphics.Dc,
    fadeFont as Graphics.FontType,
    minValue as Lang.Number,
    values as Lang.Array<Lang.Number?>,
    chartX as Lang.Number, // right of the chart
    chartY as Lang.Number // top of the chart
  ) as Void {
    var chartString = "";
    for (var i = 0; i < values.size(); i++) {
      var value = values[values.size() - i - 1];
      var fadeChar = "0";
      if (value != null && value != 0) {
        if (minValue < 100) {
          var fadeRatio = (value - minValue).toFloat() / (100 - minValue);
          fadeChar = (fadeRatio * 8 + 1).toNumber().format("%d");
        } else {
          fadeChar = "9";
        }
      }
      chartString = fadeChar + chartString;
    }
    dc.drawText(
      chartX,
      chartY,
      fadeFont,
      chartString,
      Graphics.TEXT_JUSTIFY_RIGHT
    );
  }
}
