// License: LGPL-3.0-or-later
import { splitParam } from "..";

export default function parseCustomAmounts(customAmounts:string):number[] {
  return splitParam(customAmounts).map(Number).filter(i => !isNaN(i))
}