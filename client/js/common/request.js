// License: LGPL-3.0-or-later
const request = require('flyd-ajax')

module.exports = options => {
  options.headers = {
    ...options.headers,
    'Content-Type': 'application/json',
    'X-CSRF-Token': window._csrf,
  }
  return request(options)
}
