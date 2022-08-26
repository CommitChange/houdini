// License: LGPL-3.0-or-later



export function windowWithCSRF<T extends Window>(customWindow?: T) : T & {_csrf:string} {
  return customWindow || window as any;
}

export function HasAPostDonationError(obj:any) : obj is PostDonationErrorResult {
  return obj.hasOwnProperty('error');
}


export interface PostCampaignGift {
  donation_id:number
  campaign_gift_option_id?:number
}

export interface PostCampaignGiftResult {
  id:number
}


export interface DonationType  {
  amount:number,
  nonprofit_id:number,
  campaign_id?:number,
  feeCovering?:boolean,
  supporter_id:number
  fee_covered?:boolean
  token: string
  recurring: boolean
}

export interface PostRecurringDonationProps {
  recurring_donation: DonationType;
}

export interface PostDonationResult {
  charge?:{amount:number}
  payment:any
  donation:{id: number, [fields:string]:any}
  activity: Array<any>
}

export interface PostDonationErrorResult {
  error: any;
}

export interface PostRecurringDonationResult extends PostDonationResult {
  recurring_donation:any;
}

export class PostDonationError extends Error {
  constructor(message:string, readonly error:any){
    super(message);
  }
}

