import { DonationType, PostDonationResult, PostRecurringDonationResult, PostCampaignGift, PostDonationErrorResult, PostRecurringDonationProps, PostDonationError, windowWithCSRF, HasAPostDonationError } from "./types";
import CompletablePromiseManager from "./CompletablePromiseManager";


interface PostReportSuccessProps {
  donationResult: PostRecurringDonationResult | PostDonationResult;
  plausible?: any;
}



export interface SubmissionProps {
  donation: DonationType;
  campaign_gift_option_id?: number;
  plausible?: any;
}

// License: LGPL-3.0-or-later
export default class DonationSubmitter {
  readonly stateManager: CompletablePromiseManager = new CompletablePromiseManager();


  async Submit({ donation, campaign_gift_option_id, plausible }: SubmissionProps): Promise<PostDonationResult | PostRecurringDonationResult | "running" | "completed"> {

    return this.stateManager.process(async () => {
      let result:PostDonationResult|PostRecurringDonationResult;
      try {
        result = donation.recurring ?
          await this.postRecurringDonation({ recurring_donation: donation }) :
          await this.postDonation(donation)
      }
      catch (e) {
        if (e !instanceof PostDonationError) {
          throw new PostDonationError('Response was invalid', 'Response was invalid');
        }
        else {
          throw e;
        }
      }
      await this.postCampaignGift({ donation_id: result.donation.id, campaign_gift_option_id })
      this.postReportSuccess({ plausible, donationResult: result });
      return result;
    });
    
  }


  private postReportSuccess(props: PostReportSuccessProps): void {
    if (props.plausible) {
      const resp = props.donationResult;
      props.plausible('payment_succeeded', { props: { amount: resp && resp.charge && resp.charge.amount && (resp.charge.amount / 100) } });
    }
  }

  private async postCampaignGift(campaign_gift: PostCampaignGift): Promise<void> {
    const url = `/campaign_gifts`;
    if (campaign_gift.campaign_gift_option_id) {

      try {
        await this.commonFetch(url, { campaign_gift });
      }
      catch (_e) {
        // ignore error
      }
    }
  }


  private async postDonation(donation: DonationType): Promise<PostDonationResult> {


    const url = `/nonprofits/${donation.nonprofit_id}/donations`;


    const response = await this.commonFetch(url, donation);

    if (response.ok &&
      response.status >= 200 &&
      response.status < 300) {
      const json = await response.json<PostDonationErrorResult | PostDonationResult>();
      if (HasAPostDonationError(json)) {
        throw new PostDonationError(json.error.toString(), json.error);
      }

      return json;
    }
    else {
      const json = await response.json<PostDonationErrorResult | PostDonationResult>();
      if (HasAPostDonationError(json)) {
        throw new PostDonationError(json.error.toString(), json.error);
      }
      else {
        throw new PostDonationError('Response was invalid', 'Response was invalid');
      }

    }
  }

  private async postRecurringDonation(props: PostRecurringDonationProps): Promise<PostRecurringDonationResult> {
    const url = `/nonprofits/${props.recurring_donation.nonprofit_id}/recurring_donations`;


    const response = await this.commonFetch(url, props);

    if (response.ok &&
      response.status >= 200 &&
      response.status < 300) {
      const json = await response.json<PostDonationErrorResult | PostRecurringDonationResult>();
      if (HasAPostDonationError(json)) {
        throw new PostDonationError(json.error.toString(), json.error);
      }

      return json;
    }
    else {
      const json = await response.json<PostDonationErrorResult | PostDonationResult>();
      if (HasAPostDonationError(json)) {
        throw new PostDonationError(json.error.toString(), json.error);
      }
      else {
        throw new PostDonationError('Response was invalid', 'Response was invalid');
      }

    }
  }

  
  private commonFetch(url: string, props: any): Promise<Response> {
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
}