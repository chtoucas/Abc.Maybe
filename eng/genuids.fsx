// See LICENSE in the project root for license information.

open System
open System.Globalization

let start = new DateTime(2020, 1, 1, 0, 0, 0, DateTimeKind.Utc);
let now = DateTime.UtcNow;
let isMorning = now.Hour < 12;
let hour = if isMorning then 0 else 12

let mid = new DateTime(now.Year, now.Month, now.Day, hour, 0, 0, DateTimeKind.Utc);

let halfDays = 2 * (now - start).Days - (if isMorning then 1 else 0)
let seconds = (now - mid).TotalSeconds

let buildNumber = uint16(halfDays - 1)
let revisionNumber = uint16(seconds)

let revisionString = revisionNumber.ToString(CultureInfo.InvariantCulture);
let serialNumber = revisionString.PadLeft(5, '0')

printfn "%i;%i;%i%s" buildNumber revisionNumber buildNumber serialNumber
