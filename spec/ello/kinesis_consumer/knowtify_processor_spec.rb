require 'spec_helper'

describe Ello::KinesisConsumer::KnowtifyProcessor, freeze_time: true do

  before do
    allow_any_instance_of(Knowtify::Client).to receive(:upsert)
    allow_any_instance_of(Knowtify::Client).to receive(:delete)
    allow_any_instance_of(Ello::KinesisConsumer::StreamReader).to receive(:run!).and_yield(record, schema_name)
  end

  let(:processor) { described_class.new }

  describe 'when presented with a UserWasCreated event' do
    let(:schema_name) { 'user_was_created' }
    let(:record) do
      {
        'email' => 'test@example.com',
        'username' => 'testuser',
        'created_at' => Time.now.to_f
      }
    end

    it 'creates a record in Knowtify' do
      expect_any_instance_of(Knowtify::Client).to receive(:upsert).with([{
        email: 'test@example.com',
        data: {
          username: 'testuser',
          created_at: Time.now.to_datetime
        }
      }])
      processor.run!
    end
  end

  describe 'when presented with a UserChangedEmail event' do
    let(:schema_name) { 'user_changed_email' }
    let(:record) do
      {
        'username' => 'testuser',
        'email' => 'test2@example.com',
        'previous_email' => 'test@example.com',
        'created_at' => Time.now.to_f
      }
    end

    it 'removes and recreates a record in Knowtify' do
      expect_any_instance_of(Knowtify::Client).to receive(:delete).with([ 'test@example.com' ])
      expect_any_instance_of(Knowtify::Client).to receive(:upsert).with([{
        email: 'test2@example.com',
        data: {
          username: 'testuser',
          created_at: Time.now.to_datetime
        }
      }])
      processor.run!
    end
  end

  describe 'when presented with a UserWasDestroyed event' do
    let(:schema_name) { 'user_was_deleted' }
    let(:record) do
      {
        'email' => 'test@example.com',
        'deleted_at' => Time.now.to_f
      }
    end

    it 'removes a record in Knowtify' do
      expect_any_instance_of(Knowtify::Client).to receive(:delete).with([ 'test@example.com' ])
      processor.run!
    end
  end

end
