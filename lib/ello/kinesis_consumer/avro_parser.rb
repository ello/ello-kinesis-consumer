require 'avro'

module Ello
  module KinesisConsumer
    class AvroParser

      def initialize(data)
        @data = data
      end

      def each_with_schema_name
        buffer = StringIO.new(@data)
        reader = Avro::DataFile::Reader.new(buffer, Avro::IO::DatumReader.new)
        reader.each do |record|
          schema_name = reader.datum_reader.readers_schema.name
          yield record, schema_name
        end
      end

    end
  end
end
