// License: LGPL-3.0-or-later
import 'whatwg-fetch';

// we add CSRF to the window type

type WindowAndCsrf = Window & {_csrf:string};
export function windowWithCSRF(): WindowAndCsrf {
  return window as unknown as WindowAndCsrf;
}

/** includes the csrf token automatically */
export function commonFetch(url: string, props: any): Promise<Response> {
  return fetch(url, {
    method: 'POST',
    body: JSON.stringify(props),
    headers: new Headers({
      'Content-Type': 'application/json',
      'X-CSRF-Token': windowWithCSRF()._csrf
    }),
    credentials: 'include'
  });
}

export function HasAPostDonationError(obj:any) : obj is PostDonationErrorResult {
  return obj.hasOwnProperty('error');
}

export interface PostCampaignGift {
  result:PostDonationResult
  campaign_gift_option_id?:number
}

export interface PostCampaignGiftResult {
  id:number
}


interface DonationType  {
  amount:number,
  nonprofit_id:number,
  campaign_id?:number,
  feeCovering?:boolean,
  supporter_id:number
  fee_covered?:boolean
  token: string
  recurring: boolean
}

type PostDonationProps = DonationType

interface PostRecurringDonationProps {
  recurring_donation: DonationType;
}

export interface PostDonationResult {
  charge?:{amount:number}
  payment:any
  donation:{id: number, [fields:string]:any}
  activity: Array<any>
}

interface PostDonationErrorResult {
  error: any;
}

interface PostRecurringDonationResult extends PostDonationResult {
  recurring_donation:any;
}

class PostDonationError extends Error {
  constructor(message:string, readonly error:any){
    super(message);
  }
}



