import last from 'lodash/last';
import isEqual from 'lodash/isEqual'



export type Events = {
  type: 'beginSubmit' |'savedCard' | 'completed'
} | {
  type: 'errored', error:string
};



export default class DonationSubmitterEvents  {

  private events:Array<Events> = []
  
  push(event: Events): Events | undefined {
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

  get top(): Events | undefined {
    return last(this.events);
  }


}