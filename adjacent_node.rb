class AdjacentNode
  attr_accessor :node, :weight

  # This is the constructor for the AdjacentNode class.
  def initialize(node, weight = nil)
    @node = node
    @weight = weight
  end

  # This converts the node to a hash.
  def to_hash
    {
        node: @node.name,
        weight: @weight
    }
  end
end