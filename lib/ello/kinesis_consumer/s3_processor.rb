require 'aws-sdk'

module Ello
  module KinesisConsumer
    class S3Processor < BaseProcessor

      def run!
        @stream_reader.run! do |record, opts|
          @logger.debug "#{opts[:schema_name]}: #{record}"
          upload_record_to_s3(opts)
        end
      end

      def upload_record_to_s3(opts)
        obj = s3_bucket.object("#{ENV['KINESIS_STREAM_NAME']}/#{opts[:shard_id]}/#{opts[:sequence_number]}")
        obj.put(body: opts[:raw_data], server_side_encryption: 'AES256')
      end
      add_transaction_tracer :upload_record_to_s3, category: :task

      private

      def s3_bucket
        @s3_bucket ||= Aws::S3::Resource.new.bucket(ENV['S3_KINESIS_EVENT_BUCKET'])
      end
    end
  end
end
