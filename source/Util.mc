using Toybox.Application as Application;
using Toybox.Lang as Lang;
using Toybox.System as System;
using Toybox.Weather as Weather;

function shortFourNumber(num as Lang.Number) as Lang.String {
  // 123 -> 123
  // 1234 -> 1234
  // 12345 -> 12k
  // 123456 -> 123k
  // 1234567 -> 1.2m
  // 12345678 -> 12m
  // 123456789 -> 123m
  if (num < 10000) {
    return num.format("%d");
  } else if (num < 1000000) {
    return (num / 1000).format("%d") + "k";
  } else if (num < 10000000) {
    return (num / 1000000.0).format("%.1f") + "m";
  }
  return (num / 1000000).format("%d") + "m";
}

function shortSixNumber(num as Lang.Number) as Lang.String {
  // 123 -> 123
  // 1234 -> 1234
  // 12345 -> 12345
  // 123456 -> 123456
  // 1234567 -> 1.234m
  // 12345678 -> 12.34m
  // 123456789 -> 123.4m
  if (num < 1000000) {
    return num.format("%d");
  } else if (num < 100000000) {
    return (num / 1000000.0).format("%.3f") + "m";
  } else if (num < 1000000000) {
    return (num / 1000000.0).format("%.2f") + "m";
  }
  return (num / 1000000.0).format("%.1f") + "m";
}

function getTemperature(
  celsius as Lang.Number,
  unit as System.UnitsSystem
) as Lang.Float {
  if (unit == System.UNIT_METRIC) {
    return celsius.toFloat();
  }
  return (celsius * 1.8 + 32).toFloat();
}

function resizeNumberArray(
  source as Lang.Array<Lang.Number?>,
  newSize as Lang.Number,
  defaultValue as Lang.Number?
) as Lang.Array<Lang.Number?> {
  var newArray = new Lang.Array<Lang.Number?>[newSize];
  var sourceSize = source.size();
  var size = sourceSize > newSize ? newSize : sourceSize;
  for (var i = 0; i < size; i++) {
    var newIndex = newSize - 1 - i;
    var sourceIndex = sourceSize - 1 - i;
    if (sourceIndex >= 0) {
      newArray[newIndex] = source[sourceIndex];
    } else {
      newArray[newIndex] = defaultValue;
    }
  }
  return newArray;
}

function shiftLeftNumberArray(
  source as Lang.Array<Lang.Number?>,
  value as Lang.Number?
) as Lang.Array<Lang.Number?> {
  var newArray = source.slice(1, null);
  newArray.add(value);
  return newArray;
}

function getDayOfWeekString(dayOfWeek as Lang.Number) as Lang.String? {
  switch (dayOfWeek) {
    case 1:
      return Application.loadResource(Rez.Strings.DayOfWeek1);
    case 2:
      return Application.loadResource(Rez.Strings.DayOfWeek2);
    case 3:
      return Application.loadResource(Rez.Strings.DayOfWeek3);
    case 4:
      return Application.loadResource(Rez.Strings.DayOfWeek4);
    case 5:
      return Application.loadResource(Rez.Strings.DayOfWeek5);
    case 6:
      return Application.loadResource(Rez.Strings.DayOfWeek6);
    case 7:
      return Application.loadResource(Rez.Strings.DayOfWeek7);
    default:
      return null;
  }
}

