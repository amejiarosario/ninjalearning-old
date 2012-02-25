# AllegroGraph Endpoint connection
# 

require 'allegro_graph'
require 'linkeddata'
require 'set'
require './config'

class AGraph
  attr_accessor :username, :password, :host, :port
  
  #
  # Constructor
  # 
  def initialize(user,pass,host,port)
    @username = user
    @password = pass
    @host = host
    @port = port
    @server = AllegroGraph::Server.new :username => @username, :password => @password, :host => @host, :port => @port
  end
  
  #
  # Setter for allegro Graph repository
  #
  def repository(repositoryName='test_repo')
    @repository = AllegroGraph::Repository.new @server, repositoryName
    @repository.create_if_missing!
  end
  
  #
  # Setter for allegro Graph repository
  #
  def repository=(repositoryName)
    repository repositoryName
  end
  
  #
  # Return a RDF::Graph with the whole repo.
  #
  def get_repo (repoName='test_repo')
    puts "get_repo"
    repository repoName
    puts "set_repository #{@repository}"
    result = @repository.query.perform "select ?s ?p ?o {?s ?p ?o} order by ?s"
    #puts "@repository.query.perform #{result}"
    
    graph = RDF::Graph.new(repoName) # TODO: repo name, host, port, ...
    
    result['values'].each do |triple|
      graph << RDF::Statement.new(
        # FIXME: not all triples are RDF::URI, they also can be: RDF::Literal and RDF:Node
        # RDF::Node => "<_:g2178284620>"
        # RDF::Literal => "\"Motorola - Refurbished XOOM Family Edition Tablet with 16GB Memory - Licorice\"@en-us"
        RDF::URI.new(triple[0]),
        RDF::URI.new(triple[1]),
        RDF::URI.new(triple[2]),
      )
    end
    graph
  end
  
  ##
  # Get classes and subclasses
  def get_terms(repositoryName='ComputerScience_test')
    repo = set_repository(repositoryName)
    
    # SparQL queries
    @repository.query.language = :sparql
    res = @repository.query.perform "SELECT distinct ?Class ?Subclass WHERE { ?Subclass rdfs:subClassOf ?Class . } Order by ?Class "
    terms = Set.new
    # I know this could be done more efficiently...
    res['values'].each do |pair|
      terms.add(pair[0])
      terms.add(pair[1]) 
    end
    terms    
  end
  
  #
  # Add a RDF::Statement (triple/quad) 
  # (no support for quad. Very easy to add though.)
  #
  def add (triple)
    
    #@repository.transaction do
      #triples.each do |triple|
        puts "@repository.statements.create #{triples[0]}, #{triples[1]}, #{triples[2]}"
        @repository.statements.create triples[0], triples[1], triples[2]
      #end
    #end
    
  end
  
  #
  # Insert RDF::Graph into the Allegro repositoy
  # Sadly, @repository.transaction timeout, so no transactions.
  #
  def insert(graph)    
    graph.each_triple do |s, p, o|
      @repository.statements.create pt(s), pt(p), pt(o)
    end
  end
  
  #
  # Prepare triple. Serialize a triple with a N-Triple format
  #
  def pt(triple)
    if triple.literal?
      s = "\"#{escape(triple)}\""
      s += "@#{escape(triple.language)}" if triple.language?
      return s
    else
      return "<#{escape(triple)}>"
    end
     #when iri? # when node?
  end
  
  #
  # escape double quoutes
  #
  def escape(triple)
    s = triple.to_s.gsub(/\"/,"\\\"")
    s
  end
  
end

=begin
# test
ag = AGraph.new($AGRAPH['user'],$AGRAPH['pass'],$AGRAPH['host'],$AGRAPH['port'])
ag.repository = "bestbuy_test"

graph = RDF::Graph.new
graph << RDF::RDFa::Reader.open("http://www.bestbuy.com/shop/ipad+xoom")
puts graph.statements.count
ag.insert(graph)

=end