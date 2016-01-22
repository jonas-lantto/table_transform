class Store
  def initialize(columns)
    @columns = columns
    @store = Hash.new {|h,k| h[k] = [] }
  end

  def << (hash_values)
    @store[hash_values[:partition] || :default] << create_row(hash_values)
  end

  def to_a
    @store.values.reduce([@columns], :+)
  end

  def partition(partition = :default)
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
