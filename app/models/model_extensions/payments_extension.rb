# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
module ModelExtensions
  module PaymentsExtension
    include Model::AsMoneyable

    as_money :gross_amount, :net_amount, :fee_total

    delegate :currency, to: :owner

    def gross_amount
      map(&:gross_amount).sum
    end

    def net_amount
      map(&:net_amount).sum
    end

    def fee_total
      map(&:fee_total).sum
    end

    def owner
      proxy_association.owner
    end

  end
end