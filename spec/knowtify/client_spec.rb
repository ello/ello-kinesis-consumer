require 'spec_helper'

describe Knowtify::Client, vcr: true do
  let(:client) { Knowtify::Client.new }

  describe 'creating a contact' do
    it 'returns the response body from the service' do
      expect(client.upsert([{ email: 'test@example.com',
                              data: { created_at: Time.now.iso8601 } }])).to eq({
        "status" => "received",
        "contacts" => 1,
        "contacts_updated" => 1,
        "contacts_errored" => 0,
        "errors" => "None found by our cylon detector.",
        "warnings" => "...and zero warnings! Your request is in ship shape!" })
    end
  end

  describe 'updating a contact' do
    it 'returns the response body from the service' do
      client.upsert([{ email: 'test@example.com' }])
      expect(client.upsert([{ email: 'test@example.com',
                              data: { created_at: Time.now.iso8601 } }])).to eq({
        "status" => "received",
        "contacts" => 1,
        "contacts_updated" => 1,
        "contacts_errored" => 0,
        "errors" => "None found by our cylon detector.",
        "warnings" => "...and zero warnings! Your request is in ship shape!" })
    end
  end

  describe 'deleting a contact' do
    it 'returns the response body from the service' do
      client.upsert([{ email: 'test@example.com' }])
      expect(client.delete(['test@example.com'])).to eq({
        "status" => "received",
        "contacts" => 1,
        "successes" => 1,
        "errors" => 0 })
    end
  end

end
