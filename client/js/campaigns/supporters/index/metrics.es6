// License: LGPL-3.0-or-later
const h = require('virtual-dom/h')
const thunk = require('vdom-thunk')

const root = state => {
	if(!state || !state.get('data')) return h('span')
	return h('table.table--plaid', [
		h('thead', [
			h('tr', [h('th', 'Gift option'), h('th', 'Count'), h('th', 'One time'), h('th', 'Recurring')]),
		]),
		h('tbody', state.get('data').map(gift => thunk(giftRow, gift)).toJS())
	])
}

const giftRow = gift => {
	
  var name = gift.get('name')
	name = !name || !name.length ? 'No Gift Option Chosen' : name
	return h('tr', [
		h('td', h('strong', name)),
		h('td', (gift.get('total_donations') || 0) + ''),
		h('td', '$' + utils.cents_to_dollars(gift.get('total_one_time'))),
		h('td', '$' + utils.cents_to_dollars(gift.get('total_recurring')))
	])
}

module.exports = { root: root, $streams: $ }
