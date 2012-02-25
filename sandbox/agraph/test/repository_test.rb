require File.dirname(__FILE__) + '/test_helper.rb'

class RepositoryTest < Test::Unit::TestCase
  def setup
    setup_server
    setup_repository
  end

  def test_should_report_the_number_of_statements_it_contains
    assert_equal 0, @repository.size
    load_example_data
    assert_expected_number_of_statements
  end

  def test_should_support_loading_local_ntriple_data_from_file
    load_example_data
    assert_expected_number_of_statements
  end

  def test_should_support_loading_local_ntriple_data_from_string
    @repository.add_ntriples(File.read(example_path('foaf.nt')))
    assert_expected_number_of_statements
  end

  def test_should_contain_no_records_after_clear_is_called
    load_example_data
    @repository.clear!
    assert_equal 0, @repository.size
  end
  
  def test_should_allow_statements_to_be_removed
    # Remove everything in one go.
    load_example_data
    @repository.remove! nil, nil, nil
    assert_equal 0, @repository.size

    # Remove all foaf:knows relationships.
    load_example_data
    knows = RDFS::Resource.new("http://xmlns.com/foaf/0.1/knows")
    @repository.remove! nil, knows, nil
    assert_equal((expected_number_of_statements -
                  expected_number_of_knows_predicates),
                 @repository.size)
  end

  def test_should_support_simple_statement_queries
    load_example_data
    name = RDFS::Resource.new("http://xmlns.com/foaf/0.1/name")
    result = @repository.statements nil, name, "James Bond"
    assert_match /Bond/, result
  end
  
  def test_should_support_sparql_queries
    load_example_data
    result = @repository.query(<<EOD)
SELECT ?o WHERE {
  <http://example.org/stuff/HMSS> <http://xmlns.com/foaf/0.1/member> ?o .
}
EOD
    assert_match /Bond/, result
  end

  def test_should_support_prolog_queries
    load_example_data
    result = @repository.query(<<EOQ, :language => 'Prolog')
(?o) (q !<http://example.org/stuff/HMSS> !<http://xmlns.com/foaf/0.1/member> ?o)
EOQ
    assert_match /Bond/, result
  end

  def test_should_support_indexing
    @repository.index!
  end

  def test_should_have_a_flush_method
    @repository.flush
  end

  def test_should_allow_classes_to_be_defined
    @repository.define_class('http://example.org/A')
    @repository.define_class('http://example.org/B', 'http://example.org/A')
    isa = @repository.query(<<EOQ)
SELECT ?s WHERE {
  ?s <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2000/01/rdf-schema#Class>
}
EOQ
    assert_match(%r"http://example\.org/A", isa)
    assert_match(%r"http://example\.org/B", isa)

    assert_subclass("http://example\.org/A",
                    "http://www\.w3\.org/1999/02/22-rdf-syntax-ns#Resource")
    assert_subclass("http://example\.org/B", "http://example\.org/A")
  end

  def assert_subclass klass, parent
    result = @repository.query(<<EOQ)
SELECT ?o WHERE {
  <#{klass}> <http://www.w3.org/2000/01/rdf-schema#subClassOf> ?o
}
EOQ
    assert_match(Regexp.new(Regexp.escape(parent)), result)
  end

  # TODO - Not yet tested:
  #   test_should_return_a_list_of_all_statements_it_contains
  #   test_should_support_loading_ntriples_data_from_a_url

  # Load some example data into our repository.
  def load_example_data
    @repository.load_ntriples(example_path('foaf.nt'))
  end

  # Make sure we have the right number of statements in the repository.
  def assert_expected_number_of_statements
    assert_equal expected_number_of_statements, @repository.size
  end
end
