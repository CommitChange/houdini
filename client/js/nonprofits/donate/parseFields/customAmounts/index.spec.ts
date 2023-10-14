// License: LGPL-3.0-or-later
import parseCustomAmounts from '.';

describe('.parseCustomAmounts', () => {
  it('when no numbers exist you get an empty array', () => {
    expect(parseCustomAmounts('fendwaofnocinwet')).toBeEmpty();
  });
  
  it('when an empty string, you get an empty array', () => {
    expect(parseCustomAmounts('fendwaofnocinwet')).toBeEmpty();
  });

  it('spaces dont matter', () => {
    expect(parseCustomAmounts(' 3, 45')).toStrictEqual([3, 45])
  });

  it('handles floats correctly', () => {
    expect(parseCustomAmounts(' 5.5, 45')).toStrictEqual([5.5, 45])
  });
});