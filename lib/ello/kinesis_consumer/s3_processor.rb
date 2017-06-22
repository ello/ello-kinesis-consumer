require 'aws-sdk'

module Ello
  module KinesisConsumer
    class S3Processor < BaseProcessor

      def run!
        @stream_reader.run! do |record, opts|
          @logger.debug "#{opts[:schema_name]}: #{record}"
          obj = s3_bucket.object("#{opts[:shard_id]}/#{opts[:sequence_number]}")
          obj.put(body: opts[:raw_data])
        end
      end

      private

      def s3_bucket
        @s3_bucket ||= Aws::S3::Resource.new.bucket(ENV['KINESIS_STREAM_NAME'])
      end
    end
  end
end
