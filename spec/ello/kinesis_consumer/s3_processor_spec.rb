require 'spec_helper'
require 'ello/kinesis_consumer/s3_processor'

describe Ello::KinesisConsumer::S3Processor, vcr: true do

  it 'sets the prefix name to "s3"' do
    expect(described_class.prefix).to eq('s3')
    expect(StreamReader).to receive(:new).with(stream_name: 'foo',
                                               prefix: 's3')
    described_class.new(stream_name: 'foo')
  end

  describe 'processing events' do
    let(:processor) { described_class.new }
    let(:data) { File.read(File.join('spec', 'support', 'fixtures', 'user_was_created.avro')) }
    let(:seq_number) { '12345' }
    let(:shard_id) { '1' }
    let(:opts) { { schema_name: 'user_was_created', sequence_number: seq_number, raw_data: data, shard_id: shard_id } }
    let(:record) { {} }
    let(:s3_obj) { Aws::S3::Client.new.get_object(bucket: ENV['S3_KINESIS_EVENT_BUCKET'], key: "#{ENV['KINESIS_STREAM_NAME']}/#{shard_id}/#{seq_number}")}

    before do
      allow_any_instance_of(StreamReader).to receive(:run!).and_yield(record, opts)
      processor.run!
    end

    it 'adds the event to S3 and can be retrieved and parsed after the fact' do
      last_event = StringIO.new(s3_obj.body.read)
      parsed_event = Avro::DataFile::Reader.new(last_event, Avro::IO::DatumReader.new)

      expect(parsed_event.first["email"]).to eq "hello@example.com"
      expect(parsed_event.datum_reader.readers_schema.class).to eq Avro::Schema::RecordSchema
      expect(parsed_event.datum_reader.readers_schema.name).to eq "UserWasCreated"
    end
  end
end
