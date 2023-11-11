// License: LGPL-3.0-or-later
import {formatFormData} from "."

describe('formatFormData', () => {

  const generalInput = {
    name: 'Penelope',
    email: 'penelope@yorkie.zone'
  }

  it('keeps everything identical when no custom fields are included', () => {
    expect(formatFormData(generalInput)).toStrictEqual(
      {supporter: generalInput})
  });

  it('turns customFields into an array', () => {
    expect(formatFormData({...generalInput, customFields: {
      'furriness': 'very_high',
      'bark': 'very_loud'
    }})).toStrictEqual(
      {
        supporter: {
          ...generalInput, 
          customFields: [
            ['furriness', 'very_high'],
            ['bark', 'very_loud']
          ]
        }
      }
      );
  })
});