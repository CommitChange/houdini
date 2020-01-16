// License: LGPL-3.0-or-later
import * as React from 'react';
import ApiManager from './ApiManager';
import AccountLinkManager from './AccountLinkManager'
import InnerStripeAccountVerification from './InnerStripeAccountVerification';



export interface StripeAccountVerificationProps {
  nonprofit_id: number
  dashboard_link:string
}


export default function StripeAccountVerification(props:StripeAccountVerificationProps) {
  return <ApiManager>
    <AccountLinkManager nonprofitId={props.nonprofit_id}>
      <InnerStripeAccountVerification dashboardLink={props.dashboard_link} />
    </AccountLinkManager>
  </ApiManager>
}



