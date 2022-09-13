// License: LGPL-3.0-or-later
import { PostCampaignGift, windowWithCSRF } from "./types";

export async function postCampaignGift(campaign_gift: PostCampaignGift): Promise<void> {

  if (campaign_gift.campaign_gift_option_id) {

    try {
      await post({ donation_id: campaign_gift.result.donation.id, campaing_gift_option_id: campaign_gift.campaign_gift_option_id });
    }
    catch (_e) {
      // ignore error
    }
  }
}

async function post(campaign_gift: {donation_id: number, campaing_gift_option_id:number}): Promise<void> {
  const url = `/campaign_gifts`;
  await commonFetch(url, { campaign_gift });
}

function commonFetch(url: string, props: any): Promise<Response> {
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
