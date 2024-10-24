// License: LGPL-3.0-or-later
// Include the cards/fields partial to use with this.
// Call appl.card_form.create(card_obj) to start the card creation process.
// Use the appl.card_form.on_fail callback to handle failures.
// Use the appl.card_form.on_complete callback to handle completion.
// This does not create any donations -- do the donation creation inside appl.card_form.on_complete.

// Not namespacing card_form; only show one card form on the page at any time

const request = require('../common/super-agent-promise')
const format_err = require('../common/format_response_error')
const grecaptcha_during_payment = require('../../../javascripts/src/lib/grecaptcha_during_payment').default

module.exports = create_card

// UI state defaults
appl.def('card_form', {
	loading: false,
	error: false,
	status: '',
	on_complete: function() {},
	on_fail: function() {},
	progress_width: '0%' // Width of the progress bar
})

// Define some status messages and progress bar widths for each step of the process
var statuses = {
	before_tokenization: {
		progress_width: '20%',
		status: 'Double-checking your card...'
	},
	before_create: {
		progress_width: '75%',
		status: 'Looks good! Sending the carrier pigeons...'
	},
	on_complete: {
			progress_width: '100%',
			status: 'Processing payment...'
	}
}

// Tokenize with stripe, then save to our db.
// The first argument must be a holder object that has 'type' and 'id' keys.
// eg: {holder: {type: 'Nonprofit', id: 1}}
// This is the a Card object from Stripe v3
function create_card(holder, card_obj, cardholderName, postalCode, options ) {
  options = options || {}
	if(appl.card_form.loading) return
	appl.def('card_form', { loading: true, error: false })
	appl.def('card_form', statuses.before_tokenization)

  // // Delete the cvc key from card_obj if
  // // the value of cvc is a blank string.
  // // Otherwise, Stripe will return an error for
  // // incorrect security code.
  // if(card_obj.cvc === '') {
  //   delete card_obj['cvc']
  // }

	// First, tokenize the card with Stripe.js
	return tokenize_with_stripe(window[card_obj], cardholderName, postalCode)
		.catch(display_stripe_err)
		// Then, save a Card record in our db
		.then(function(stripe_resp) {
			appl.def('card_form', statuses.before_create)
			return stripe_resp
		})
		.then(grecaptcha_during_payment)
		.catch(display_grecaptcha_err)
		.then(function(args) {
			return create_record(holder, args.stripe_resp, args.recaptcha_token, options)
		})
		.then(function(resp) {
			appl.def('card_form', statuses.on_complete)
			return resp.body
		})
		.catch(display_err)
}

// Post to stripe to get back a stripe_card_token
function tokenize_with_stripe(card_obj, cardholderName, postalCode) {
	return new Promise(function(resolve, reject) {
		stripeV3.createToken(card_obj, {name:cardholderName, address_zip: postalCode}).then( function(resp) {
			if(resp.error) reject(resp)
			else resolve(resp.token)
		})
	})
}

// Save a record of the card in our own db
function create_record(holder, stripe_resp, recaptcha_token, options={}) {
	var output = {card: {
            holder_type: holder.type,
            holder_id: holder.id,
            email: holder.email,
            cardholders_name: stripe_resp.name,
            name: stripe_resp.card.brand + ' *' + stripe_resp.card.last4,
            stripe_card_token: stripe_resp.id,
            stripe_card_id: stripe_resp.card.id
		}}
	
	if (recaptcha_token){
		output['g-recaptcha-response']= recaptcha_token
	}
	if (options['event_id'])
	{
		output['event_id'] = options['event_id']
	}

	return request.post(options.path || '/cards')
		.send(output)
		.perform()
}

// Set UI state to display an error in the card form.
function display_err(resp) {
  if(resp && resp.error) {
    appl.def('card_form', {
      loading: false,
      error: true,
      status: format_err(resp),
      progress_width: '0%'
    })
    appl.def('loading', false)
  }
}

function display_stripe_err(resp) {
  if(resp && resp.error) {
    appl.def('card_form', {
      loading: false,
      error: true,
      status: resp.error.message,
      progress_width: '0%'
    })
		appl.def('loading', false)
		
		throw new Error()
  }
}

function display_grecaptcha_err(resp) {
	if(resp && resp.message) {
	  appl.def('card_form', {
		loading: false,
		error: true,
		status: resp.message,
		progress_width: '0%'
	  })
		  appl.def('loading', false)
		  
		  throw new Error()
	}
  }
