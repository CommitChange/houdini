// License: LGPL-3.0-or-later

// Given an end dateTime ("2015-11-17 19:00") and a time-zone ("America/Los_Angeles"),
// if the end dateTime has passed, return false
// if the end dateTime is more than a day away
//   then return the number of days away
// if the end dateTime is less than a day away
//   then return a countdown stream with seconds precision
//
// This function returns a stream.
//
// This function takes a timezone in the format "Country/City"
// See here: http://momentjs.com/timezone/
//

declare function timeRemaining(endDateTime:string, tz?:string):() => string|false;

export default timeRemaining;
