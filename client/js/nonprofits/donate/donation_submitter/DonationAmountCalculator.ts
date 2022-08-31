// License: LGPL-3.0-or-later

import {CommitchangeFeeCoverageCalculator} from '../../../../../javascripts/src/lib/payments/commitchange_fee_coverage_calculator'

interface CalcResult {
  /**
   * The actual amount which should be charged. If fee coverage is included, this will include that amount
   */
  donationTotal:number,
  /**
   * The amount of fees that need to be added to the raw amount, in order to cover the fees.
   */
  potentialFees:string
}

export default class DonationAmountCalculator implements EventTarget {
 
  private _coverFees: boolean = false;
  private _inputAmount:number = 0;
  private eventTarget = new EventTarget();
  
  constructor(readonly feeStructure:{   flatFee:number; percentageFee:number}) {
  }

  get coverFees() {
    return this._coverFees
  }

  set coverFees(val:boolean) {
    const prev = this._coverFees
    if (prev !== val) {
      this._coverFees = val;
      this.dispatchEvent(new Event('updated'));
    }
  }

  get inputAmount() {
    return this._inputAmount;
  }

  set inputAmount(val:number) {
    if (val !== this._inputAmount) {
      this._inputAmount = val;
      this.dispatchEvent(new Event('updated'));
    }
  }

  get calcResult(): {donationTotal:number, potentialFees:string} {
    const calc  = new CommitchangeFeeCoverageCalculator({
      ...this.feeStructure,
      currency: 'usd',
      feeCovering: this.coverFees
    });

    const calcFromNetResult = calc.calcFromNet(this._inputAmount);

    return {
      donationTotal: calcFromNetResult.actualTotalAsNumber,
      potentialFees: calcFromNetResult.estimatedFees.feeAsString
    }
  }

  addEventListener(type: string, listener: EventListenerOrEventListenerObject, options?: boolean | AddEventListenerOptions): void {
    this.eventTarget.addEventListener(type, listener, options);
  }
  dispatchEvent(evt: Event): boolean {
    return this.eventTarget.dispatchEvent(evt);
  }
  removeEventListener(type: string, listener?: EventListenerOrEventListenerObject, options?: boolean | EventListenerOptions): void {
    this.eventTarget.removeEventListener(type, listener, options);
  }
}