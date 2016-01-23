class Store
  def initialize(columns, partition_symbol = nil)
    @columns = columns
    @col_sym = columns.map { |x| x.downcase.to_sym }
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
      @col_sym.inject([]) { |row, col| row << (hash_values[col] || '') }
    end

end
