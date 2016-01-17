class Store
  def initialize
    @columns = %w(Severity Category Reason Module ModuleType Note)
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
      row << case col.downcase.to_sym
               when :severity
                 value.to_s.capitalize
               when :category
                 value || 'Internal'
               else
                 value || ''
             end
    end
    row
  end

end
