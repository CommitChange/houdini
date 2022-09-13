// License: LGPL-3.0-or-later

import {GetPlausible, paymentSucceededPlausible} from './plausibleWrapper';
import { postCampaignGift } from './postCampaignGift';

import StateManager  from "./StateManager";
import { PostDonationResult } from './types';
type DonationResult = PostDonationResult

export type EventObjects = {
  type: 'beginSubmit' |'savedCard' | 'completed'
} | {
  type: 'errored', error:string
} | {
  type: 'completed',
  result: DonationResult,
};

interface DonationSubmitterProps {
  getPlausible?:GetPlausible,
  campaign_gift_option_id?:number;
}

export default class DonationSubmitter implements EventTarget {

  
  private stateManager = new StateManager();

  private eventTarget = new EventTarget();

  constructor(private readonly props:DonationSubmitterProps) {

    Object.bind(this, this.handleBeginSubmit);
    Object.bind(this, this.handleSavedCard);
    Object.bind(this, this.handleErrored);
    Object.bind(this, this.handleCompleted);
    Object.bind(this, this.postCampaignGift);

    this.stateManager.addEventListener('beginSubmit', (evt:Event) => this.handleBeginSubmit(evt));
    this.stateManager.addEventListener('savedCard', (evt:Event) => this.handleSavedCard(evt));
    this.stateManager.addEventListener('errored', (evt:Event) => this.handleErrored(evt));

    this.stateManager.addEventListener('completed', (evt:Event) => this.handleCompleted(evt));

  }


  get loading(): boolean {
    return this.stateManager.loading;
  }

  get error():string|undefined {
    return this.stateManager.error;
  }

  get progress(): number|undefined {
    return this.stateManager.progress;
  }

  get completed(): boolean {
    return this.stateManager.completed;
  }

  get result(): DonationResult|undefined {
    return this.stateManager.result;
  }

  private async postSuccess():Promise<void> {
    await this.postCampaignGift();
    try {
     paymentSucceededPlausible({getPlausible: this.props.getPlausible, result: this.result});
    }
    catch(e) {
      console.error(e)
    }
  }

  private async postCampaignGift():Promise<void> {
    try {
      await postCampaignGift({result: this.result, 
        campaign_gift_option_id: this.props.campaign_gift_option_id
      })
    }
    catch (_e){
      //...ignore!
    }
  }

  public reportBeginSubmit():void {
    this.stateManager.reportBeginSubmit();
  }

  public reportError(error:string):void {
    this.stateManager.reportError(error);
  }

  public reportSavedCard(): void {
    this.stateManager.reportSavedCard();
  }

  public reportCompleted(result:DonationResult): void {
    this.stateManager.reportCompleted(result);
  }

  addEventListener(type: 'updated', listener: EventListenerOrEventListenerObject, options?: boolean | AddEventListenerOptions): void {
    this.eventTarget.addEventListener(type, listener, options);
  }
  dispatchEvent(event: Event): boolean {
    return this.eventTarget.dispatchEvent(event);
  }
  removeEventListener(type: 'updated', callback: EventListenerOrEventListenerObject, options?: boolean | EventListenerOptions): void {
    this.eventTarget.removeEventListener(type, callback, options);
  }

  private async handleCompleted(_evt: Event):Promise<void> {
    try {
      await this.postSuccess();
    }
    finally {
      this.dispatchEvent(new Event('updated'));
    }
    
    
  }
  
  private handleErrored(evt: Event) {
    this.dispatchEvent(new Event('updated'));
  }
  
  private handleSavedCard(evt: Event) {
    this.dispatchEvent(new Event('updated'));
  }
  
  private handleBeginSubmit(evt: Event) {
    this.dispatchEvent(new Event('updated'));
  }
}