# Run me as 'ruby -I../lib foaf.rb http://localhost:8111/sesame'.

require 'rubygems'
require 'activerdf_agraph'

# Parse our arguments.
if ARGV.length != 1
  STDERR.puts "Usage: #{$0} <sparql server base url>"
  exit 1
end
server_url = ARGV[0]

#--------------------------------------------------------------------------
#  Direct AllegroGraph access, without going through ActiveRDF.

# Build a connection to the server, create a database, and make sure it's
# empty.
serv = AllegroGraph::Server.new(server_url)
repo = serv.new_repository("ruby_foaf_example", :if_exists => "open")
repo.clear!

# Load some data into our repository.
puts "Loading RDF data..."
repo.load_ntriples(File.dirname(__FILE__) + '/foaf.nt')
puts "#{repo.size} tuples loaded"

#--------------------------------------------------------------------------
#  Setting up ActiveRDF.  We need to tell it where to find data, and we
#  need to set up some namespaces.

# OK, now we can create a SPARQL connection and query our repository.
ConnectionPool.add_data_source(:type => :agraph, :repository => repo)

# Create a FOAF namespace.
Namespace.register :foaf, 'http://xmlns.com/foaf/0.1/'
ObjectManager.construct_classes

#--------------------------------------------------------------------------
#  Using the RDF object mapper.  Note that this won't work unless we have
#  a reasonable amount of schema data loaded in our repository (which we
#  loaded as part of our FOAF file).

puts "Adding new triples to data store from Ruby..."

smersh = FOAF::Organization.new("http://example.org/stuff/SMERSH")
smersh.save
smersh.foaf::name = "Smert Spionam" # How can we get UTF-8 working?
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

# Dump a complete table of organization membership.
FOAF::Organization.find_all.each do |org|
  puts "Members of #{org.name}:"
  org.all_foaf::member.each do |member|
    puts "  #{member.name}"
    member.all_foaf::knows.each do |known|
      puts "    knows #{known.name}"
    end
  end
end

