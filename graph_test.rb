require 'test/unit'
require './graph.rb'
require './actor_node.rb'
require './movie_node.rb'
require './adjacent_node.rb'
require 'active_support/core_ext/enumerable.rb'

class GraphTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @actor1 = ActorNode.new("John Jim")
    @actor1.age = 20
    @actor2 = ActorNode.new("Fred Ward")
    @actor2.age = 30
    @movie1 = MovieNode.new("Creeper")
    @movie1.box_office = 100000
    @movie1.year = 2000
    @graph = Graph.new
    @graph.add_actor_node(@actor1)
    @graph.add_actor_node(@actor2)
    @graph.add_movie_node(@movie1)
    @actor1.adjacency_list << AdjacentNode.new(@movie1, 60000)
    @movie1.adjacency_list << AdjacentNode.new(@actor1, 60000)
    @actor2.adjacency_list << AdjacentNode.new(@movie1, 40000)
    @movie1.adjacency_list << AdjacentNode.new(@actor2, 40000)
  end

  def test_boolean_methods
    assert @graph.is_actor_node_in_graph(@actor1.name)
    assert @graph.is_actor_node_in_graph(@actor2.name)
    assert !@graph.is_actor_node_in_graph("Bon Jovi")
  end

  def test_get_methods
    assert_equal @actor1, @graph.get_actor_node(@actor1.name)
    assert_equal @actor2, @graph.get_actor_node(@actor2.name)
    assert_not_equal @actor1, @graph.get_actor_node("john")
    assert_not_equal @actor1, @graph.get_actor_node(@actor2.name)
  end

  def test_queries
    # 1. Find how much a movie has grossed
    assert_equal @movie1.box_office, @graph.get_box_office_amount(@movie1.name)
    # 2. List which movies an actor has worked in
    movies = @graph.get_movies_containing_actor(@actor1.name)
    assert movies.include? @movie1.name
    assert movies.exclude? "James Bond"
    # 3. List which actors worked in a movie
    actors = @graph.get_actors_in_movie(@movie1.name)
    assert actors.include? @actor1.name
    assert actors.include? @actor2.name
    assert actors.exclude? "Johnny Bravo"
    # 4. List the top X actors with the most total grossing value
    top_grossing = @graph.get_top_grossing_actors(1)
    assert top_grossing.include? @actor1.name
    assert top_grossing.exclude? @actor2.name
    # 5. List the oldest X actors
    oldest = @graph.get_oldest_actors(1)
    assert oldest.exclude? @actor1.name
    assert oldest.include? @actor2.name
    # 6. List all the movies for a given year
    movies_for_year = @graph.get_movies_for_year(2000)
    assert movies_for_year.include? @movie1.name
    assert movies_for_year.exclude? "Sharknado"
    # 7. List all the actors for a given year
    actors_for_year = @graph.get_actors_for_year(2000)
    assert actors_for_year.include? @actor1.name
    assert actors_for_year.include? @actor2.name
    assert actors_for_year.exclude? "Jim Bone"
  end

  def test_delete
    @graph.delete_movie_node(@movie1.name)
    assert @graph.movie_nodes.exclude? @movie1
    @graph.delete_actor_node(@actor1.name)
    assert @graph.actor_nodes.exclude? @actor1
  end
end