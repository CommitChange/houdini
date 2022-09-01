import last from 'lodash/last';
import isEqual from 'lodash/isEqual'
import { DonationResult } from '.';



export type EventObjects = {
  type: 'beginSubmit' |'savedCard' | 'completed'
} | {
  type: 'errored', error:string
} | {
  type: 'completed',
  result: DonationResult,
};



export default class DonationSubmitterEvents  {

  private events:Array<EventObjects> = []
  
  push(event: EventObjects): EventObjects | undefined {
    if (!this.top) {
      this.events.push(event)
      return event;
    }
    else if (!isEqual(this.top, event)) {
      this.events.push(event);
      return event;
    }
    return undefined;
  }

  get top(): EventObjects | undefined {
    return last(this.events);
  }


}