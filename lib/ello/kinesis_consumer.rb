require 'ello/string_extensions'
require 'ello/hash_extensions'
require 'ello/kinesis_consumer/knowtify_processor'
require 'ello/kinesis_consumer/mailchimp_processor'

Gibbon::Request.timeout = Integer(ENV['MAILCHIMP_TIMEOUT'] || 120)