function getWeatherConditionString(condition as Lang.Number) as Lang.String? {
  switch (condition) {
    case Weather.CONDITION_CLEAR:
      return Application.loadResource(Rez.Strings.ConditionClear);
    case Weather.CONDITION_PARTLY_CLOUDY:
      return Application.loadResource(Rez.Strings.ConditionPartlyCloudy);
    case Weather.CONDITION_MOSTLY_CLOUDY:
      return Application.loadResource(Rez.Strings.ConditionMostlyCloudy);
    case Weather.CONDITION_RAIN:
      return Application.loadResource(Rez.Strings.ConditionRain);
    case Weather.CONDITION_SNOW:
      return Application.loadResource(Rez.Strings.ConditionSnow);
    case Weather.CONDITION_WINDY:
      return Application.loadResource(Rez.Strings.ConditionWindy);
    case Weather.CONDITION_THUNDERSTORMS:
      return Application.loadResource(Rez.Strings.ConditionThunderstorms);
    case Weather.CONDITION_WINTRY_MIX:
      return Application.loadResource(Rez.Strings.ConditionWintryMix);
    case Weather.CONDITION_FOG:
      return Application.loadResource(Rez.Strings.ConditionFog);
    case Weather.CONDITION_HAZY:
      return Application.loadResource(Rez.Strings.ConditionHazy);
    case Weather.CONDITION_HAIL:
      return Application.loadResource(Rez.Strings.ConditionHail);
    case Weather.CONDITION_SCATTERED_SHOWERS:
      return Application.loadResource(Rez.Strings.ConditionScatteredShowers);
    case Weather.CONDITION_SCATTERED_THUNDERSTORMS:
      return Application.loadResource(
        Rez.Strings.ConditionScatteredThunderstorms
      );
    case Weather.CONDITION_UNKNOWN_PRECIPITATION:
      return Application.loadResource(
        Rez.Strings.ConditionUnknownPrecipitation
      );
    case Weather.CONDITION_LIGHT_RAIN:
      return Application.loadResource(Rez.Strings.ConditionLightRain);
    case Weather.CONDITION_HEAVY_RAIN:
      return Application.loadResource(Rez.Strings.ConditionHeavyRain);
    case Weather.CONDITION_LIGHT_SNOW:
      return Application.loadResource(Rez.Strings.ConditionLightSnow);
    case Weather.CONDITION_HEAVY_SNOW:
      return Application.loadResource(Rez.Strings.ConditionHeavySnow);
    case Weather.CONDITION_LIGHT_RAIN_SNOW:
      return Application.loadResource(Rez.Strings.ConditionLightRainSnow);
    case Weather.CONDITION_HEAVY_RAIN_SNOW:
      return Application.loadResource(Rez.Strings.ConditionHeavyRainSnow);
    case Weather.CONDITION_CLOUDY:
      return Application.loadResource(Rez.Strings.ConditionCloudy);
    case Weather.CONDITION_RAIN_SNOW:
      return Application.loadResource(Rez.Strings.ConditionRainSnow);
    case Weather.CONDITION_PARTLY_CLEAR:
      return Application.loadResource(Rez.Strings.ConditionPartlyClear);
    case Weather.CONDITION_MOSTLY_CLEAR:
      return Application.loadResource(Rez.Strings.ConditionMostlyClear);
    case Weather.CONDITION_LIGHT_SHOWERS:
      return Application.loadResource(Rez.Strings.ConditionLightShowers);
    case Weather.CONDITION_SHOWERS:
      return Application.loadResource(Rez.Strings.ConditionShowers);
    case Weather.CONDITION_HEAVY_SHOWERS:
      return Application.loadResource(Rez.Strings.ConditionHeavyShowers);
    case Weather.CONDITION_CHANCE_OF_SHOWERS:
      return Application.loadResource(Rez.Strings.ConditionChanceOfShowers);
    case Weather.CONDITION_CHANCE_OF_THUNDERSTORMS:
      return Application.loadResource(
        Rez.Strings.ConditionChanceOfThunderstorms
      );
    case Weather.CONDITION_MIST:
      return Application.loadResource(Rez.Strings.ConditionMist);
    case Weather.CONDITION_DUST:
      return Application.loadResource(Rez.Strings.ConditionDust);
    case Weather.CONDITION_DRIZZLE:
      return Application.loadResource(Rez.Strings.ConditionDrizzle);
    case Weather.CONDITION_TORNADO:
      return Application.loadResource(Rez.Strings.ConditionTornado);
    case Weather.CONDITION_SMOKE:
      return Application.loadResource(Rez.Strings.ConditionSmoke);
    case Weather.CONDITION_ICE:
      return Application.loadResource(Rez.Strings.ConditionIce);
    case Weather.CONDITION_SAND:
      return Application.loadResource(Rez.Strings.ConditionSand);
    case Weather.CONDITION_SQUALL:
      return Application.loadResource(Rez.Strings.ConditionSquall);
    case Weather.CONDITION_SANDSTORM:
      return Application.loadResource(Rez.Strings.ConditionSandstorm);
    case Weather.CONDITION_VOLCANIC_ASH:
      return Application.loadResource(Rez.Strings.ConditionVolcanicAsh);
    case Weather.CONDITION_HAZE:
      return Application.loadResource(Rez.Strings.ConditionHaze);
    case Weather.CONDITION_FAIR:
      return Application.loadResource(Rez.Strings.ConditionFair);
    case Weather.CONDITION_HURRICANE:
      return Application.loadResource(Rez.Strings.ConditionHurricane);
    case Weather.CONDITION_TROPICAL_STORM:
      return Application.loadResource(Rez.Strings.ConditionTropicalStorm);
    case Weather.CONDITION_CHANCE_OF_SNOW:
      return Application.loadResource(Rez.Strings.ConditionChanceOfSnow);
    case Weather.CONDITION_CHANCE_OF_RAIN_SNOW:
      return Application.loadResource(Rez.Strings.ConditionChanceOfRainSnow);
    case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN:
      return Application.loadResource(Rez.Strings.ConditionCloudyChanceOfRain);
    case Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW:
      return Application.loadResource(Rez.Strings.ConditionCloudyChanceOfSnow);
    case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW:
      return Application.loadResource(
        Rez.Strings.ConditionCloudyChanceOfRainSnow
      );
    case Weather.CONDITION_FLURRIES:
      return Application.loadResource(Rez.Strings.ConditionFlurries);
    case Weather.CONDITION_FREEZING_RAIN:
      return Application.loadResource(Rez.Strings.ConditionFreezingRain);
    case Weather.CONDITION_SLEET:
      return Application.loadResource(Rez.Strings.ConditionSleet);
    case Weather.CONDITION_ICE_SNOW:
      return Application.loadResource(Rez.Strings.ConditionIceSnow);
    case Weather.CONDITION_THIN_CLOUDS:
      return Application.loadResource(Rez.Strings.ConditionThinClouds);
    case Weather.CONDITION_UNKNOWN:
      return Application.loadResource(Rez.Strings.ConditionUnknown);
    default:
      return null;
  }
}
