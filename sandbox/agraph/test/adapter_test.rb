require File.dirname(__FILE__) + '/test_helper.rb'

# TODO - There's a lot of duplication between AdapterTest and
# RepositoryTest.  Refactor this out somehow?
class AdapterTest < Test::Unit::TestCase
  def setup
    setup_server
    setup_repository
    @adapter = AllegroGraph::Adapter.new(:repository => @repository)
  end

  def test_should_report_size_before_and_after_loading
    assert_equal 0, @repository.size
    load_example_data
    assert_expected_number_of_statements
  end

  def test_should_support_sparql_queries_and_return_objects
    load_example_data

    knows = RDFS::Resource.new("http://xmlns.com/foaf/0.1/knows")
    m = RDFS::Resource.new("http://example.org/stuff/M")
    result = @adapter.query(Query.new.select(:s).distinct.where(:s, knows, m))

    uris = result.flatten.map {|s| s.uri }
    assert uris.member?("http://example.org/stuff/Bond")
  end

  def test_should_allow_clearing_all_statements
    load_example_data
    @adapter.clear
    assert_equal 0, @adapter.size
  end

  def test_should_delete_records_matching_a_pattern
    load_example_data
    knows = RDFS::Resource.new("http://xmlns.com/foaf/0.1/knows")
    @adapter.delete nil, knows, nil
    assert_equal((expected_number_of_statements -
                  expected_number_of_knows_predicates),
                 @adapter.size)
  end

  def test_should_support_adding_a_triple_to_data_store
    load_example_data
    type = RDFS::Resource.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
    @adapter.add(RDFS::Resource.new("http://example.org/stuff/Titania"),
                 type,
                 RDFS::Resource.new("http://xmlns.com/foaf/0.1/Person"))
    assert_equal expected_number_of_statements+1, @adapter.size
  end

  def test_should_support_add_ntriples_method
    @adapter.add_ntriples(File.read(example_path("foaf.nt")))
    assert_expected_number_of_statements
  end

  # Load our example data into the repository.  Note that we can only
  # do local loads in ntriple format.
  def load_example_data
    @adapter.load(example_path('foaf.nt'))
  end

  # Make sure that we loaded the right number of statements.
  def assert_expected_number_of_statements
    assert expected_number_of_statements, @adapter.size
  end
end
