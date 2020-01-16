// License: LGPL-3.0-or-later
// require a root component here. This will be treated as the root of a webpack package
import Root from "../src/components/common/Root"
import StripeVerificationConfirm from "../src/components/stripe_verification_confirm/StripeVerificationConfirm"

import * as ReactDOM from 'react-dom'
import * as React from 'react'

function LoadReactPage(element:HTMLElement, nonprofit_id:number) {
  ReactDOM.render(<Root><StripeVerificationConfirm nonprofit_id={nonprofit_id}/></Root>, element)
}


(window as any).LoadReactPage = LoadReactPage