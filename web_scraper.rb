# Sources:
# http://www.nokogiri.org/tutorials/parsing_an_html_xml_document.html
# https://stackoverflow.com/questions/46579397/using-rubys-nokogiri-to-scrape-specific-part-of-wikipedia
# https://stackoverflow.com/questions/46628719/how-to-retrieve-gross-information-from-a-wikipedia-movie-page-with-nokogiri-rub
# https://stackoverflow.com/questions/1474688/nokogiri-how-to-select-nodes-by-matching-text?rq=1
# https://stackoverflow.com/questions/39653384/how-to-extract-links-and-link-text-from-html-using-nokogiri
# https://chatbotslife.com/how-to-convert-human-readable-number-to-float-in-ruby-5b4c12375c4a
# https://stackoverflow.com/questions/1708504/how-do-i-remove-a-node-with-nokogiri
# https://stackoverflow.com/questions/819263/get-persons-age-in-ruby
# https://stackoverflow.com/questions/31767864/converting-an-array-of-objects-to-json-in-ruby
# https://www.thoughtco.com/making-deep-copies-in-ruby-2907749

require 'open-uri'
require 'rubygems'
require 'nokogiri'
require 'logger'
require 'json'
require 'ostruct'
require 'active_support/core_ext/enumerable.rb'
require './graph.rb'
require './actor_node.rb'
require './movie_node.rb'
require './adjacent_node.rb'

