// License: LGPL-3.0-or-later
export default class DonationSubmitter implements EventTarget {

  private _loading:boolean = false;
  private _error:string|undefined = undefined;
  private eventTarget = new EventTarget();

  get loading(): boolean {
    return !this._error && this._loading;
  }
  
  set loading(val:boolean) {
    if (this._loading !== val) {
      this._loading = val;
      this.dispatchEvent(new Event('updated'));
    }
  }

  get error():string|undefined {
    return this._error;
  }

  set error(val:string|undefined) {
    if (this._error !== val) {
      this._error = val;
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