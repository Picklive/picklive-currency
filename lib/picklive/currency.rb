# -*- encoding : utf-8 -*-

require 'action_view'

module Picklive
  module Currency

    def self.[](code)
      puts "WARN: Currency code #{code.inspect} is DEPRECATED" if code == 'chip'
      case code
        when 'GBP' then GBP
        when 'USD' then USD
        when 'chip', 'chips' then Chips
        when 'ticket', 'tickets' then Ticket
      else
        raise ArgumentError.new("unknown currency code: #{code.inspect}")
      end
    end

    def self.all            ; [GBP, USD, Chips, Ticket] ; end
    def self.cash_codes     ; %w(GBP USD)               ; end
    def self.virtual_codes  ; ['chips', 'tickets']      ; end

    # To create a currency object:
    #
    #   GBP.new(1000) # -> <GBP:10.0>
    #   GBP[10]       # -> <GBP:10.0>
    #   GBP['10.00']  # -> <GBP:10.0>
    #   Chips[1000]   # -> <Chips:1000>
    class Base
      include ActionView::Helpers::NumberHelper

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

      def to_s(options = {})
        formatted_amount = number_to_currency(amount, :unit => self.class.symbol)
        if options[:short]
          formatted_amount.gsub(/\.0+$/, '')
        else
          formatted_amount
        end
      end

      def for_sentence
        to_s(:short => true)
      end
    end


    class GBP < Base
      def self.precision    ; 100    ; end
      def self.code         ; 'GBP'  ; end
      def self.real?        ; true   ; end
      def self.symbol       ; '£'    ; end
      def self.html_symbol  ; '&pound;' ; end
    end

    class USD < Base
      def self.precision    ; 100    ; end
      def self.code         ; 'USD'  ; end
      def self.real?        ; true   ; end
      def self.symbol       ; '$'    ; end
      def self.html_symbol  ; '$'    ; end
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

    class Ticket < Chips
      def self.code; 'tickets' ; end

      def to_s
        pluralize(amount, "Ticket")
      end
    end

    mattr_accessor :default_currency
    @@default_currency = GBP

    def self.setup
      yield self
    end

    # It provides scopes for models that have a `currency_code` method.
    module ModelMethods

      def self.included(base)
        if defined?(ActiveRecord::Base) && base.superclass == ActiveRecord::Base
          base.class_eval do
            scope :cash_only,    -> { where(:currency_code => Picklive::Currency.cash_codes) }
            scope :virtual_only, -> { where(:currency_code => Picklive::Currency.virtual_codes) }
          end
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
                    amount_in_currency = Picklive::Currency::default_currency.new((amount_in_currency.to_f * Picklive::Currency::default_currency.precision).round)
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
USD = Picklive::Currency::USD
Chips = Picklive::Currency::Chips
Ticket = Picklive::Currency::Ticket

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

  def dollars
    (self * 100).cents
  end
  alias_method :dollar, :dollars

  def cents
    Picklive::Currency::USD.new(self)
  end
  alias_method :cent, :cents

  def to_dollars
    self / 100.0
  end

  def to_cents
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

  def dollars
    (self * 100).round.cents
  end
  alias_method :dollar, :dollars

  def to_cents
    (self * 100).round
  end

end

class String
  def pounds
    to_f.pounds
  end
  alias_method :pound, :pounds

  def dollars
    to_f.dollars
  end
  alias_method :dollar, :dollars
end

