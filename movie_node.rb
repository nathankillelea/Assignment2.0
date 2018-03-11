class MovieNode
  attr_accessor :name, :box_office, :year, :adjacency_list

  # This is the constructor for the MovieNode class.
  def initialize(name, box_office = nil, year = nil, adjacency_list = [])
    @name = name
    @box_office = box_office
    @year = year
    @adjacency_list = adjacency_list
  end

  # This converts the node to a hash.
  def to_hash
    {
        name: @name,
        box_office: @box_office,
        year: @year,
        adjacency_list: @adjacency_list
    }
  end
end