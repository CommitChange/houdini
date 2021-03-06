// License: LGPL-3.0-or-later
const h = require('snabbdom/h')
const R = require('ramda')
const flyd = require('flyd')
flyd.lift = require('flyd/module/lift')
flyd.flatMap = require('flyd/module/flatmap')
const request = require('../../common/request')
const cardForm = require('./card-form.es6')
const format = require('../../common/format')
const progressBar = require('../../components/progress-bar')
const {calculateTotal} = require('../../nonprofits/donate/calculate-total')
const {CommitchangeStripeFeeStructure} = require('../../../../javascripts/src/lib/payments/commitchange_stripe_fee_structure')
const {Money} = require('../../../../javascripts/src/lib/money')
const {centsToDollars} = require('../../common/format')

function init(params$, donation$) {
    var state = { params$: params$, donation$: donation$ }
    state.rdUpdateAmountPath = `/recurring_donations/${app.pageLoadData.recurring_donation.id}/update_amount`
    state.token = utils.get_param('t')

    state.posting = false

    const cardPayload$ = flyd.map(supp => ({card: {holder_id: supp.id, holder_type: 'Supporter'}}), flyd.stream(state.params$().supporter))
    const card$ = flyd.merge(
        flyd.stream({})
        , flyd.map(supp => ({name: supp.name, address_zip: supp.zip_code}), flyd.stream(state.params$().supporter)))
    const coverFees$ = flyd.map(params => (params.manual_cover_fees || params.hide_cover_fees_option) ? false : true, params$)

    const hideCoverFeesOption$ = flyd.map(params => params.hide_cover_fees_option, params$)

    state.donationTotal$ = flyd.combine((donation$, coverFees$) => {
        const feeStructure = app.nonprofit.feeStructure
        if (!feeStructure) {
           throw new Error("billing Plan isn't found!")
         }
         return calculateTotal({feeCovering: coverFees$(), amount: donation$().amount}, new CommitchangeStripeFeeStructure(feeStructure));
      }, [state.donation$, coverFees$])
      
      state.potentialFees$ = flyd.map((donation) => {
        const feeStructure = app.nonprofit.feeStructure
        if (!feeStructure) {
           throw new Error("billing Plan isn't found!")
         }
         const ccFeeStructure = new CommitchangeStripeFeeStructure(feeStructure)
         const fee = ccFeeStructure.calcFromNet(Money.fromCents(donation.amount || 0, 'usd')).fee
         return "$" + centsToDollars(fee.amountInCents)
      }, state.donation$)


    state.cardForm = cardForm.init({path: '/cards', card$, payload$: cardPayload$, outerError$: state.error$, 
    donationTotal$: state.donationTotal$, coverFees$, potentialFees$: state.potentialFees$,
    hide_cover_fees_option$: hideCoverFeesOption$})
    state.supporter$ = state.params$().supporter
    // // Set the card ID into the donation object when it is saved
    const cardToken$ = flyd.map(R.prop('token'), state.cardForm.saved$)

    state.updateCardAndAmount$ = flyd.flatMap(
        resp => {
            if(state.posting) return flyd.stream()
            else state.posting = true
            return request({
            method: 'put'
            , path: state.rdUpdateAmountPath
            , send: {edit_token: state.token, token: cardToken$(), amount: state.donationTotal$(), fee_covered: coverFees$()}
        }).load}
        , cardToken$
    )


    state.error$ = flyd.mergeAll([
        , flyd.map(R.always(undefined), state.cardForm.form.submit$)
        , state.cardForm.error$
        , flyd.map(resp => "An unknown error occurred. Please try again later", flyd.filter(resp =>
        {
            return resp.body.error || resp.status >= 300
        }, state.updateCardAndAmount$))
    ])



    state.success$ = flyd.filter(resp => {
        return !resp.body.error|| resp.status < 300
    }, state.updateCardAndAmount$)

    // Control progress bar
    state.progress$ = flyd.scanMerge([
        [state.cardForm.form.validSubmit$, R.always({status: 'Checking card...', percentage: 20, hidden:false})]
        , [state.cardForm.saved$, R.always({status: 'Finalizing...', percentage: 100, hidden:false})]
        , [state.cardForm.error$, R.always({hidden: true, percentage: 0})] // Hide when an error shows up
        , [flyd.filter(R.identity,state.error$), R.always({hidden: true})] // Hide when an error shows up
    ], {hidden: true})

    state.loading$ = flyd.mergeAll([
        flyd.map(R.always(true), state.cardForm.form.validSubmit$)
        , flyd.map(R.always(false), state.cardForm.error$)
        , flyd.map(R.always(false), state.error$)
        , flyd.map(R.always(false), state.success$)
    ])


    flyd.lift(() => state.posting = false, state.error$)

    flyd.lift((ev) => {
        window.location.reload()
        },
        state.success$)

    flyd.lift(() => {
        console.log(state.error$())
    }, state.error$)

    return state
}

function view(state) {
  var isRecurring = true
  var dedic =  {}
  return h('div.wizard-step.payment-step', [
    h('p.u-fontSize--18 u.marginBottom--0.u-centered', [
    h('span', '$' + format.centsToDollars(state.donationTotal$()))
    , h('strong', isRecurring ? ' monthly recurring' : ' one-time ')
    ])
  , dedic && (dedic.first_name || dedic.last_name)
      ? h('p.u-centered', `In ${dedic.dedication_type || 'honor'} of ${dedic.first_name} ${dedic.last_name}`)
      : ''
  , h('div.u-marginBottom--10', [ 
      cardForm.view(R.merge(state.cardForm, {error$: state.error$, hideButton: state.loading$()}))
    , progressBar(state.progress$())
    ])
  ])
}

module.exports = {view, init}
