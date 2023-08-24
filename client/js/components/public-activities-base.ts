// License: LGPL-3.0-or-later
/** This file is the beginning of a migration of code from public-activities.js to ts */

import moment from "moment";

/**
 * As described in QueryDonations.for_campaign_activities
 */
interface CampaignPageActivity {
  supporter_name:string
  amount: string
  recurring: boolean
  date: string
}

export function ago(date: moment.MomentInput) {
  return moment(date).fromNow();
}

export function formatRecurring(o: { recurring: boolean  }) {
  return o.recurring
    ? `made a recurring contribution of`
    : `contributed`;
}



// export function formatCampaign(r:{
//   body: {
//     supporter_name: string,
//     date: moment.MomentInput,
//     amount: number,
//     recurring?: boolean | undefined | null; 
//   }[]

// }) {
//   return r.body.map(o => (
//     {
//       name: o.supporter_name 
//     , action: formatRecurring(o) + ' ' + o.amount
//     , date: ago(o.date)
//     }
//   ))
// }