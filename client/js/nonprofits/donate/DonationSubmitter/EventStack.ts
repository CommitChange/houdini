// License: LGPL-3.0-or-later
import last from 'lodash/last';
import isEqual from 'lodash/isEqual'


export default class EventStack<TEventObjects extends {type:string}> {

  private events:Array<TEventObjects> = []
  
  push(event: TEventObjects): TEventObjects | undefined {
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

  get top(): TEventObjects | undefined {
    return last(this.events);
  }


}