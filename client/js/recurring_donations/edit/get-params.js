// License: LGPL-3.0-or-later
const R = require('ramda')

const splitParam = str => str.split(/[_;,]/)

module.exports = params => {
  const defaultAmts = '10,25,50,100,250,500,1000'
  // Set defaults
  const merge = R.merge({
    custom_amounts: ''
  })
  // Preprocess data
  const evolve = R.evolve({
    multiple_designations: splitParam
  , custom_amounts: amts => R.compose(R.map(Number), splitParam)((amts instanceof String ? amts : R.map(x => x/100, amts).join(',')) || defaultAmts)
  , custom_fields: fields => R.map(f => {
      const [name, label] = f.split(':').map(R.trim);
      return {name, label: label ? label : name}
    }, fields.split(','))
  })
  return evolve(merge(params))
}
