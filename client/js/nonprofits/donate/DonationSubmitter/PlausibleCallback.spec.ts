// License: LGPL-3.0-or-later
import PlausibleCallback from './PlausibleCallback';


describe('PlausibleCallback', () => {
  describe('.canRun', () => {
    it('false when getPlausible is undefined', () => {
      const c = new PlausibleCallback({ props: {}} as any);
      expect(c.canRun()).toEqual(false)
    })

    it('false when getPlausible returns undefined', () => {
      const c = new PlausibleCallback({ props: {getPlausible: ():any => undefined}} as any);
      expect(c.canRun()).toEqual(false)
    })

    it('true when returns plausible function', () => {
      const realPlausibleFunc = jest.fn();
      const c = new PlausibleCallback({ props: {getPlausible: ():any => realPlausibleFunc}} as any);
      expect(c.canRun()).toEqual(true);
    })
  })

  describe('.run', () => {
    function build(result?:{charge?:{amount?:number}}) {
      const realPlausibleFunc = jest.fn();
      return {
        plausible: realPlausibleFunc,
        obj: new PlausibleCallback({ props: {getPlausible: ():any => realPlausibleFunc}, result}  as any)
      };

    }

    it('calls plausible with no amount when result is undefined', async () => {
      const {plausible, obj} = build();
      await obj.run();
      expect(plausible).toHaveBeenCalledWith('payment_succeeded', {
        props: {
          amount: undefined,
        }
      });
    })

    it('calls plausible with no amount when charge is undefined', async () => {
      const {plausible, obj} = build({});
      await obj.run();
      expect(plausible).toHaveBeenCalledWith('payment_succeeded', {
        props: {
          amount: undefined,
        }
      });
    })

    it('calls plausible with no amount when charge.amount is undefined', async () => {
      const {plausible, obj} = build({charge:{}});
      await obj.run();
      expect(plausible).toHaveBeenCalledWith('payment_succeeded', {
        props: {
          amount: undefined,
        }
      });
    })

    it('calls plausible with amount/100 when charge.amount is defined', async () => {
      const {plausible, obj} = build({charge:{amount: 1000}});
      await obj.run();
      expect(plausible).toHaveBeenCalledWith('payment_succeeded', {
        props: {
          amount: 10,
        }
      });
    })
  });

  describe('.catchError', () => {
    it('does not rethrow errors', () => {
      const c = new PlausibleCallback({} as any);
      expect(() => c.catchError(new Error())).not.toThrow();
    })
  })
});