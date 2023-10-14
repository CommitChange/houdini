// License: LGPL-3.0-or-later
const getParams = require('./get-params');
const {getDefaultAmounts} = require('./custom_amounts');

describe('.getParams', () => {
  describe('custom_amounts:', () => {
    it('gives custom_amounts defaults if not passed in', () => {
      expect(getParams({})).toHaveProperty('custom_amounts', getDefaultAmounts());
    });

    it('accepts integers', () => {
      expect(getParams({custom_amounts: '3'})).toHaveProperty('custom_amounts', [3]);
    });

    it('accepts floats', () => {
      expect(getParams({custom_amounts: '3.5'})).toHaveProperty('custom_amounts', [3.5]);
    });

    it('splits properly', () => {
      expect(getParams({custom_amounts: '3.5,  600\n;400;3'})).toHaveProperty('custom_amounts', [3.5, 600, 400, 3]);
    });
    
  });

  describe.skip('custom_fields:', () => {

  });

  describe.skip('multiple_designations:', () => {

  });

  describe('tags:', () => {
    it('keeps tags empty if not passed in', () => {
      expect(getParams({})).not.toHaveProperty('tags')
    });

    it('when one tag passed it is in an array by itself', () => {
      expect(getParams({tags: 'A tag name'})).toHaveProperty('tags', ['A tag name']);
    });

    it('when a tag has a leading or trailing whitespace, it is stripped',() => {
      expect(getParams({tags: '   \tA tag name\n'})).toHaveProperty('tags', ['A tag name']);
    });
  });
});