// License: LGPL-3.0-or-later
const h = require('snabbdom/h')
const R = require('ramda')
const flyd = require('flyd')
flyd.lift = require('flyd/module/lift')
flyd.flatMap = require('flyd/module/flatmap')
const request = require('../../common/request')
const cardForm = require('../../components/card-form.es6')
const sepaForm = require('../../components/sepa-form.es6')
const progressBar = require('../../components/progress-bar')
const { CommitchangeFeeCoverageCalculator } = require('../../../../javascripts/src/lib/payments/commitchange_fee_coverage_calculator')
const { centsToDollars } = require('../../common/format')
const cloneDeep = require('lodash/cloneDeep')
const DonationSubmitter = require('./donation_submitter').default;

const sepaTab = 'sepa'
const cardTab = 'credit_card'

function init(state) {
  const params$ = (state && state.params$) || flyd.stream({});

  const payload$ = flyd.map(supp => ({ card: { holder_id: supp.id, holder_type: 'Supporter' } }), state.supporter$)
  const supporterID$ = flyd.map(supp => supp.id, state.supporter$)
  const card$ = flyd.merge(
    flyd.stream({})
    , flyd.map(supp => ({ name: supp.name, address_zip: supp.zip_code }), state.supporter$))

  const coverFees$ = flyd.map(params => (params.manual_cover_fees || params.hide_cover_fees_option) ? false : true, params$)

  const hideCoverFeesOption$ = flyd.map(params => params.hide_cover_fees_option, params$)

  const feeCalculator$ = flyd.map((coverFees) => {
    const feeStructure = app.nonprofit.feeStructure
    if (!feeStructure) {
      throw new Error("billing Plan isn't found!")
    }

    return new CommitchangeFeeCoverageCalculator({
      ...app.nonprofit.feeStructure,
      currency: 'usd',
      feeCovering: coverFees
    });
  }, coverFees$)

  const calcFromNetResult$ = flyd.combine((donation$, feeCalculator$) => {
    return feeCalculator$().calcFromNet(donation$().amount)
  }, [state.donation$, feeCalculator$]);
  // Give a donation of value x, this returns x + estimated fees (using fee coverage formula) if fee coverage is selected OR
  // x if fee coverage is not selected
  state.donationTotal$ = flyd.map((calcFromNetResult) => calcFromNetResult.actualTotalAsNumber
    , calcFromNetResult$);

  //Given a donation of value x, this gives the amount of fees that would be added if fee coverage were selected, i.e. so 
  // the nonprofit gets a net of x
  state.potentialFees$ = flyd.map((calcFromNetResult) => calcFromNetResult.estimatedFees.feeAsString
    , calcFromNetResult$);

  state.cardForm = cardForm.init({
    path: '/cards', card$, payload$, donationTotal$: state.donationTotal$, coverFees$, potentialFees$: state.potentialFees$,
    hide_cover_fees_option$: hideCoverFeesOption$
  })
  state.sepaForm = sepaForm.init({ supporter: supporterID$ })

  // Set the card ID into the donation object when it is saved
  const cardToken$ = flyd.map((i) => {
    return i['token']
  }, state.cardForm.saved$)
  const donationWithAmount$ = flyd.combine((donation, donationTotal, coverFees$) => {
    const d = cloneDeep(donation())
    d.amount = donationTotal()
    d.fee_covered = coverFees$()
    return d;
  }, [state.donation$, state.donationTotal$, coverFees$])
  const donationWithCardToken$ = flyd.lift(R.assoc('token'), cardToken$, donationWithAmount$)

  // Set the sepa transfer details ID into the donation object when it is saved
  const sepaId$ = flyd.map(R.prop('id'), state.sepaForm.saved$)
  const donationWithSepaId$ = flyd.lift(R.assoc('direct_debit_detail_id'), sepaId$, state.donation$)

  state.donationParams$ = flyd.immediate(
    flyd.combine((sepaParams, cardParams, activeTab) => {
      if (activeTab() == sepaTab) {
        return sepaParams()
      } else if (activeTab() == cardTab) {
        return cardParams()
      }
    }, [donationWithSepaId$, donationWithCardToken$, state.activePaymentTab$])
  )
  const donationResp$ = flyd.flatMap((donation) => postDonation(donation, paramsWithGift$), state.donationParams$)

  // Post the gift option, if necessary
  const paramsWithGift$ = flyd.filter(params => params.gift_option_id || params.gift_option && params.gift_option.id, state.params$)

  state.error$ = flyd.mergeAll([
    flyd.map(R.prop('error'), flyd.filter(resp => resp.error, donationResp$))
    , flyd.map(R.always(undefined), state.cardForm.form.submit$)
    , flyd.map(R.always(undefined), state.sepaForm.form.submit$)
    , state.cardForm.error$
    , state.sepaForm.error$
  ])
  state.paid$ = flyd.filter(resp => !resp.error, donationResp$)

  // Control progress bar for card payment
  state.progress$ = flyd.scanMerge([
    [state.cardForm.form.validSubmit$, R.always({ status: I18n.t('nonprofits.donate.payment.loading.checking_card'), percentage: 20 })]
    , [state.cardForm.saved$, R.always({ status: I18n.t('nonprofits.donate.payment.loading.sending_payment'), percentage: 100 })]
    , [state.cardForm.error$, R.always({ hidden: true })] // Hide when an error shows up
    , [flyd.filter(R.identity, state.error$), R.always({ hidden: true })] // Hide when an error shows up
  ], { hidden: true })

  state.loading$ = flyd.mergeAll([
    flyd.map(R.always(true), state.cardForm.form.validSubmit$)
    , flyd.map(R.always(true), state.sepaForm.form.validSubmit$)
    , flyd.map(R.always(false), state.paid$)
    , flyd.map(R.always(false), state.cardForm.error$)
    , flyd.map(R.always(false), state.sepaForm.error$)
    , flyd.map(R.always(false), state.error$)
  ])

  // post utm tracking details after donation is saved
  // flyd.map(
  //   R.apply((utmParams, donationResponse) => postTracking(app.utmParams, donationResp$))
  //   , state.paid$
  // )

  return state
}

