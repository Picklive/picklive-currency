require 'action_view'
module Picklive
  module Currency

    def self.[](code)
      puts "WARN: Currency code #{code.inspect} is DEPRECATED" if code == 'chip'
      return GBP if code == 'GBP'
      return Chips if code == 'chips' || code == 'chip'
      raise ArgumentError.new("unknown currency code: #{code.inspect}")
    end

    def self.all            ; [GBP, Chips] ; end
    def self.cash_codes     ; 'GBP'       ; end
    def self.virtual_codes  ; 'chips'      ; end

    # To create a currency object:
    #
    #   GBP.new(1000) # -> <GBP:10.0>
    #   GBP[10]       # -> <GBP:10.0>
    #   GBP['10.00']  # -> <GBP:10.0>
    #   Chips[1000]   # -> <Chips:1000>
    class Base
      def self.fake?              ; not real? ; end
      def self.cash?              ; real?     ; end
      def self.virtual?           ; !cash?    ; end
      def self.html_symbol        ; symbol    ; end

      attr_accessor :integer_amount
      private :integer_amount=

      def initialize integer_amount
        self.integer_amount = integer_amount.to_i
      end

      def self.[](human_value)
        v = human_value.to_f
        new((v * self.precision).round)
      end

      def amount
        if self.class.precision == 1
          integer_amount
        else
          integer_amount / self.class.precision.to_f
        end
      end
      alias_method :to_decimal, :amount

      def +(other); same_type!(other); self.class.new(integer_amount + num_from(other)); end
      def -(other); same_type!(other); self.class.new(integer_amount - num_from(other)); end
      def *(multiplier); self.class.new(integer_amount * multiplier); end
      def /(divider); self.*(1/divider.to_f); end
      def -@; self.class.new(-integer_amount); end
      def abs; self.class.new(integer_amount.abs); end

      include Comparable
      def <=>(other); same_type!(other); self.integer_amount <=> num_from(other); end
      def ==(other)
        if other.is_a?(self.class)
          self.integer_amount == other.integer_amount
        else
          self.integer_amount == 0 && (other.respond_to?(:to_i) && other.to_i == 0)
        end
      end
      def eql?(other); self == other; end

      def same_type!(other)
        unless other.is_a?(Fixnum) || other.is_a?(Float)
          unless other.is_a?(Picklive::Currency::Base)
            raise "Not a currency: #{other.inspect}"
          end
          if self.class.code != other.class.code
            raise ArgumentError.new("Different currencies: #{self.class.code} vs #{other.class.code}")
          end
        end
      end

      def num_from(other)
        other.respond_to?(:integer_amount) ? other.integer_amount : other
      end

      def to_i;  integer_amount;       end
      def to_f;  integer_amount.to_f;  end
      def inspect; "<#{self.class.code}:#{amount}>"; end
    end


    class GBP < Base
      def self.precision    ; 100    ; end
      def self.code         ; 'GBP'  ; end
      def self.real?        ; true   ; end
      def self.symbol       ; '£'    ; end
      def self.html_symbol  ; '&pound;' ; end

      include ActionView::Helpers::NumberHelper

      def to_s options = {}
        s = number_to_currency(amount, :unit => '£')
        if options[:short]
          if amount < 1.0
            s = "#{(integer_amount * self.class.precision).round}p"
          else
            s = s.gsub(/\.0+$/, '')
          end
        end
        s
      end
    end


    class Chips < Base
      def self.precision    ; 1       ; end
      def self.code         ; 'chips' ; end
      def self.real?        ; false   ; end
      def self.symbol       ; ''      ; end

      include ActionView::Helpers::TextHelper

      def to_s
        pluralize(amount, "Chip")
      end
    end


    # It provides scopes for models that have a `currency_code` method.
    module ModelMethods

      def self.included(base)
        base.class_eval do
          scope :cash_only,    where(:currency_code => Picklive::Currency.cash_codes)
          scope :virtual_only, where(:currency_code => Picklive::Currency.virtual_codes)
        end
      end

      def currency
        Picklive::Currency[currency_code]
      end

      def amount_in_currency
        currency.new(amount_in_pennies)
      end
    end

    # Provides setters and getters for `something_in_currency`, alias: `something`
    # Mix it into classes that have `something_in_pennies` setter/getter and call:
    #   cuurrency_field :something
    module Converters
      def self.included(base)
        base.instance_eval do
          def currency_field(*fields)
            self.class_eval do

              fields.each do |field|
                define_method "#{field}_in_currency" do
                  pennies = self.send("#{field}_in_pennies")
                  currency.new(pennies) unless pennies.nil?
                end

                define_method "#{field}_in_currency=" do |amount_in_currency|
                  if ! amount_in_currency.is_a?(Picklive::Currency::Base)
                    amount_in_currency = Picklive::Currency::GBP.new((amount_in_currency.to_f * Picklive::Currency::GBP.precision).round)
                  end
                  if self.respond_to?("currency_code=")
                    self.currency_code = amount_in_currency.class.code
                  end
                  self.send("#{field}_in_pennies=", amount_in_currency.integer_amount)
                end

                alias_method :"#{field}",  :"#{field}_in_currency"
                alias_method :"#{field}=", :"#{field}_in_currency="

              end
            end
          end

          def currency_fields(*fields)
            currency_field(*fields)
          end
        end
      end
    end

  end
end

GBP = Picklive::Currency::GBP
Chips = Picklive::Currency::Chips

class Fixnum
  def percent
    self.to_f / 100
  end

  def pounds
    (self * 100).pennies
  end
  alias_method :pound, :pounds

  def pennies
    Picklive::Currency::GBP.new(self)
  end
  alias_method :pence, :pennies

  def to_pounds
    self / 100.0
  end

  def to_pennies
    self * 100
  end

  def chips
    Picklive::Currency::Chips.new(self)
  end
end

class Float
  def pounds
    (self * 100).round.pennies
  end
  alias_method :pound, :pounds

  def to_pennies
    (self * 100).round
  end
end

class String
  def pounds
    to_f.pounds
  end
  alias_method :pound, :pounds
end

