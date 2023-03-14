# frozen_string_literal: true
# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE

json.id payment.houid
json.object 'payment'
json.date payment.date

json.supporter do
  json.partial! '/api_new/common/supporter', supporter: Supporter.find(payment.supporter_id)

json.payment_type do
  json.partial! '/api_new/common/payment_type', payment: payment
