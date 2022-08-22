// License: LGPL-3.0-or-later
import 'whatwg-fetch';

// we add CSRF to the window type
const windowWithCSRF: Window & {_csrf:string} = window as any;



function HasAPostDonationError(obj:any) : obj is PostDonationErrorResult {
  return obj.hasOwnProperty('error');
}


interface PostCampaignGift {
  donation_id:number
  campaign_gift_option_id?:number
}

interface PostCampaignGiftResult {
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

interface PostDonationResult {
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

async function postDonation(donation:DonationType) : Promise<PostDonationResult> {


  const url = `/nonprofits/${donation.nonprofit_id}/donations`;


    const response = await fetch(url, {
      method: 'POST',
      body: JSON.stringify(donation),
      headers:new Headers({
        'Content-Type': 'application/json',
        'X-CSRF-Token': windowWithCSRF._csrf
      }),
      credentials: 'include'
    })

    if (response.ok && 
      response.status >= 200 && 
      response.status < 300)
      {
        const json = await response.json<PostDonationErrorResult|PostDonationResult>();
        if (HasAPostDonationError(json))
        {
          throw new PostDonationError(json.error.toString(), json.error);
        }

        return json;
      }
    else {
      const json = await response.json<PostDonationErrorResult|PostDonationResult>();
      if (HasAPostDonationError(json))
      {
        throw new PostDonationError(json.error.toString(), json.error);
      }
      else {
        throw new PostDonationError('Response was invalid', 'Response was invalid');
      }
      
    }
}

async function postRecurringDonation(props:PostRecurringDonationProps) : Promise<PostRecurringDonationResult> {
  const url = `/nonprofits/${props.recurring_donation.nonprofit_id}/recurring_donations`;


  const response = await fetch(url, {
    method: 'POST',
    body: JSON.stringify(props),
    headers:new Headers({
      'Content-Type': 'application/json',
      'X-CSRF-Token': windowWithCSRF._csrf
    }),
    credentials: 'include'
  })

  if (response.ok && 
    response.status >= 200 && 
    response.status < 300)
    {
      const json = await response.json<PostDonationErrorResult|PostRecurringDonationResult>();
      if (HasAPostDonationError(json))
      {
        throw new PostDonationError(json.error.toString(), json.error);
      }

      return json;
    }
    else {
      const json = await response.json<PostDonationErrorResult|PostDonationResult>();
      if (HasAPostDonationError(json))
      {
        throw new PostDonationError(json.error.toString(), json.error);
      }
      else {
        throw new PostDonationError('Response was invalid', 'Response was invalid');
      }
      
    }
}

async function postCampaignGift(campaign_gift:PostCampaignGift):Promise<void> {
  const url = `/campaign_gifts`;
  if (campaign_gift.campaign_gift_option_id) {

    try {
      await fetch(url, {
        method: 'POST',
        body: JSON.stringify({campaign_gift}),
        headers:new Headers({
          'Content-Type': 'application/json',
          'X-CSRF-Token': windowWithCSRF._csrf
        }),
        credentials: 'include'
      });
    }
    catch(_e) {
      // ignore error
    }
  }
}

interface PostReportSuccessProps {
  donationResult: PostRecurringDonationResult|PostDonationResult;
  plausible?: any;
}

function postReportSuccess(props:PostReportSuccessProps):void {
  if (props.plausible) {
    const resp = props.donationResult;
    props.plausible('payment_succeeded', {props: {amount: resp && resp.charge && resp.charge.amount && (resp.charge.amount / 100)}});
  }
}


interface Props {
  donation: DonationType;
  campaign_gift_option_id?:number;
  plausible?: any;
}

export default async function PostCharge({donation, campaign_gift_option_id, plausible}:Props) : Promise<PostDonationResult|PostRecurringDonationResult|null> {

  const result = donation.recurring ? 
    await postRecurringDonation({recurring_donation: donation}) :
    await postDonation(donation)

  await postCampaignGift({donation_id: result.donation.id, campaign_gift_option_id})
  postReportSuccess({plausible, donationResult:result});

  return result;
}