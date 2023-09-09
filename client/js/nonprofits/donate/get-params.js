// License: LGPL-3.0-or-later
const {evolve: Revolve, merge: Rmerge, split: Rsplit, compose: Rcompose, map: Rmap, split: Rsplit} = require('ramda')
const {getDefaultAmounts} = require('./custom_amounts');
const { parseCustomFields, splitParam }  = require('./parseFields');

module.exports = params => {
  const defaultAmts = getDefaultAmounts().join()
  // Set defaults
  const merge = Rmerge({
    custom_amounts: ''
  })
  // Preprocess data
  const evolve = Revolve({
    multiple_designations: splitParam
  , custom_amounts: amts => Rcompose(Rmap(Number), splitParam)(amts || defaultAmts)
  , custom_fields: parseCustomFields
  , tags: tags => Rmap(tag => {
      return tag.trim()
    }, Rsplit(',', tags))
  })

  const outputParams = Rcompose(evolve, merge)(params)
  if (window.app && window.app.widget && window.app.widget.custom_amounts) {
    outputParams.custom_amounts = window.app.widget.custom_amounts
  }
  return outputParams;
}
