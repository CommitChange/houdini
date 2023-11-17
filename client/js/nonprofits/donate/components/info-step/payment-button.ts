// License: LGPL-3.0-or-later
const h = require('snabbdom/h')
import set from 'lodash/set';

interface Props {
  error?: string
  loading?: boolean
  setSelectedPayment(type:string):string
  loadingText?: string
  buttonText?: string
  I18n: any
}


export default function paymentButton({setSelectedPayment, I18n, buttonText, loadingText, ...options}:Props , label:string, state:any) : ReturnType<typeof h> {
  const error =  !!options.error
  const loading = !!options.loading
  

  const btnclass= set({ 'ff-button--loading': loading }, label, true)

  return h('div.ff-buttonWrapper.u-centered.u-marginTop--10', {
    class: { 'ff-buttonWrapper--hasError': error }
  }, [
    h('p.ff-button-error', {style: {display: !!error ? 'block' : 'none'}} , error)
  , h('button.ff-button', {
      props: { type: 'submit', disabled: loading }
    , on: { click: () => setSelectedPayment(label) }
    , class: btnclass
    }, [
      loading ? (loadingText || " Saving...") : (buttonText ||  I18n.t('nonprofits.donate.payment.card.submit'))
    ])
  ])
}