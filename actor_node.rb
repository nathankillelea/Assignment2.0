class ActorNode
  attr_accessor :name, :age, :total_grossing_value, :adjacency_list

  # This is the constructor for the ActorNode class.
  def initialize(name, age = nil, total_grossing_value = nil, adjacency_list = [])
    @name = name
    @age = age
    @total_grossing_value = total_grossing_value
    @adjacency_list = adjacency_list
  end

  # This converts the node to a hash.
  def to_hash
    {
        name: @name,
        age: @age,
        total_grossing_value: @total_grossing_value,
        adjacency_list: @adjacency_list
    }
  end
end