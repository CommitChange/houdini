// License: LGPL-3.0-or-later
export interface PlausibleFunction {
  (eventType: string, val: any): void
}

export interface GetPlausible {

  (): PlausibleFunction | undefined
}

/**
 * Notifies plausible that the payment has been created
 */
export function paymentSucceededPlausible({ getPlausible, result }: { getPlausible?: GetPlausible, result?: { charge?: { amount?: number } } }) {

  const plausibleFunction = getPlausible && getPlausible();

  if (plausibleFunction) {
    plausibleFunction('payment_succeeded', {
      props: {
        amount: result?.charge?.amount && (result.charge.amount / 100)
      }
    });
  }
}