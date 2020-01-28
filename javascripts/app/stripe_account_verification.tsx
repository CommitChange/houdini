// License: LGPL-3.0-or-later
// require a root component here. This will be treated as the root of a webpack package
import Root from "../src/components/common/Root"
import StripeAccountVerification from "../src/components/stripe_account_verification/StripeAccountVerification"

import * as ReactDOM from 'react-dom'
import * as React from 'react'

function LoadReactPage(element:HTMLElement, nonprofit_id:number) {
  ReactDOM.render(<Root><StripeAccountVerification nonprofit_id={nonprofit_id}/></Root>, element)
}


(window as any).LoadReactPage = LoadReactPage