const postTracking = (utmParams, donationResponse) => {
  const params = R.merge(utmParams, { donation_id: donationResponse().donation.id })

  if (utmParams.utm_source || utmParams.utm_medium || utmParams.utm_content || utmParams.utm_campaign) {
    return flyd.map(R.prop('body'), request({
      path: `/nonprofits/${app.nonprofit_id}/tracking`
      , method: 'post'
      , send: params
    }).load)
  }
}

const donationSubmitter = new DonationSubmitter();
const postDonation = (donation, paramsWithGift$) => {
  

  const result$ = flyd.stream()
  const campaign_gift_option_id = paramsWithGift$() && (paramsWithGift$().gift_option_id || paramsWithGift$().gift_option && paramsWithGift$().gift_option.id);
  const plausible = window['plausible'];
  donationSubmitter.Submit({
    donation,
    campaign_gift_option_id,
    plausible
  }).then((i) => {
    //if it's an object, that means this has completed.
    if (typeof i === 'object') {
      result$(i);
    }
  }).catch((i) => result$(i))
  
  return result$;
}

const paymentTabs = (state) => {
  if (state.activePaymentTab$() == sepaTab) {
    return payWithSepaTab(state)
  } else if (state.activePaymentTab$() == cardTab) {
    return payWithCardTab(state)
  }
}

const payWithSepaTab = state => {
  return h('div.u-marginBottom--10', [
    sepaForm.view(state.sepaForm)
  ])
}

const payWithCardTab = state => {
  var result = h('div.u-marginBottom--10', [
    cardForm.view(R.merge(state.cardForm, { error$: state.error$, hideButton: state.loading$() }))
    , progressBar(state.progress$())
  ])
  return result
}

function view(state) {
  var isRecurring = state.donation$().recurring
  var dedic = state.dedicationData$()
  var amountLabel = isRecurring ? ` ${I18n.t('nonprofits.donate.payment.monthly_recurring')}` : ` ${I18n.t('nonprofits.donate.payment.one_time')}`
  var weekly = "";
  if (state.donation$().weekly) {
    amountLabel = amountLabel.replace(I18n.t('nonprofits.donate.amount.monthly'), I18n.t('nonprofits.donate.amount.weekly')) + "*";
    weekly = h('div.u-centered.notice', [h("small", I18n.t('nonprofits.donate.amount.weekly_notice', { amount: (format.weeklyToMonthly(state.donationTotal$()) / 100.0), currency: app.currency_symbol }))]);
  }
  return h('div.wizard-step.payment-step', [
    h('p.u-fontSize--18 u.marginBottom--0.u-centered.amount', [
      h('span', app.currency_symbol + centsToDollars(state.donationTotal$()))
      , h('strong', amountLabel)
    ])
    , weekly
    , dedic && (dedic.first_name || dedic.last_name)
      ? h('p.u-centered', `${dedic.dedication_type === 'memory' ? I18n.t('nonprofits.donate.dedication.in_memory_label') : I18n.t('nonprofits.donate.dedication.in_honor_label')} ` + `${dedic.first_name || ''} ${dedic.last_name || ''}`)
      : ''
    , paymentTabs(state)
  ])
}

module.exports = { view, init }
