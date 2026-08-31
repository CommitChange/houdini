// License: LGPL-3.0-or-later
import { AmountButtonDesc } from "../../amt";
const h = require('snabbdom/h');



export default function amount_button_contents(currency_symbol: string, amt: AmountButtonDesc):  ReturnType<typeof h>[] {

  return [
    h('span.dollar', currency_symbol),
    String(amt.amount),
    ...(amt.highlight ? [
      h(`i.fa.fa-${amt.highlight}`, { style: { lineHeight: '.85em', marginLeft: '3px' } })
    ] : [])
  ]
}