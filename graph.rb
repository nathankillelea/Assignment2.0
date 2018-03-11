# Sources:
# https://ex0ns.me/2015/01/30/-ruby-graph-representation/
# http://billleidy.com/blog/advent-of-code-and-graph-data-structure.html
# https://www.geeksforgeeks.org/graph-and-its-representations/
# https://github.com/brianstorti/ruby-graph-algorithms/blob/master/dijkstra/graph.rb
# https://stackoverflow.com/questions/9459447/finding-n-keys-with-highest-value-in-hash-keeping-order

class Graph
  attr_accessor :actor_nodes, :movie_nodes

  # This is the constructor for the Graph class.
  def initialize
    @actor_nodes = []
    @movie_nodes = []
  end

  # This function converts the graph to a hash.
  def to_hash
    {
        actor_nodes: @actor_nodes,
        movie_nodes: @movie_nodes
    }
  end

  # This function adds an actor node into the graph.
  # @param node The node to be added into the graph
  def add_actor_node(node)
    actor_nodes << node
  end

  # This function adds a movie node into the graph.
  # @param node The node to be added into the graph
  def add_movie_node(node)
    movie_nodes << node
  end

  # This function checks whether the actor node is in the graph.
  # @param name The name of the node to be searched
  # @return [Boolean] This returns true if the node is in the graph and false if not.
  def is_actor_node_in_graph(name)
    actor_nodes.each { |node| (if node.name == name then return true end)}
    return false
  end

  # This function checks whether the movie node is in the graph.
  # @param name The name of the node to be searched
  # @return [Boolean] This returns true if the node is in the graph and false if not.
  def is_movie_node_in_graph(name)
    movie_nodes.each { |node| (if node.name == name then return true end)}
    return false
  end

  # This function gets the actor node for a given name.
  # @param name The name of the actor to be retrieved
  # @return [ActorNode] This returns the actor node corresponding to the given name.
  def get_actor_node(name)
    actor_nodes.each { |node| (if node.name == name then return node end)}
  end

  # This function gets the movie node for a given name.
  # @param name The name of the movie to be retrieved.
  # @return [MovieNode] This returns the movie node corresponding to the given name.
  def get_movie_node(name)
    movie_nodes.each { |node| (if node.name == name then return node end)}
  end

  # This function deletes a movie node and all references from actors to it.
  # @param name The name of the movie to be removed.
  def delete_movie_node(name)
    movie_node = get_movie_node(name)
    movie_node.adjacency_list.each do |actor_adj_node|
      actor_adj_node.node.adjacency_list.each do |movie_adj_node|
        if movie_adj_node.node == movie_node
          actor_adj_node.node.adjacency_list.delete(movie_adj_node)
        end
      end
    end
    movie_nodes.delete(movie_node)
  end

  # This function deletes an actor node and all references from movies to it.
  # @param name The name of the actor to be removed.
  def delete_actor_node(name)
    actor_node = get_actor_node(name)
    actor_node.adjacency_list.each do |movie_adj_node|
      movie_adj_node.node.adjacency_list.each do |actor_adj_node|
        if actor_adj_node.node == actor_node
          movie_adj_node.node.adjacency_list.delete(actor_adj_node)
        end
      end
    end
    actor_nodes.delete(actor_node)
  end

  # This function gets the box office amount for a given movie.
  # @param name The name of the movie to find the box office amount for
  # @return [Float] This returns the box office amount corresponding to the given name.
  def get_box_office_amount(name)
    movie_nodes.each{ |node| (if node.name == name then return node.box_office end) }
  end

  # This function gets the movies containing the given actor.
  # @param name The name of the actor
  # @return [[String]] This returns an array of the movies containing an actor.
  def get_movies_containing_actor(name)
    actor_node = get_actor_node(name)
    if(actor_node != nil)
      movies_containing_actor = []
      actor_node.adjacency_list.each { |movie_adj_node| movies_containing_actor << movie_adj_node.node.name}
      return movies_containing_actor
    end
  end

  # This function gets the actors starring in the given movie.
  # @param name The name of the movie
  # @return [[String]] This returns an array of the actors starring in a movie.
  def get_actors_in_movie(name)
    movie_node = get_movie_node(name)
    if(movie_node != nil)
      actors_in_movie = []
      movie_node.adjacency_list.each { |actor_adj_node| actors_in_movie << actor_adj_node.node.name}
      return actors_in_movie
    end
  end

  # This function gets the top X grossing actors.
  # @param amount The number of actors to get
  # @return [[String]] This returns an array of length amount containing the top grossing actors.
  def get_top_grossing_actors(amount)
    sorted_by_grossing = actor_nodes.sort_by { |actor_node| actor_node.total_grossing_value }.reverse
    top_grossing_actors = []
    for i in 0..amount-1
      top_grossing_actors[i] = sorted_by_grossing[i].name
    end
    return top_grossing_actors
  end

  # This function gets the top X oldest actors.
  # @param amount The number of actors to get
  # @return [[String]] This returns an array of length amount containing the oldest actors.
  def get_oldest_actors(amount)
    sorted_by_age = actor_nodes.sort_by { |actor_node| actor_node.age }.reverse
    oldest_actors = []
    for i in 0..amount-1
      oldest_actors[i] = sorted_by_age[i].name
    end
    return oldest_actors
  end

  # This function gets all movies for a given year.
  # @param year The given year
  # @return [[String]] This returns an array of the movies for a given year.
  def get_movies_for_year(year)
    movies = []
    movie_nodes.each{ |movie_node| (if movie_node.year == year then movies << movie_node.name end) }
    return movies
  end

  # This function gets all actors that starred in a movie in a given year.
  # @param year The given year
  # @return [[String]] This returns an array of the actors that starred in a movie in a given year.
  def get_actors_for_year(year) # make sure this works
    actors_for_year = []
    movies = get_movies_for_year(year)
    movie_nodes_subset = []
    movies.each { |movie| movie_nodes_subset << get_movie_node(movie) }
    movie_nodes_subset.each do |movie_node|
      movie_node.adjacency_list.each do |actor_adj_node|
        actors_for_year << actor_adj_node.node.name
      end
    end
    actors_for_year.uniq
  end
end