require 'active_rdf'
require 'queryengine/query2sparql'
require 'activerdf_sparql/sparql_result_parser'

module AllegroGraph

  # This is an ActiveRDF adapter which connects to AllegroGraph databases
  # using HTTP.  For a more-extensive API, see AllegroGraph::Server and
  # AllegroGraph::Repository.
  #
  # This code is inspired by the original +activerdf_sparql+ module,
  # which we actually call for parsing SPARQL query result sets.
  class Adapter < ActiveRdfAdapter
    # Make sure we get properly registered with ActiveRDF.
    ConnectionPool.register_adapter(:agraph, self)
    
    # Create a new adapter.  Options include:
    #
    # +:url+:: The URL to the repository.  Specify either this, or
    #   +:repository+ below.
    # +:repository+:: An already-constructed repository object.
    def initialize options = {}
      @reads = true
      @writes = true
      @repository = (options[:repository] ||
                     AllegroGraph::Repository.new(options[:url]))
    end
    
    # Return the size of the repository.
    def size
      @repository.size
    end
    
    # Execute an ActiveRDF query against the repository.
    def query query
      # Translate our query from ActiveRDF to SPARQL format and run it.
      query_str = Query2SPARQL.translate(query)
      #puts "Query: #{query_str}"
      raw_result = @repository.query(query_str)
      #puts "Raw: #{raw_result}"

      # Parse our result and return it.
      parser = SparqlResultParser.new
      REXML::Document.parse_stream(raw_result, parser)
      #puts "Found: #{parser.result.inspect}"
      parser.result
    end
    
    # Clear all RDF triples from the repository.  Be careful!
    def clear
      @repository.clear!
    end

    # Delete all triples matching the specified +subj+, +pred+ and +obj+.
    # The value +nil+ is treated as a wild card that will match anything.
    def delete subj=nil, pred=nil, obj=nil
      @repository.remove! subj, pred, obj
    end

    # Add a triple to the repository.  +subj+ and +pred+ must both be
    # RDFS::Resource values; +obj+ may be either a resource or a literal
    # value.
    def add subj, pred, obj
      @repository.add!([[subj, pred, obj]])
    end

    # Load a file in ntriple format into the repository.
    def load ntriple_file
      @repository.load_ntriples(ntriple_file)
    end

    # TODO - This is a useless placeholder method which we should remove.
    def add_ntriples ntriple_data
      @repository.add_ntriples ntriple_data
    end

    # Flush all changes back to the repository.  For now, this function
    # does nothing, because we flush all changes as they occur.
    def flush
      true
    end
  end
  
end