class WebScraper

  @total_actors_left = 250 # 250
  @total_movies_left = 125 # 125
  File.delete('log.txt')
  @logger = Logger.new('log.txt')
  @actor_queue = Array.new
  @movie_queue = Array.new
  @actor_links = Array.new
  @movie_links = Array.new
  @completed_actors = Array.new
  @completed_movies = Array.new
  @completed_actor_links = Array.new
  @completed_movie_links = Array.new
  @graph = Graph.new

  # This function runs the scraper until the number of actors and movies are met or until both queues are empty.
  # @param starting_actor The name of the starting actor
  # @param starting_actor_link The shorthand URL of the starting actor
  def self.main(starting_actor, starting_actor_link)
    scrape_actor_page(starting_actor, starting_actor_link)
    @completed_actors << starting_actor
    @completed_actor_links << starting_actor_link

    prng = Random.new

    until (@total_actors_left <= 0 and @total_movies_left <= 0) or (@actor_queue.empty? and @movie_queue.empty?)
      until @movie_queue.empty? or (@total_movies_left <= 0)
        @logger.debug "Movies left: #{@total_movies_left}"
        @logger.debug "Actors left: #{@total_actors_left}"
        @logger.debug "#{@movie_queue}"
        @logger.debug "#{@movie_links}"
        sleep prng.rand(0.125)
        @completed_movies << @movie_queue.first
        @completed_movie_links << @movie_links.first
        scrape_movie_page(@movie_queue.shift, @movie_links.shift)
      end
      until @actor_queue.empty?
        @logger.debug "Movies left: #{@total_movies_left}"
        @logger.debug "Actors left: #{@total_actors_left}"
        @logger.debug "#{@actor_queue}"
        @logger.debug "#{@actor_links}"
        sleep prng.rand(0.125)
        @completed_actors << @actor_queue.first
        @completed_actor_links << @actor_links.first
        scrape_actor_page(@actor_queue.shift, @actor_links.shift)
      end
    end

    until @movie_queue.empty?
      @graph.delete_movie_node(@movie_queue.shift)
    end

    add_weights
    add_total_grossing_for_actors
    graph_to_json(@graph, 'graph.json')

    @logger.info "1. Find how much a movie has grossed"
    @logger.info @graph.get_box_office_amount("Marie")
    @logger.info "2. List which movies an actor has worked in"
    @logger.info @graph.get_movies_containing_actor("Morgan Freeman")
    @logger.info"3. List which actors worked in a movie"
    @logger.info @graph.get_actors_in_movie("Glory")
    @logger.info "4. List the top X actors with the most total grossing value"
    @logger.info @graph.get_top_grossing_actors(4)
    @logger.info "5. List the oldest X actors"
    @logger.info @graph.get_oldest_actors(5)
    @logger.info "6. List all the movies for a given year"
    @logger.info @graph.get_movies_for_year(1989)
    @logger.info "7. List all the actors for a given year"
    @logger.info @graph.get_actors_for_year(1989)
  end

  # This function scrapes the movie's page.
  # @param movie The name of the movie
  # @param movie_link The shorthand URL of the movie's page
  def self.scrape_movie_page(movie, movie_link)
    begin
      @logger.info "Scraping #{movie_link}"
      doc = Nokogiri::HTML(open("https://en.wikipedia.org" + movie_link))
      infobox = doc.at_css('.infobox')
      infobox.search('sup').each { |src| src.remove }
      box_office = infobox.at('th:contains("Box office")').next_element.text.delete('$,US')
      @logger.debug "Human-readable Box Office: #{box_office}"
      box_office = human_to_number(box_office)
      year = Date.parse(doc.at_css('.bday').text).year
      starring = infobox.at('th:contains("Starring")').next_element
      cast = starring.css('a').map(&:text)
      cast_links = starring.css('a[href]').map{ |element| element["href"] }
    rescue
      @logger.error "#{movie_link} could not be scraped"
      if @graph.is_movie_node_in_graph(movie)
        @graph.delete_movie_node(movie)
      end
    else
      @total_movies_left = @total_movies_left - 1
      @logger.info "Box Office: #{box_office}"
      @logger.info "Year: #{year}"
      if !@graph.is_movie_node_in_graph(movie)
        @graph.add_movie_node(movie_node = MovieNode.new(movie))
      else
        movie_node = @graph.get_movie_node(movie)
      end
      movie_node.box_office = box_office
      movie_node.year = year
      for i in 0..cast.length-1
        if @completed_actors.exclude? cast[i] and @actor_queue.exclude? cast[i]
          @actor_links << cast_links[i]
          @actor_queue << cast[i]
          @graph.add_actor_node(actor_node = ActorNode.new(cast[i]))
          actor_node.adjacency_list << AdjacentNode.new(movie_node)
          movie_node.adjacency_list << AdjacentNode.new(actor_node)
        end
      end
    end
  end

  def self.scrape_box_office(doc)
    box_office = doc.at('th:contains("Box office")').next_element.text.delete('$,US')
    @logger.debug "Human-readable Box Office: #{box_office}"
    box_office = human_to_number(box_office)
  end

  # This function scrapes the actor's page.
  # @param actor The name of the actor
  # @param actor_link The shorthand URL of the actor's page
  def self.scrape_actor_page(actor, actor_link)
    begin
      @logger.info "Scraping #{actor_link}"
      doc = Nokogiri::HTML(open("https://en.wikipedia.org" + actor_link))
      doc.search('sup').each { |src| src.remove }
      age = age(Date.parse(doc.at_css('.bday').text))
      filmography = doc.at_css('#Filmography').parent.next_element.next_element
      films = filmography.css('i a').map(&:text)
      film_links = filmography.css('i a').map{ |element| element["href"] }
    rescue
      @logger.error "#{actor_link} could not be scraped"
      if @graph.is_actor_node_in_graph(actor)
        @graph.delete_actor_node(actor)
      end
    else
      @total_actors_left = @total_actors_left - 1
      @logger.info "Age: #{age}"
      if !@graph.is_actor_node_in_graph(actor)
        @graph.add_actor_node(actor_node = ActorNode.new(actor))
      else
        actor_node = @graph.get_actor_node(actor)
      end
      actor_node.age = age
      for i in 0..films.length-1
        if @completed_movies.exclude? films[i] and @movie_queue.exclude? films[i]
          @movie_links << film_links[i]
          @movie_queue << films[i]
          @graph.add_movie_node(movie_node = MovieNode.new(films[i]))
          movie_node.adjacency_list << AdjacentNode.new(actor_node)
          actor_node.adjacency_list << AdjacentNode.new(movie_node)
        end
      end
    end
  end

  # This function converts a human readable number to a float e.g. 3 million -> 3000000.
  # @param num The human readable number to be converted to a float
  # @return [Float] The number converted to a float
  def self.human_to_number(num)
    num.gsub!("\u00A0", " ")
    num_arr = num.split(' ')
    @logger.debug num_arr
    if num_arr[1] == 'thousand'
      return num_arr[0].to_f * 10**3
    elsif num_arr[1] == 'million'
      return num_arr[0].to_f * 10**6
    elsif num_arr[1]  == 'billion'
      return num_arr[0].to_f * 10**9
    else
      return num_arr[0].to_f
    end
  end

  # This function calculates the age of the actor given their birthday.
  # @param bday The birthday of the actor to be converted to age
  # @return [Integer] The age of the actor
  def self.age(bday)
    now = Time.now.utc.to_date
    now.year - bday.year - ((now.month > bday.month || (now.month == bday.month && now.day >= bday.day)) ? 0 : 1)
  end

  # This function stores the graph as a .json file
  def self.graph_to_json(graph, file_name)
    cloned_graph = Marshal.load(Marshal.dump(graph))
    json_object = cloned_graph.to_hash
    json_object.each do |type, array|
      for i in 0..array.length-1
        for j in 0..array[i].adjacency_list.length-1
          array[i].adjacency_list[j] = array[i].adjacency_list[j].to_hash
        end
        array[i] = array[i].to_hash
      end
    end
    File.open(file_name, 'w') { |f| f.write(JSON.pretty_generate(json_object)) }
  end

  # This function creates a graph from a .json file.
  def self.json_to_graph(json_file)
    json_string = File.read(json_file)
    data = JSON.parse(json_string)
    new_graph = Graph.new
    actor_data = data['actor_nodes']
    movie_data = data['movie_nodes']
    new_graph.actor_nodes = actor_data.map { |a_n| ActorNode.new(a_n['name'], a_n['age'], a_n['total_grossing_value'],
                                                                 a_n['adjacency_list'].map{|adj_node| AdjacentNode.new(new_graph.get_movie_node(adj_node['node']), adj_node['weight'])}) }
    new_graph.movie_nodes = movie_data.map { |m_n| MovieNode.new(m_n['name'], m_n['box_office'], m_n['year'],
                                                                 m_n['adjacency_list'].map{|adj_node| AdjacentNode.new(new_graph.get_actor_node(adj_node['node']), adj_node['weight'])}) }
    return new_graph
  end

  # This function adds the total grossing value for each actor
  def self.add_total_grossing_for_actors
    for i in 0..@graph.actor_nodes.length-1
      sum = 0
      @graph.actor_nodes[i].adjacency_list.each{ |movie_adj_node| sum += movie_adj_node.weight }
      @graph.actor_nodes[i].total_grossing_value = sum
    end
  end

  # This function adds the edge weights to the adjacent_nodes with younger actors being weighted more.
  def self.add_weights
    @graph.movie_nodes.each { |movie_node| movie_node.adjacency_list.sort_by! { |actor_adj_node| actor_adj_node.node.age } }
    for i in 0..@graph.movie_nodes.length-1
      x = 1.0
      box_office_total = @graph.movie_nodes[i].box_office.to_f
      weighted_gross = []
      for j in 0..@graph.movie_nodes[i].adjacency_list.length-1
        weighted_gross[j] = (0.5)**x * @graph.movie_nodes[i].box_office.to_f
        box_office_total -= weighted_gross[j].to_f
        x += 1.0
      end
      box_office_total = box_office_total / (@graph.movie_nodes[i].adjacency_list.length)
      for j in 0..@graph.movie_nodes[i].adjacency_list.length-1
        weighted_gross[j] += box_office_total
      end
      for j in 0..@graph.movie_nodes[i].adjacency_list.length-1
        actor_adj_node = @graph.movie_nodes[i].adjacency_list[j]
        actor_adj_node.weight = weighted_gross[j]
        for k in 0..actor_adj_node.node.adjacency_list.length-1
          if actor_adj_node.node.adjacency_list[k].node == @graph.movie_nodes[i]
            actor_adj_node.node.adjacency_list[k].weight = weighted_gross[j]
          end
        end
      end
    end
  end

  # This calls the main function
  main("Morgan Freeman", "/wiki/Morgan_Freeman")

end