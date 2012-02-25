require 'active_rdf'
require 'active_rdf/queryengine/ntriples_parser'
require 'allegrograph/http_endpoint'

# Make sure we have a version of XML::Builder in the 2.x series.  The old
# 1.x series didn't escape attributes, and using it with our code below
# would cause some fairly serious security problems.
require 'rubygems'
gem 'builder', '~> 2.0'
require 'builder'

module AllegroGraph

  # An AllegroGraph repository.
  class Repository < HttpEndpoint
    # Get the size of this repository.
    def size
      sz = http_get('/size')
      unless sz =~ /^\d+$/
        raise "Unexpected repository size \"#{sz}\" at #{@uri}"
      end
      sz.to_i
    end
    
    # Submit a raw RDF-update transaction to this repository.  Normal
    # users will probably prefer using the +transaction+ method instead.
    def raw_transaction xml
      http_post('/statements', xml,
                { 'Content-Type' => 'application/x-rdftransaction' })      
    end

    # Create and run an RDF-update transaction using Builder's
    # XML-generation tools.  An example:
    #
    #   repo.transaction do |trans|
    #     trans.clear
    #   end
    def transaction
      builder = Builder::XmlMarkup.new
      xml = builder.transaction {|trans| yield trans }
      #puts "Transaction: #{xml}"
      raw_transaction(xml)
    end

    # Clear the repository.
    def clear!
      raw_transaction('<transaction><clear /></transaction>')
    end

    # Delete matching triples from the repository.
    def remove! subj = nil, pred = nil, obj = nil
      transaction do |trans|
        trans.remove do
          [subj, pred, obj].each {|item| add_to_trans(trans, item) }
        end
      end
    end

    # Add a list of triples to the repository.
    def add! triples
      transaction do |trans|
        triples.each do |subj, pred, obj|
          trans.add do
            [subj, pred, obj].each {|item| add_to_trans(trans, item) }
          end
        end
      end
    end

    # Load a file in ntriples format.
    #
    # TODO: We'll need a more complete set of load functions, with better
    # names.
    def load_ntriples file
      add_ntriples(File.read(file))
    end

    # Load a string in ntriples format into the repository.
    def add_ntriples data
      ntriples = NTriplesParser.parse(data.split(/\r?\n/))
      add!(ntriples)
    end

    # Load a URI in ntriples format into the repository.
    def load_ntriples_uri uri
      http_post_form('/load', 'ntriple' => uri)
    end

    # Load a URI in RDF format directly into the repository.
    def load_rdf_uri uri
      http_post_form('/load', 'rdf' => uri)
    end

    # Fetch all the matching RDF statements in this repository.
    def statements subj=nil, pred=nil, obj=nil
      args = { :subj => subj, :pred => pred, :obj => obj }
      args.each do |k,v|
        case
        when v.nil?
          args.delete(k)
        when v.respond_to?(:uri)
          args[k] = "<#{v.uri}>"
        else
          args[k] = v.to_s.inspect
        end
      end
      http_get('/statements', args,
               { 'Accept' => 'application/rdf+ntriples' })
    end

    # Run a query against this repository.  Options include:
    #
    # +:language+:: The language to use for the query.  Defaults to SPARQL.
    def query query, options = {}
      options = { :language => 'SPARQL' }.merge(options)
      http_get("",
               { 'queryLn' => options[:language],
                 'query' => query },
               { 'Accept' => 'application/sparql-results+xml' })
    end

    # Update the index.  We clearly need to add more options here, but I'm
    # not sure what they might be.
    def index!
      http_get('/index', 'index' => 'all')
    end

    # Flush all changes back to the repository.  Does nothing, at least for
    # now.
    def flush
      # Does nothing, for now.
    end

    # Declare _uri_ to be an rdfs::Class, and a subclass of _parent_uri_.
    # This is a temporary helper method to make example code look nicer
    # until we design something better.
    def define_class(uri,
                     parent_uri =
                       "http://www\.w3\.org/1999/02/22-rdf-syntax-ns#Resource")
      type =
        RDFS::Resource.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
      klass = RDFS::Resource.new("http://www.w3.org/2000/01/rdf-schema#Class")
      subclass_of =
        RDFS::Resource.new("http://www.w3.org/2000/01/rdf-schema#subClassOf")
      add!([[RDFS::Resource.new(uri), type, klass],
            [RDFS::Resource.new(uri), subclass_of,
             RDFS::Resource.new(parent_uri)]])
    end

    private
    
    # Add a value to a transaction.
    def add_to_trans trans, value
      if value.nil?
        trans.null
      elsif value.respond_to?(:uri)
        # XXX - AllegroGraph bug: We need to put an extra set of
        # brackets around the URI, or AllergroGraph will get
        # confused.  The engineers at Franz say that this is probably
        # not the way AllegroGraph should work.
        trans.uri("<#{value.uri}>")
      else
        trans.literal(value.to_s)
      end
    end
  end

end
