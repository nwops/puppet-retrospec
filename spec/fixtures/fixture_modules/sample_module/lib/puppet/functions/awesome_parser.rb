# extremely helpful documentation
# https://github.com/puppetlabs/puppet-specifications/blob/master/language/func-api.md#the-4x-api

# Example Documention for function using puppet strings
# https://github.com/puppetlabs/puppetlabs-strings
# When given two numbers, returns the one that is larger.
# You could have a several line description here if you wanted,
# but I don't have much to say about this function.
#
# @example using two integers
#   $bigger_int = max(int_one, int_two)
#
# @return [Integer] the larger of the two parameters
#
# @param num_a [Integer] the first number to be compared
# @param num_b [Integer] the second number to be compared
Puppet::Functions.create_function(:awesome_parser) do
  # the function below is called by puppet and and must match
  # the name of the puppet function above. You can set your
  # required parameters below and puppet 4 will enforce these
  # change x and y to suit your needs although only one parameter is required
  def awesome_parser(x,y)
    x >= y ? x : y
  end

  # you can define other helper methods in this code block as well
end
