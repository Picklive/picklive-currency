# -*- encoding : utf-8 -*-

require 'picklive/currency'

describe Picklive::Currency do

  it "knows about GBP" do
    Picklive::Currency['GBP'].should == GBP
  end

  it "knows about USD" do
    Picklive::Currency['USD'].should == USD
  end

  it "knows about chips" do
    Picklive::Currency['chips'].should == Chips
  end

  it "knows about tickets" do
    Picklive::Currency['tickets'].should == Ticket
  end

  describe "currency 0 value" do
    it "is equal to 0 as integer" do
      (GBP.new(0) == 0).should be_true
    end
  end

  describe "currency nonzero value" do
    it "is not equal to the integer value" do
      (GBP.new(100) == 100).should be_false
    end
  end

  describe "USD currency 0 value" do
    it "is equal to 0 as integer" do
      (USD.new(0) == 0).should be_true
    end
  end

  describe "USD currency nonzero value" do
    it "is not equal to the integer value" do
      (USD.new(100) == 100).should be_false
    end
  end

  it "can be created in to different ways, which create equal objects" do
    GBP[5.20].should == GBP.new(520)
  end

  it "is comparable with same type" do
    (GBP[3.10] > GBP[3.09]).should be_true
    (GBP[3.10] > GBP[3.10]).should be_false
  end

  it "is not comparable with a different type" do
    expect { GBP[3.10] > Chips[309] }.to raise_error
  end

  it "is comparable to an integer, except for equality" do
    (GBP[3.10] > 309).should be_true
    (GBP[3.10] > 310).should be_false
    (GBP[3.10] == 310).should be_false
    (GBP[3.10] != 310).should be_true
  end

  it "has a format that can be included in sentences" do
    "Give me #{GBP[5].for_sentence}".should == "Give me £5"
    "Give me #{GBP[0.1].for_sentence}".should == "Give me 10p"
  end
end


