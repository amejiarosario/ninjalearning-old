require 'rubygems'
require 'test/unit'
require 'activerdf_agraph'

# Reopen the standard TestCase class and add some new methods.
class Test::Unit::TestCase
  # Set up a proxy object for our server.
  def setup_server
    @server = AllegroGraph::Server.new($server_url)
  end

  # Create a new, empty test repository, and set up a proxy object for it.
  def setup_repository
    @repository =
      @server.new_repository("ruby_agraph_test", :if_exists => "open")
    @repository.clear!
  end

  # Get the path to an example file.
  def example_path name
    File.dirname(__FILE__) + '/../examples/' + name
  end

  # The number of statements expected in foaf.nt.
  def expected_number_of_statements; 29 end

  # The number of foaf:knows predicates expected in foaf.nt.
  def expected_number_of_knows_predicates; 8 end
end

# Get a URL for our server.
def initialize_server_url
  unless ENV.has_key?('AGRAPH_URL')
    raise ("Please set the environment variable AGRAPH_URL to point to " +
             "your server's HTTP interface.  For example: " +
             "\"http://localhost:8111/sesame\".")
  end
  $server_url = ENV['AGRAPH_URL']
end

initialize_server_url
