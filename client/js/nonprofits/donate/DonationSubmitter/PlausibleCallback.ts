import { Callback } from "../../../../../app/javascript/common/Callbacks";
import DonationSubmitter from './';

// License: LGPL-3.0-or-later
export interface PlausibleFunction {
  (eventType: string, val: any): void
}

export interface GetPlausible {

  (): PlausibleFunction | undefined
}


export default class PlausibleCallback extends Callback<DonationSubmitter> {

  private get plausibleFunction(): PlausibleFunction {
    return this.props.props.getPlausible()
  }
  canRun(): boolean {
    return !!(this.props.props.getPlausible &&  this.props.props.getPlausible())
  }

  run(): void {
    this.plausibleFunction('payment_succeeded', {
      props: {
        amount: this.props.result?.charge?.amount && (this.props.result.charge.amount / 100)
      }
    });
  }

  catchError(e: unknown): void {
    console.log(e);
  }

}