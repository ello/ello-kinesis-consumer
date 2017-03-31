require 'spec_helper'

describe MailchimpWrapper, vcr: true do
  let(:wrapper) { described_class.new }

  describe 'upserting a user to the users list' do
    it 'adds the user to the list successfully' do
      result = wrapper.upsert_to_users_list(email: 'asdf1234@ello.co', preferences: {})
      expect(result['email_address']).to eq('asdf1234@ello.co')
      expect(result['status']).to eq('subscribed')
      expect(result['list_id']).to eq(ENV['MAILCHIMP_USERS_LIST_ID'])
    end

    it 'sets an already unsubscribed user to pending status' do
      wrapper.remove_from_users_list('unsubscribed.user@ello.co')
      result = wrapper.upsert_to_users_list(email: 'unsubscribed.user@ello.co', preferences: {}, force_resubscribe: true)

      expect(result['email_address']).to eq('unsubscribed.user@ello.co')
      expect(result['status']).to eq('pending')
      expect(result['list_id']).to eq(ENV['MAILCHIMP_USERS_LIST_ID'])
    end

    it 'sets/maps interest groups properly' do
      prefs_hash = { 'users_email_list' => true, 'daily_ello' => false, 'weekly_ello' => false }
      result = wrapper.upsert_to_users_list(email: 'test1@ello.co',
                                            preferences: prefs_hash)
      expect(result['interests']).to eq(
        '250fa0013d' => true,
        'a0acf584c8' => false,
        '2d020275c1' => false,
        '2762585b56' => false,
      )
    end

    it 'does not bark if the user has a bad e-mail address' do
      expect { wrapper.upsert_to_users_list(email: 'ops123', preferences: {}) }.not_to raise_error
    end

    it 'return nil if an e-mail is in the skiplist' do
      ENV['EMAILS_TO_SKIP'] = 'bad,addresses'
      result = wrapper.upsert_to_users_list(email: 'bad', preferences: {})
      expect(result).to be_nil
    end
  end

  describe 'removing a user from the users list' do
    it 'removes the user properly' do
      result = wrapper.remove_from_users_list('ops@ello.co')
      expect(result['status']).to eq('unsubscribed')
    end

    it 'does not bark if the user is not on the list' do
      expect { wrapper.remove_from_users_list('ops123@ello.co') }.not_to raise_error
    end
  end
end
