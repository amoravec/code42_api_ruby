# Copyright (c) 2016 Code42, Inc.

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
require 'bundler/setup'
require 'faraday'
require 'faraday_middleware'
require 'logger'
require 'code42/error'
require 'code42/faraday_middleware/parse_server_env'

module Code42
  class Connection
    attr_accessor :host, :port, :scheme, :path_prefix, :username, :password, :adapter, :token, :verify_https, :logger, :mlk, :last_response

    def initialize(options = {})
      self.host         = options[:host]
      self.port         = options[:port]
      self.scheme       = options[:scheme]
      self.path_prefix  = options[:path_prefix]
      self.username     = options[:username]
      self.password     = options[:password]
      self.token        = options[:token] if options[:token]
      self.verify_https = !options[:verify_https].nil? ? options[:verify_https] : true
    end

    extend Forwardable

    instance_delegate %i(host  port  path_prefix  scheme)  => :adapter
    instance_delegate %i(host= port= path_prefix= scheme=) => :adapter

    instance_delegate %i(get post put delete) => :adapter

    def verify_https=(verify_https)
      adapter.ssl[:verify] = verify_https
    end

    def verify_https
      adapter.ssl[:verify]
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def adapter
      @adapter ||= Faraday.new do |f|
        f.request  :multipart
        f.request  :json

        f.adapter  :net_http

        f.response :json

        # Custom Faraday Middleware parser to parse the javascript returned from the /api/ServerEnv api.
        f.use Code42::FaradayMiddleware::ParseServerEnv
      end
    end

    def has_valid_credentials?
      username && password
    end

    def token=(token)
      @token = token
      adapter.headers['Authorization-Challenge'] = "false"
      adapter.headers['Authorization'] = "TOKEN #{token}"
      @token
    end

    def mlk=(mlk)
      @mlk = mlk
      adapter.headers['C42-MasterLicenseKey'] = "BASIC #{mlk}"
      @mlk
    end

    def username=(username)
      @username = username
      adapter.basic_auth(username, password) if has_valid_credentials?
    end

    def password=(password)
      @password = password
      adapter.basic_auth(username, password) if has_valid_credentials?
    end

    def make_request(method, *args, &block)
      begin
        @last_response = response = self.send(method, *args, &block)
        ActiveSupport::Notifications.instrument('code42.request', {
          method:   method,
          args:     args,
          response: response
        })
      rescue Faraday::Error::ConnectionFailed
        raise Code42::Error::ConnectionFailed
      end
      check_for_errors(response)
      response.body
    end

    def respond_to_missing?(method_name, include_private = false)
      adapter.respond_to?(method_name, include_private) || super
    end

    private

    def check_for_errors(response)
      if response.status == 401
        raise Code42::Error::AuthenticationError.new(description_from_response(response), response.status)
      elsif response.status == 403
        raise Code42::Error::AuthorizationError.new(description_from_response(response), response.status)
      elsif response.status == 404
        raise Code42::Error::ResourceNotFound.new(description_from_response(response), response.status)
      elsif response.status >= 400 && response.status < 600
        body = response.body.is_a?(Array) ? response.body.first : response.body
        raise exception_from_body(body, response.status)
      end
    end

    def description_from_response(response)
      response.try { |resp| resp.body.try { |body| body.first['description'] } }
    end

    def exception_from_body(body, status = nil)
      return Code42::Error.new("Status: #{status}") if body.nil? || !body.has_key?('name')
      exception_name = body['name'].downcase.camelize
      if Code42::Error.const_defined?(exception_name)
        klass = Code42::Error.const_get(exception_name)
      else
        # Generic server error if no specific error is caught.
        klass = Code42::Error::ServerError
      end
      klass.new(body['description'], status)
    end

    def method_missing(method_name, *args, &block)
      return super unless adapter.respond_to?(method_name)
      adapter.send(method_name, *args, &block)
    end
  end
end
