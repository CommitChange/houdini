# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class StripeAccount < ActiveRecord::Base
  attr_accessible  :object, :stripe_account_id
  has_one :nonprofit, primary_key: :stripe_account_id
  has_one :nonprofit_verification_process_status, primary_key: :stripe_account_id

  ## this scopes let you find accounts that do or do not have a future_requirements attribute
  scope :with_future_requirements, -> {where("object->'future_requirements' IS NOT NULL") }
  scope :without_future_requirements, -> {where("object->'future_requirements' IS NULL") }

  def object=(input)
    serialize_on_update(input)
  end

  def verification_status
    if pending_verification.any?
      result = :pending
    elsif needs_immediate_validation_info
      result = :unverified
    elsif needs_more_validation_info
      result = :temporarily_verified
    else
      result = :verified
    end
    result
  end

  def requirements
    Requirements.new(object['requirements'])
  end

  def future_requirements
    Requirements.new(object['future_requirements'])
  end

  def future_deadline_with_requirements
    return nil if future_requirements.current_deadline.nil?
    [
      future_requirements.currently_due,
      future_requirements.past_due,
      future_requirements.eventually_due,
      future_requirements.pending_verification
  ].none?{| i| i.none?}

  end

  # describes a deadline where additional requirements are needed to be completed
  # future_requirements can have a current_deadline and not have any additional requirements so
  # we don't consider that a deadline here.
  def deadline

    requirements.current_deadline
    # if [future_requirements
    # [requirements.current_deadline, future_requirements.current_deadline].select{|i| !i.nil?}.min
    # requirements.current_deadline
  end

  def needs_more_validation_info
    validation_arrays = [self.currently_due, self.past_due, self.eventually_due].map{|i| i || []}
    validation_arrays.any? do |i| 
      !i.none? && !i.all? do |j| 
        j.starts_with?('external_account')
      end
    end
  end

  def needs_immediate_validation_info
    validation_arrays = [self.currently_due, self.past_due].map{|i| i || []}
    deadline || validation_arrays.any? do |i| 
      !i.none? && !i.all? do |j| 
        j.starts_with?('external_account')
      end
    end
  end

  private 
  def serialize_on_update(input)

    object_json = nil
    
    case input
    when Stripe::Account
      write_attribute(:object, input.to_hash)
      object_json = self.object
      puts self.object
    when String
      write_attribute(:object, input)
      object_json = self.object
    end
    self.charges_enabled = !!object_json['charges_enabled']
    self.payouts_enabled = !!object_json['payouts_enabled']
    requirements = Requirements.new( object_json['requirements'])
    self.disabled_reason =  requirements.disabled_reason
    self.currently_due = requirements.currently_due
    self.past_due =  requirements.past_due
    self.eventually_due =  requirements.eventually_due
    self.pending_verification = requirements.pending_verification

    unless self.stripe_account_id
      self.stripe_account_id = object_json['id']
    end

    self.object
  end


  # describes the Stripe Account Requirements in a more pleasant way
  class Requirements
    def initialize(requirements)
      @requirements = requirements || {}
    end
    
    def current_deadline
      if @requirements['current_deadline'] && @requirements['current_deadline'].to_i != 0
        Time.at(@requirements['current_deadline'].to_i)
      else
        nil
      end
    end
  
    def disabled_reason
      @requirements['disabled_reason']
    end
  
    def currently_due
      @requirements['currently_due']  || []
    end
    
    def past_due
      @requirements['past_due']  || []
    end
  
    def eventually_due
      @requirements['eventually_due'] || []
    end
  
    def pending_verification
      @requirements['pending_verification'] || []
    end
  end
end
