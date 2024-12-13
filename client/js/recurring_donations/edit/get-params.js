// License: LGPL-3.0-or-later

const splitParam = str => str.split(/[_;,]/)

module.exports = params => {
  const defaultAmts = '10,25,50,100,250,500,1000'

  const amounts = params.customAmounts instanceof String
      ? params.customAmounts
      : params.customAmounts.map((x) => x / 100).join(',') || defaultAmts;

  return {
    ...params,
    multiple_designations: splitParam(params.multiple_designations),
    custom_amounts: splitParam(amounts).map(Number),
    custom_fields: params.custom_fields.split(',').map((f) => {
      const [name, label] = f.split(':').map((s) => s.trim());
      return { name, label: label ? label : name };
    }),
  };
}
