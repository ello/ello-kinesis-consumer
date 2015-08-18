require 'net/http'
require 'uri'

module Knowtify
  class Client

    # API documentation is at http://api.knowtify.io/v1.0/docs/knowtify-api-basics

    def initialize(token: ENV['KNOWTIFY_API_TOKEN'])
      @token = token
    end

    # Create/update contacts. Expects an array of contact hashes.
    def upsert(contacts)
      uri = URI.parse('http://www.knowtify.io/api/v1/contacts/upsert')
      req = Net::HTTP::Post.new(uri.path)
      req.body = JSON.generate(contacts: contacts)
      req['Content-Type'] = 'application/json'
      req['Authorization'] = "Token token=\"#{@token}\""
      response = Net::HTTP.start(uri.host, uri.port) do |http|
        http.request(req)
      end
      JSON.parse(response.body)
    end

    # Trigger a transactional e-mail to the provided contacts (array of hashes) with the associated event name
    def transactional(event_name, contacts)
      uri = URI.parse('http://www.knowtify.io/api/v1/contacts/upsert')
      req = Net::HTTP::Post.new(uri.path)
      req.body = JSON.generate(event: name, contacts: contacts)
      req['Content-Type'] = 'application/json'
      req['Authorization'] = "Token token=\"#{@token}\""
      response = Net::HTTP.start(uri.host, uri.port) do |http|
        http.request(req)
      end
      JSON.parse(response.body)
    end


    # Expects an array of e-mail addresses to delete
    def delete(emails)
      uri = URI.parse('http://www.knowtify.io/api/v1/contacts/delete')
      req = Net::HTTP::Post.new(uri.path)
      req.body = JSON.generate(contacts: emails)
      req['Content-Type'] = 'application/json'
      req['Authorization'] = "Token token=\"#{@token}\""
      response = Net::HTTP.start(uri.host, uri.port) do |http|
        http.request(req)
      end
      JSON.parse(response.body)
    end
  end
end
