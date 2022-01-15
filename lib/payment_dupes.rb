module PaymentDupes
    def self.copy_dedication(source, target)
        return true if source.donation.dedication.blank?
        return true if target.donation.dedication.present? && (source.donation.dedication.blank? || target.donation.dedication == source.donation.dedication)
        return false if target.donation.dedication.present?
        target.donation.dedication = source.donation.dedication
        target.donation.save!
    end

    def self.can_copy_dedication?(source, target)
        return true if source.donation.dedication.blank?
        return true if target.donation.dedication.present? && (source.donation.dedication.blank? || target.donation.dedication == source.donation.dedication)
        return false if target.donation.dedication.present?
        true
    end

    def self.copy_designation(src, target, designations_to_become_comments)
        if designations_to_become_comments.include?(src.donation.designation)
            if target.donation.comment.blank?
                target.donation.comment = "Designation: " + src.donation.designation
            else
                target.donation.comment += " \nDesignation: " + src.donation.designation
            end
            src.donation.designation = nil
            target.donation.save!
            src.donation.save!
            return true
        end
        return true if src.donation.designation.blank?
        return true if target.donation.designation.present? && (src.donation.designation.blank? || target.donation.designation == src.donation.designation)
        return false if target.donation.dedication.present?
        target.donation.designation = src.donation.designation
        target.donation.save!
    end

    def self.can_copy_designation?(src, target, designations_to_become_comments)
        if designations_to_become_comments.include?(src.donation.designation)
            return true
        end
        return true if src.donation.designation.blank?
        return true if target.donation.designation.present? && (src.donation.designation.blank? || target.donation.designation == src.donation.designation)
        return false if target.donation.designation.present?
        true
    end

    def self.copy_comment(source, target)
        return true if source.donation.comment.blank?
        return true if target.donation.comment.present? && (source.donation.comment.blank? || target.donation.comment == source.donation.comment)
        return false if target.donation.comment.present?
        target.donation.comment = source.donation.comment
        target.donation.save!
    end

    def self.can_copy_comment?(source, target)
        return true if source.donation.comment.blank?
        return true if target.donation.comment.present? && (source.donation.comment.blank? || target.donation.comment == source.donation.comment)
        return false if target.donation.comment.present?
        true
    end

    def self.payment_dupes(np_id, designations_to_become_comments)
        return if Rails.env.production?
        ActiveRecord::Base.transaction do
            nonprofit = Nonprofit.find(np_id)
            etap_id_cf = CustomFieldMaster.find_by(name: 'E-Tapestry Id #').id
            supp = nonprofit.supporters.not_deleted.joins(:custom_field_joins).where('custom_field_joins.custom_field_master_id = ?', etap_id_cf).references(:custom_field_joins)
            duplicate_payments = [['Original Payment (Original Commit Change)', 'Payment Duplicate (Original Commit Change)', 'How It Looks After Deleting The Duplicate (Commit Change Copy)']]
            couldnt_delete = [['Original Payment (Original Commit Change)', 'Payment Duplicate (Original Commit Change)', 'Reason']]

            supp.find_each do |s|
                offsite_payments = s.payments.includes(:donation).where("kind = 'OffsitePayment'").joins(:journal_entries_to_item)

                offsite_payments.find_each do |offsite|
                    # match one offsite donation with an online donation if:
                    # - the offsite donation was created on the same day that we ran the import and
                    # - the offsite donation has the same date as the online payment
                    # - there is a journal entry item for the offsite payment

                    donation_or_ticket_payments = s.payments.not_matched.includes(:donation).where("(kind = 'Donation' OR kind = 'Ticket' OR kind = 'RecurringDonation') AND gross_amount = ? AND to_char(date, 'YYYY-MM-DD') = ?", offsite.gross_amount, offsite.date.strftime('%Y-%m-%d'))
                    donation_or_ticket_payments.find_each do |online|
                        reasons = []
                        if online.kind == 'Ticket'
                            offsite.destroy
                            duplicate_payments << [
                                'https://us.commitchange.com/nonprofits/3693/payments?pid=' + online.id.to_s,
                                'https://us.commitchange.com/nonprofits/3693/payments?pid=' + offsite.id.to_s,
                                'https://commitchange-test.herokuapp.com/nonprofits/3693/payments?pid=' + online.id.to_s
                            ]
                            if online.payment_dupe_status.present?
                                online.payment_dupe_status.matched = true
                                online.payment_dupe_status.save!
                            else
                                online.payment_dupe_status = PaymentDupeStatus.create!(matched: true)
                            end
                        elsif offsite.donation.event.present? && offsite.donation.event != online.donation.event
                            # different events, dont delete
                            couldnt_delete << [
                                'https://us.commitchange.com/nonprofits/3693/payments?pid=' + online.id.to_s,
                                'https://us.commitchange.com/nonprofits/3693/payments?pid=' + offsite.id.to_s,
                                'Event, '
                            ]
                        elsif offsite.donation.campaign.present? && offsite.donation.campaign != online.donation.campaign
                            # different campaigns, dont delete
                            couldnt_delete << [
                                'https://us.commitchange.com/nonprofits/3693/payments?pid=' + online.id.to_s,
                                'https://us.commitchange.com/nonprofits/3693/payments?pid=' + offsite.id.to_s,
                                'Campaign, '
                            ]
                        else
                            unless can_copy_comment?(offsite, online)
                                reasons << 'Comment'
                            end
                            unless can_copy_dedication?(offsite, online)
                                reasons << 'Dedication'
                            end
                            unless can_copy_designation?(offsite, online, designations_to_become_comments)
                                reasons << 'Designation'
                            end
                            if reasons.none?
                                if online.kind == 'RecurringDonation'
                                    ActiveRecord::Base.transaction do
                                        # addresses all the payments from that recurring donation so we avoid future problems
                                        recurring_donation = online.donation
                                        recurring_payments = recurring_donation.payments
                                        temp_duplicate_payments = []
                                        temp_offsite_matches = []
                                        recurring_payments.find_each do |recurring_payment|
                                            equivalent_offsite = s.payments.not_matched.where("kind = 'OffsitePayment' AND gross_amount = ? AND to_char(payments.date, 'YYYY-MM-DD') = ?", recurring_payment.gross_amount, recurring_payment.date.strftime('%Y-%m-%d')).joins(:journal_entries_to_item)
                                            if equivalent_offsite.count == 1
                                                # match!
                                                temp_offsite_matches << equivalent_offsite.first
                                                temp_duplicate_payments << [
                                                    'https://us.commitchange.com/nonprofits/3693/payments?pid=' + recurring_payment.id.to_s,
                                                    'https://us.commitchange.com/nonprofits/3693/payments?pid=' + equivalent_offsite.first.id.to_s,
                                                    'https://commitchange-test.herokuapp.com/nonprofits/3693/payments?pid=' + recurring_payment.id.to_s
                                                ]
                                                if recurring_payment.payment_dupe_status.present?
                                                    recurring_payment.payment_dupe_status.matched = true
                                                    recurring_payment.payment_dupe_status.save!
                                                else
                                                    recurring_payment.payment_dupe_status = PaymentDupeStatus.create!(matched: true)
                                                end
                                                if equivalent_offsite.first.payment_dupe_status.present?
                                                    equivalent_offsite.first.payment_dupe_status.matched = true
                                                    equivalent_offsite.first.payment_dupe_status.save!
                                                else
                                                    equivalent_offsite.first.payment_dupe_status = PaymentDupeStatus.create!(matched: true)
                                                end
                                            end
                                        end
                                        if temp_offsite_matches.any?
                                            # it's the same donation for all of them so
                                            # we can do the copies once
                                            copy_comment(offsite, online)
                                            copy_dedication(offsite, online)
                                            copy_designation(offsite, online, designations_to_become_comments)
                                            duplicate_payments.concat(temp_duplicate_payments)
                                            # deletes matching offsites here
                                            temp_offsite_matches.each do |id|
                                                p = Payment.find(id)
                                                d = p.donation
                                                d.payments.destroy_all
                                                d.destroy
                                            end
                                        else
                                            couldnt_delete << [
                                                'https://us.commitchange.com/nonprofits/3693/payments?pid=' + online.id.to_s,
                                                'https://us.commitchange.com/nonprofits/3693/payments?pid=' + offsite.id.to_s,
                                                'Recurring Donation Payments'
                                            ]
                                            raise ActiveRecord::Rollback
                                        end
                                    end
                                else
                                    copy_comment(offsite, online)
                                    copy_dedication(offsite, online)
                                    copy_designation(offsite, online, designations_to_become_comments)
                                    offsite.donation.destroy
                                    offsite.destroy
                                    duplicate_payments << [
                                        'https://us.commitchange.com/nonprofits/3693/payments?pid=' + online.id.to_s,
                                        'https://us.commitchange.com/nonprofits/3693/payments?pid=' + offsite.id.to_s,
                                        'https://commitchange-test.herokuapp.com/nonprofits/3693/payments?pid=' + online.id.to_s
                                    ]
                                    if online.payment_dupe_status.present?
                                        online.payment_dupe_status.matched = true
                                        online.payment_dupe_status.save!
                                    else
                                        online.payment_dupe_status = PaymentDupeStatus.create!(matched: true)
                                    end
                                end
                            else
                                couldnt_delete << [
                                    'https://us.commitchange.com/nonprofits/3693/payments?pid=' + online.id.to_s,
                                    'https://us.commitchange.com/nonprofits/3693/payments?pid=' + offsite.id.to_s,
                                    reasons.join(', ')
                                ]
                            end
                        end
                    end
                end
            end
            File.write('payment_dupes.csv', Format::Csv.from_array(duplicate_payments))
            File.write('couldnt_delete.csv', Format::Csv.from_array(couldnt_delete))
        end
    end
end
