require 'httparty'

module Contractually
  class Api
    include HTTParty

    def initialize(server, api_token)
      self.class.base_uri "#{server}/v0/"
      # Empty body required so we don't get a 411 error
      # See https://github.com/jnunemaker/httparty/issues/124
      @options = { query: { api_token: api_token }, body: "" }
    end

    def query(type, path, data)
      options = @options.clone
      options[:query].merge!(data)
      self.class.send(type, path, options)
    end

    def post(path, data)
      self.query(:post, path, data)
    end

    def put(path, data)
      self.query(:put, path, data)
    end
  end
end
