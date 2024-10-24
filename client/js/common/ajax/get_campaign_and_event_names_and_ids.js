// License: LGPL-3.0-or-later
const request = require('../client')

module.exports = function(npo_id) {
  const campaignsPath = '/nonprofits/' + npo_id + '/campaigns/name_and_id'
  const eventsPath = '/nonprofits/' + npo_id + '/events/name_and_id'

  request.get(campaignsPath).end(function(err, resp){
    var dataResponse = []

    if (!err) {
      resp.body.unshift(false)
      dataResponse = resp.body.map((i) => {
        if (i.isChildCampaign)
        {
          return {id: i.id, name: i.name + " - " + i.creator}
        }
        else
        {
          return {id: i.id, name: i.name}
        }
      })
    }
    appl.def('campaigns.data', dataResponse)
  })

  request.get(eventsPath).end(function(err, resp){
    let dataResponse = []
    if(!err) {
      resp.body.unshift(false)
      dataResponse = resp.body
    }

    appl.def('events.data', dataResponse)
  })
}
