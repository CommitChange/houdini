// License: LGPL-3.0-or-later
import DonationSubmitterEvents from "./DonationSubmitterEvents";

export type EventTypes = 'beginSubmit' | 'savedCard' | 'errored';

type WindowWithPlausible = Window & {plausible?:(eventType:string, val:any)  => void};

const winWithPlausible = window as unknown as WindowWithPlausible;

export type DonationResult = {charge?: {amount?:number}}

export default class DonationSubmitter implements EventTarget {

  
  private events = new DonationSubmitterEvents();

  private eventTarget = new EventTarget();


  get loading(): boolean {
    const lastEvent = this.events.top;
    return lastEvent && (lastEvent.type === 'beginSubmit' || lastEvent.type === 'savedCard');
  }

  get error():string|undefined {
    const lastEvent = this.events.top;
    if (lastEvent && lastEvent.type === 'errored') {
      return lastEvent.error;
    }
    return undefined;
  }

  get progress(): number|undefined {
    const lastEvent = this.events.top;
    if (lastEvent.type === 'beginSubmit') {
      return 20;
    }
    else if (lastEvent.type === 'savedCard') {
      return 100;
    }
    else {
      return undefined;
    }
  }

  private postSuccess(resp?:DonationResult):void {
    const plausible = winWithPlausible.plausible;
    try {
      if (plausible) {
        plausible('payment_succeeded', {
            props: {
              amount: resp?.charge?.amount && (resp.charge.amount / 100)
            }
          }
        );
      }
    }
    catch(e) {
      console.error(e)
    }
  }

  public beginSubmit():void {
    if (this.events.push({type: 'beginSubmit'})) {
      this.dispatchEvent(new Event('updated'));
    };
  }

  public reportError(error:string):void {
    if (this.events.push({type: 'errored', error})) {
      this.dispatchEvent(new Event('updated'));
    }
  }

  public savedCard(): void {
    if (this.events.push({type: 'savedCard'})) {
      this.dispatchEvent(new Event('updated'));
    }
  }

  public completed(result:DonationResult): void {
    if (this.events.push({type: 'completed', result})) {
      this.dispatchEvent(new Event('updated'));

      this.postSuccess(result);
    }
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
}