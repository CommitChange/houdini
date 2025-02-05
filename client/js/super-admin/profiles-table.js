// License: LGPL-3.0-or-later
const h = require('flimflam/h')
const searchTable = require('../components/search-table')
const request = require('../common/client')

const link = (href, text) => h('p.m-0', [ h('a', {props: {href, target: '_blank'}}, text)])

const header = [
  h('tr', [
    h('th.pl-0', 'ID')
    , h('th.pl-0', 'Name')
    , h('th.pl-0', 'First Name')
    , h('th.pl-0', 'Last Name')
    , h('th.pl-0', 'City')
    , h('th.pl-0', 'Email')
    , h('th.pl-0', 'Phone')
    , h('th.pl-0', 'Updated At')
    , h('th.pl-0', 'Created At')
    , h('th.pl-0', '')
  ])
]

const row = (data={}, i) => {
  const sendUserConfirmation = (user_id) => {
    request.get(`/admin/resend_user_confirmation`)
      .query({ profile_id: data.id })
      .end((err, result) => {
        if (err) {
          window.alert(`Uh oh, we have a bug! Error is in browser console (Ctrl-Shift-i) and listed next: ${err}`)
          console.error(err)
        } else {
          window.alert("Confirmation sent!")
        }
      });
    };

  const name = data.name ? data.name : 'No name'
  return h('tr.sub', [
    h('td.pl-0', h('p.m-0', '#' + data.id))
    , h('td.pl-0', h('h5.m-0.max-width-1', [link(`/profiles/${data.id}/`, name)]))
    , h('td.pl-0', data.first_name ? h('p.m-0', data.first_name) : '')
    , h('td.pl-0', data.last_name ? h('p.m-0', data.last_name) : '')
    , h('td.pl-0', data.city ? h('p.m-0', data.city) : '')
    , h('td.pl-0', data.email ? h('p.m-0', data.email) : '')
    , h('td.pl-0', data.phone ? h('p.m-0', data.phone) : '')
    , h('td.pl-0', data.updated_at)
    , h('td.pl-0', data.created_at)
    , h('td.pl-0', [
      , h('p.m-0', { class: {
          'color-green' :  data.is_confirmed
        , 'color-red' : !data.is_confirmed
        , 'underline' : !data.is_confirmed }}
        , data.is_confirmed ? 'confirmed' : [h('a', {on: {click: () => { sendUserConfirmation(data.id) }}}, 'unconfirmed')])
    ])
  ])
}

module.exports = state => searchTable(state, header, row, 'Search profiles')
