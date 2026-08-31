// License: LGPL-3.0-or-later

type StateEventTypes =  'update'

type PaymentField = Record<string, string>

export default class DonationInfoCollector implements EventTarget {
  
  private _paymentFields:PaymentField[] = []
  private eventTarget = new EventTarget();

  get paymentFields() : PaymentField[] {
    return this._paymentFields;
  }

  set paymentFields(fields:PaymentField[]) {
    this._paymentFields = fields;
  }

  addEventListener(type: StateEventTypes, listener: EventListenerOrEventListenerObject, options?: boolean | AddEventListenerOptions): void {
    this.eventTarget.addEventListener(type, listener, options);
  }
  dispatchEvent(event: Event): boolean {
    return this.eventTarget.dispatchEvent(event);
  }
  removeEventListener(type: StateEventTypes, callback: EventListenerOrEventListenerObject, options?: boolean | EventListenerOptions): void {
    this.eventTarget.removeEventListener(type, callback, options);
  }

  reportUpdated:() => void = () => {
    this.dispatchEvent(new Event('updated'));
  }
}