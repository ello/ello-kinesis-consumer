require 'librato/metrics'

module Ello
  module LibratoReporter

    class << self
      def run!(email: ENV['LIBRATO_USER'], token: ENV['LIBRATO_TOKEN'])
        @client = Librato::Metrics::Client.new
        @client.authenticate(email, token)
        @queue = Librato::Metrics::Queue.new(autosubmit_interval: 10, client: @client)
        add_listeners
      end

      private

      def add_listeners
        ActiveSupport::Notifications.subscribe('stream_reader.process_record') do |name, start, finish, id, payload|
          @queue.add "#{name}.duration": {
                          value: (finish - start),
                          source: "#{payload[:stream_name]}:#{payload[:shard_id]}" },
                     "#{name}.latency": {
                          value: payload[:ms_behind],
                          source: "#{payload[:stream_name]}:#{payload[:shard_id]}" }
        end
      end
    end

  end
end
