require File.dirname(__FILE__) + '/test_helper.rb'

class ServerTest < Test::Unit::TestCase
  def setup
    setup_server
  end

  def test_should_report_protocol_version
    assert_equal 2, @server.protocol_version
  end

  def test_should_return_list_of_repositories
    setup_repository
    repos = @server.repositories
    repos.each {|r| assert_instance_of AllegroGraph::Repository, r }

    # Make sure that our test repository appears in the list.
    assert(repos.map {|r| r.uri }.member?(@repository.uri))
  end
  
  def test_should_provide_access_to_existing_repositories
    setup_repository
    repo = @server.repository('ruby_agraph_test')
    assert_equal @repository.uri, repo.uri
  end

  def test_should_allow_creation_of_new_repository
    # Either open an existing repository, or create it if it doesn't exist.
    repo = @server.new_repository('ruby_agraph_test', :if_exists => 'open')
    assert_working_repo repo, 'ruby_agraph_test'

    # Fail with an error, because the repository already exists.
    assert_raise AllegroGraph::ServerError do
      @server.new_repository('ruby_agraph_test')
    end

    # There's also an :if_exists => "supersede" option, but I'm not sure
    # exactly what it's supposed to do.  So no tests for now.
  end

  # Make sure we have an actual, working repository at the correct address.
  def assert_working_repo repo, expected_id
    assert_equal "#{$server_url}/repositories/#{expected_id}", repo.uri
    repo.clear!
    assert_equal 0, repo.size
  end
end
