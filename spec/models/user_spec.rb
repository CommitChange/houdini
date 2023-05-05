# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require 'rails_helper'

RSpec.describe User, :type => :model do

  it {is_expected.to have_db_column(:locked_at).of_type(:datetime)}
  it {is_expected.to have_db_column(:unlock_token).of_type(:string)}
  it {is_expected.to have_db_column(:failed_attempts).of_type(:integer).with_options(default:0, null:false)}

  it 'locks correctly after 10 attempts' do
    user = create(:user)
    user.confirm
    
    10.times { user.valid_for_authentication?{ false } }
    assert user.reload.access_locked?
  end

  describe '.send_reset_password_instructions' do
    let(:user) { create(:user) }

    it 'returns a token when user hasn\'t requested a reset password token before' do
      expect(user.send_reset_password_instructions).to be_truthy
    end

    it 'returns false when user has requested a reset password too recently' do
      user.send_reset_password_instructions
      expect(user.send_reset_password_instructions).to be false
    end

    it 'adds errors to user when a user has requested a reset password too recently' do
      2.times { user.send_reset_password_instructions }
      expect(user.errors.messages[:user]).to eq(['can\'t reset password because a request was just sent'])
    end
  end
end
