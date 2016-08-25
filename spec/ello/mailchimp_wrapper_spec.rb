require 'spec_helper'

describe MailchimpWrapper, vcr: true do
  let(:wrapper) { described_class.new }

  describe 'upserting a user to the users list' do
    it 'adds the user to the list successfully' do
      result = wrapper.upsert_to_users_list 'ops@ello.co', {}
      expect(result['email_address']).to eq('ops@ello.co')
      expect(result['status']).to eq('subscribed')
      expect(result['list_id']).to eq(ENV['MAILCHIMP_USERS_LIST_ID'])
    end

    it 'sets/maps interest groups properly' do
      result = wrapper.upsert_to_users_list 'ops@ello.co', { 'users_email_list' => true,
                                                             'daily_ello' => false,
                                                             'weekly_ello' => false }
      expect(result['interests']).to eq('c59973acc2' => true,
                                        'bc8eb143f3' => false,
                                        '6513a586b4' => false)
    end

    it 'does not bark if the user has a bad e-mail address' do
      expect { wrapper.upsert_to_users_list 'ops123', {} }.not_to raise_error
    end

    it 'return nil if an e-mail is in the skiplist' do
      ENV['EMAILS_TO_SKIP'] = 'bad,addresses'
      result = wrapper.upsert_to_users_list 'bad', {}
      expect(result).to be_nil
    end
  end

  describe 'removing a user from the users list' do
    it 'removes the user properly' do
      result = wrapper.remove_from_users_list 'ops@ello.co'
      expect(result['status']).to eq('unsubscribed')
    end

    it 'does not bark if the user is not on the list' do
      expect { wrapper.remove_from_users_list('ops123@ello.co') }.not_to raise_error
    end
  end

  describe 'upserting a user to the categories list' do
    it 'sets/maps interest groups properly' do
      result = wrapper.upsert_to_categories_list 'ops@ello.co', ['art', 'music']
      expect(result['interests']).to eq('b69a899898' => true,
                                        'c7e1e11b24' => true,
                                        '67a5758600' => false)
    end

    it 'when a category doesnt exist and needs to be created' do
      result = wrapper.upsert_to_categories_list 'ops@ello.co', ['art', 'music', 'writing']
      expect(result['interests']).to eq('b69a899898' => true,
                                        'c7e1e11b24' => true,
                                        "5999dab568" => true,
                                        '67a5758600' => false)
    end
  end
end
