class Store
  def initialize(columns, partition_symbol = nil)
    @columns = columns
    @partition_symbol = partition_symbol
    @store = Hash.new {|h,k| h[k] = [] }
  end

  def << (hash_values)
    @store[hash_values[@partition_symbol]] << create_row(hash_values)
    self
  end

  def to_a
    @store.values.reduce([@columns], :+)
  end

  def partition(partition = nil)
    [@columns] + @store[partition]
  end

  private
  def create_row(hash_values)
    row = []
    @columns.each do |col|
      value = hash_values[col.downcase.to_sym]
      row << (value || '')
    end
    row
  end

end
