# picklive-currency

Classes for representing amounts of money or virtual money.

Currently it has GBP and Chips currencies built in.

## Examples

  # The amount can be given in as the usual value or the integer value:
  GBP[5.20] == GBP.new(520) # => true

  # They are comparable:
  GBP[3.10] > GBP[3.09] # => true
  GBP[3.10] > GBP[3.10] # => false

  # You can compare with an integer value
  GBP[3.10] > 309 # => true

  # Equality check is more strict:
  GBP[3.10] == 310 # => false

  # Objects are instances of Picklive::Currency::Base
  GBP[3.10].is_a? Picklive::Currency::Base # => true

  GBP[3.10].to_s # => "£3.10"
  Chips[100].to_s # => "100 Chips"

  Chips[100].class.real? # => false
  Chips[100].class.virtual? # => true
  GBP[3.10].class.real? # => true

  class Transaction
    attr_accessor :amount_in_pennies
    attr_accessor :currency_code
    include Picklive::Currency::ModelMethods
    include Picklive::Currency::Converters
    currency_field :amount
  end

  t = Transaction.new
  t.amount_in_pennies = 310
  t.currency_code = 'GBP'

  t.amount # => <GBP:3.1>
  t.amount_in_currency # => <GBP:3.1>

  t.amount = Chips[100]
  t.amount_in_pennies # => 100
  t.currency_code # => "chips"

