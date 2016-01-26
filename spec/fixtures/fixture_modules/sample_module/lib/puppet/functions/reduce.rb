Puppet::Functions.create_function(:reduce) do

  dispatch :reduce_without_memo do
    param 'Any', :enumerable
    block_param 'Callable[2,2]', :block
  end

  dispatch :reduce_with_memo do
    param 'Any', :enumerable
    param 'Any', :memo
    block_param 'Callable[2,2]', :block
  end

  def reduce_without_memo(enumerable)
    enum = asserted_enumerable(enumerable)
    enum.reduce {|memo, x| yield(memo, x) }
  end

  def reduce_with_memo(enumerable, given_memo)
    enum = asserted_enumerable(enumerable)
    enum.reduce(given_memo) {|memo, x| yield(memo, x) }
  end

  def asserted_enumerable(obj)
    unless enum = Puppet::Pops::Types::Enumeration.enumerator(obj)
      raise ArgumentError, ("#{self.class.name}(): wrong argument type (#{obj.class}; must be something enumerable.")
    end
    enum
  end

end