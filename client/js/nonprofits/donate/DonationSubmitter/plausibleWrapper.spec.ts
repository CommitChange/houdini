// License: LGPL-3.0-or-later
import {paymentSucceededPlausible} from './plausibleWrapper';


describe('plausibleWrapper', () => {
  describe('paymentSucceededPlausible', () => {
    it('completes if getPlausible is undefined', () => {
      expect(() => paymentSucceededPlausible({})).not.toThrow();
    })

    it('completes if getPlausible is returns undefined', () => {
      expect(() => paymentSucceededPlausible({getPlausible: () => undefined})).not.toThrow();
    })

    describe('completes if getPlausible is defined but result is', () => {
      it('undefined', () => {
        const realPlausibleFunc = jest.fn();
        expect(() => paymentSucceededPlausible({getPlausible: () => realPlausibleFunc})).not.toThrow();

        expect(realPlausibleFunc).toHaveBeenCalledWith('payment_succeeded', {
          props: {
            amount: undefined,
          }});

      })

      it('exists but doesnt have a charge', () => {
        const realPlausibleFunc = jest.fn();
        expect(() => paymentSucceededPlausible({getPlausible: () => realPlausibleFunc, result:{}})).not.toThrow();

        expect(realPlausibleFunc).toHaveBeenCalledWith('payment_succeeded', {
          props: {
            amount: undefined,
          }});
          
      });
      
      it('exists but doesnt have an amount', () => {
        const realPlausibleFunc = jest.fn();
        expect(() => paymentSucceededPlausible({getPlausible: () => realPlausibleFunc, result:{charge:{}}})).not.toThrow();

        expect(realPlausibleFunc).toHaveBeenCalledWith('payment_succeeded', {
          props: {
            amount: undefined,
          }});
          
      });
      
      it('exists and has an amount', () => {
        const realPlausibleFunc = jest.fn();
        expect(() => paymentSucceededPlausible({getPlausible: () => realPlausibleFunc, result:{charge:{amount: 1000}}})).not.toThrow();

        expect(realPlausibleFunc).toHaveBeenCalledWith('payment_succeeded', {
          props: {
            amount: 10,
          }});
          
      })
    })
  })
});