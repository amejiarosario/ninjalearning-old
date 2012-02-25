require 'allegrograph/http_endpoint'
require 'allegrograph/repository'

module AllegroGraph

  # An AllegroGraph server.
  class Server < HttpEndpoint
    # Return the protocol version used by the server.  We currently expect
    # this to be 2.
    def protocol_version
      protocol = http_get("/protocol")
      unless protocol =~ /^\d+$/
        raise "Unexpected protocol version \"#{protocol}\" at #{@uri}"
      end
      protocol.to_i
    end

    # Return the repositories on this server.
    #
    # TODO: Return objects, not XML.
    def repositories
      raw_result = http_get("/repositories")

      # Parse our result and return it.  Note that SparqlResultParser
      # doesn't actually give us field names, so for now, we rely on the
      # order of the fields in the returned result.
      parser = SparqlResultParser.new
      REXML::Document.parse_stream(raw_result, parser)
      parser.result.map {|record| Repository.new(record[0].uri) }
    end

    # Return an object representing an existing Repository.
    def repository name
      Repository.new("#{@uri}/repositories/#{name}")
    end

    # Create a new repository with the specified name.
    def new_repository name, options = {}
      options = { :if_exists => "error" }.merge(options)
      http_post_form("/repositories",
                     { 'id' => name, 'if-exists' => options[:if_exists] })
      repository name
    end
  end

end
