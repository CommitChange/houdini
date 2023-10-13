// License: LGPL-3.0-or-later
import customFields from "."

describe('customFields', () => { 
  it('sets the the field correctly', () => {
    expect(customFields([
      {name: "Name of Field", label: "Field Label", type: 'supporter'},
      {name: "Another Field Name", label: "Label2", type: 'supporter'}
    ])).toMatchSnapshot();
  });

  it('returns blank string correctly with nothing passed', () => {
    expect(customFields()).toBe("");
  });

  it('returns blank string correctly with null passed', () => {
    expect(customFields(null)).toBe("");
  });
  
});