require 'net/http'
require 'allegrograph/server_error'

module AllegroGraph

  # An Http endpoint has a base URI and a variety of protected methods
  # which can be used to build requests.  This is the common superclass of
  # Server and Repository.
  class HttpEndpoint
    # Create a new endpoint pointing to +uri+.
    def initialize uri
      @uri = uri
    end

    # Allow access to the URI of the this HTTP endpoint.
    attr_reader :uri

    protected

    # Characters which we don't need to escape in HTTP query strings.
    UNESCAPED_CHARACTERS = Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")

    # Turn a hash table into an HTTP query string.
    #
    # TODO: Isn't there are standard Ruby library to do this somewhere?
    def build_query_string arguments
      arguments.reject do |key, value|
        value.nil?
      end.map do |key,value|
        "#{key}=#{URI.escape(value, UNESCAPED_CHARACTERS)}"
      end.join('&')
    end

    # Construct a URI and parse it into a URI object, optionally including
    # query arguments.
    def build_uri path, arguments = {}
      # Build our query string.
      query =
        if arguments.empty?
          ""
        else
          "?#{build_query_string(arguments)}"
        end

      # Build and parse the actual URI.
      URI.parse("#{@uri}#{path}#{query}")
    end

    # Given a parsed +uri+, rebuild the path+query part we need to hand to
    # the HTTP server.
    def path_and_query uri
      if uri.query
        "#{uri.path}?#{uri.query}"
      else
        uri.path
      end
    end

    # Send an HTTP GET request to our server.
    def http_get path, arguments = {}, headers = {}
      uri = build_uri(path, arguments)
      http_request(uri, Net::HTTP::Get.new(path_and_query(uri), headers))
    end

    # Send an HTTP POST request to the server.
    def http_post path, body, headers = {}
      uri = build_uri(path)
      req = Net::HTTP::Post.new(uri.path, headers)
      req.body = body
      http_request(uri, req)
    end

    # Send an HTTP POST request to our server, encoding +arguments+ as form
    # arguments.
    def http_post_form path, arguments = {}, headers = {}
      defaults = { 'Content-Type' => 'application/x-www-form-urlencoded' }
      headers = defaults.merge(headers)
      http_post(path, build_query_string(arguments), headers)
    end

    # Make an HTTP request and handle the response.
    def http_request uri, request
      # Send the request.  We do this the long way, with explicit request
      # and response objects, because we want a lot of control over headers
      # and other details.
      response = Net::HTTP.start(uri.host, uri.port) do |http|
        http.request(request)
      end

      # Process the response.
      case response
      when Net::HTTPSuccess
        # We're OK.
      when Net::HTTPRedirection
        # We really ought to handle this with a restricted-depth recursive
        # call.  See the Net::HTTP documentation for an example.
        raise "URI redirection not yet implemented (#{uri})"
      when Net::HTTPBadRequest
        # Most internal AllegroGraph errors seem to be returned like this,
        # so extract the error string and throw a nice, tidy exception.
        raise ServerError.new(response.body)
      else
        # We have some other sort of error at the HTTP level, so just raise
        # it normally.
        #STDERR.puts "AllegroGraph HTTP error: #{response.body}"
        response.error!
      end

      # Return the body of the response.
      response.body
    end
  end

end

