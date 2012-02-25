# Run me as 'ruby -I../lib foaf_benchmark_client.rb http://localhost:8111/sesame'.

require 'rubygems'
require 'activerdf_agraph'
require 'benchmark'
require 'socket'

# Parse our arguments.
if ARGV.length != 1
  STDERR.puts "Usage: #{$0} <sparql server base url>"
  exit 1
end
server_url = ARGV[0]

# The number of times to run most benchmarks.
$count = 500

# Set up a repository.
serv = AllegroGraph::Server.new(server_url)
repo = serv.new_repository("ruby_foaf_benchmark", :if_exists => "open")
repo.clear!
repo.load_ntriples(File.dirname(__FILE__) + '/foaf.nt')

# Set up ActiveRDF.
ConnectionPool.add_data_source(:type => :agraph, :repository => repo)
Namespace.register :foaf, 'http://xmlns.com/foaf/0.1/'
ObjectManager.construct_classes

# Our pure Ruby server, for performance comparisons.
fake_repo_url = "http://localhost:8112/sesame/repositories/fake"
fake_repo = AllegroGraph::Repository.new(fake_repo_url)

# Run a /statements query and throw away the result.  We do no parsing.
def query_using_statements repo
  name = RDFS::Resource.new("http://xmlns.com/foaf/0.1/name")
  repo.statements(nil, name, "James Bond")
end

# Run a SPARQL query and throw away the result.  We do no parsing.
def query_using_sparql repo
  repo.query(<<EOD)
SELECT DISTINCT ?s WHERE { ?s <http://xmlns.com/foaf/0.1/name> "James Bond" . }
EOD
end

# Run our various benchmarks.
Benchmark.bm 30 do |bm|

  bm.report "ActiveRDF writes" do
    smersh = FOAF::Organization.new("http://example.org/stuff/SMERSH")
    smersh.save
    smersh.foaf::name = "Smert Spionam"
    smersh.foaf::nick = "SMERSH"
    
    tatiana = FOAF::Person.new("http://example.org/stuff/Tatiana")
    tatiana.save
    tatiana.foaf::name = "Tatiana Romanova"

    bond = FOAF::Person.find_by_foaf::name("James Bond")[0]
    
    # OK, this is a very odd way to add a new foaf::member or foaf::knows
    # relationship.  In fact, the semantics of setting values in ActiveRDF are
    # more than slightly weird.
    smersh.foaf::member = tatiana
    tatiana.foaf::knows = bond
    bond.foaf::knows = tatiana
  end

  bm.report "ActiveRDF reads" do
    FOAF::Organization.find_all.each do |org|
      org.name
      org.all_foaf::member.each do |member|
        member.name
        member.all_foaf::knows.each do |known|
          known.name
        end
      end
    end
  end

  bm.report "ActiveRDF query x #{$count} (AG)" do
    $count.times { FOAF::Person.find_by_foaf::name("James Bond") }
  end

  bm.report "Statement query x #{$count} (AG)" do
    $count.times { query_using_statements(repo) }
  end

  bm.report "Statement query x #{$count} (Ruby)" do
    $count.times { query_using_statements(fake_repo) }
  end

  bm.report "SPARQL query x #{$count} (AG)" do
    $count.times { query_using_sparql(repo) }
  end

  bm.report "SPARQL query x #{$count} (Ruby)" do
    $count.times { query_using_sparql(fake_repo) }
  end

  bm.report "Raw TCP client x #{$count} (Ruby)" do
    uri = URI.parse(fake_repo_url)
    $count.times do
      socket = TCPsocket.open(uri.host, uri.port)
      socket.write(<<EOD)
GET #{uri.path}/statements?pred=%3Chttp%3A%2F%2Fxmlns.com%2Ffoaf%2F0.1%2Fname%3E&obj=%22James%20Bond%22 HTTP/1.1
Accept: application/rdf+ntriples

EOD
      socket.read
      socket.close
    end
  end

  bm.report "Parse XML x #{$count} (Ruby)" do
    $count.times do
      parser = SparqlResultParser.new
      REXML::Document.parse_stream(<<EOD, parser)
<?xml version="1.0"?>
<sparql xmlns="http://www.w3.org/2005/sparql-results#">
  <head>
    <variable name="s"/>
  </head>
  <results ordered="false" distinct="false">
    <result>
      <binding name="s">
        <uri>http://example.org/stuff/Bond</uri>
      </binding>
    </result>
  </results>
</sparql>
EOD
    end
  end
end
