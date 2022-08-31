// License: LGPL-3.0-or-later

import { first } from "lodash";
import DonationSubmitterEvents from "./DonationSubmitterEvents";

type DonationSubmitterState = 'ready'|'running'| 'cardsaved'|'completed'

export type EventTypes = 'beginSubmit' | 'savedCard' | 'errored';

type Events = {
  type: 'beginSubmit' |'savedCard' | 'completed'
} | {
  type: 'errored', error:string
};

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

  public completed(): void {
    if (this.events.push({type: 'completed'})) {
      this.dispatchEvent(new Event('updated'));
    }
  }


  addEventListener(type: string, listener: EventListenerOrEventListenerObject, options?: boolean | AddEventListenerOptions): void {
    this.eventTarget.addEventListener(type, listener, options);
  }
  dispatchEvent(event: Event): boolean {
    return this.eventTarget.dispatchEvent(event);
  }
  removeEventListener(type: string, callback: EventListenerOrEventListenerObject, options?: boolean | EventListenerOptions): void {
    this.eventTarget.removeEventListener(type, callback, options);
  }
}