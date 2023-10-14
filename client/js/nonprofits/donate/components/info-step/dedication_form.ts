// License: LGPL-3.0-or-later
const h = require('snabbdom/h')
import uuid  from 'uuid';

export interface DedicationData {
  dedication_type?: 'honor' | 'memory' | null;
  first_name?: string;
  last_name?: string;
  email?: string;
  phone?: string;
  address?: string;
  dedication_note?:string;
}

interface DedicationFormInput {
  submitDedication: (target:EventTarget) => void;
  dedicationData: DedicationData
  I18n: {t:(...rest:string[]) => string}
}

export default function dedication_form(input:DedicationFormInput) : ReturnType<typeof h> {
  const radioId1 = uuid.v1() // need unique ids for the checkbox id and label for attrs
  const radioId2 = uuid.v1()
  const data = input.dedicationData;
  const I18n  = input.I18n;
  return h('form.dedication-form', {
    on: {submit: (ev:Event) => {ev.preventDefault(); input.submitDedication(ev.currentTarget)}}
  }, [
    h('p.u-centered.u-strong.u-marginBottom--10', I18n.t('nonprofits.donate.dedication.info'))
  , h('fieldset.u-marginBottom--0.col-6', [
      h('input', {props: {
        name: 'dedication_type'
      , type: 'radio'
      , id: radioId1
      , value: 'honor'
      , checked: !data.dedication_type || data.dedication_type === 'honor'
      }})
    , h('label', {props: {htmlFor: radioId1}}, I18n.t('nonprofits.donate.dedication.in_honor_label'))
    ])
  , h('fieldset.u-marginBottom--0', [
      h('input', {props: {
        name: 'dedication_type'
      , type: 'radio'
      , value: 'memory'
      , id: radioId2
      , checked: data.dedication_type === 'memory'
      }})
    , h('label', {props: {htmlFor: radioId2}}, I18n.t('nonprofits.donate.dedication.in_memory_label'))
    ])
  , h('fieldset.u-marginBottom--0.col-6', [
      h('input', {props: {
        name: 'first_name'
      , placeholder: I18n.t('nonprofits.donate.dedication.first_name')
      , title: 'First name'
      , type: 'text'
      , value: data.first_name
      }})
    ])
  , h('fieldset.u-marginBottom--0', [
      h('input', {props: {
        name: 'last_name'
      , placeholder: I18n.t('nonprofits.donate.dedication.last_name')
      , title: 'Last name'
      , type: 'text'
      , value: data.last_name
      }})
    ])
  , h('fieldset.u-marginBottom--0.col-6', [
      h('input', {props: {
        name: 'email'
      , placeholder: I18n.t('nonprofits.donate.dedication.email')
      , title: 'Email'
      , type: 'text'
      , value: data.email
      }})
    ])
  , h('fieldset.u-marginBottom--0', [
      h('input', {props: {
        name: 'phone'
      , placeholder: I18n.t('nonprofits.donate.dedication.phone')
      , title: 'Phone'
      , type: 'text'
      , value: data.phone
      }})
    ])
  , h('fieldset.u-marginBottom--0', [
      h('input', {props: {
        name: 'address'
      , placeholder: I18n.t('nonprofits.donate.dedication.full_address')
      , title: 'Address'
      , type: 'text'
      , value: data.address
      }})
    ])
  , h('fieldset', [
      h('textarea', {props: {
        name: 'dedication_note'
      , placeholder: I18n.t('nonprofits.donate.dedication.note')
      , title: 'Note'
      , value: data.dedication_note
      }})
    ])
  , h('div.u-centered', [
      h('button.button', I18n.t('nonprofits.donate.dedication.save'))
    ])
  ]);
}