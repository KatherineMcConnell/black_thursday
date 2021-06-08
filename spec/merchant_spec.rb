require 'bigdecimal'
require_relative 'spec_helper'

RSpec.describe Merchant do

  before(:each) do
    @paths = {
      :items => "./data/items.csv",
      :merchants => "./data/merchants.csv",
      :invoices => "./data/invoices.csv",
      :invoice_items => "./data/invoice_items.csv",
      :transactions => "./data/transactions.csv",
      :customers => "./data/customers.csv"
    }
    @se = SalesEngine.from_csv(@paths)
    @mr = @se.merchants
  end

  it "exists" do

    m = Merchant.new({
    :id          => 5,
    :name        => "Turing School",
    :created_at  => Time.now
    }, @mr)

    expect(m).to be_a(Merchant)
  end

  it "has attributes" do
    m = Merchant.new({
    :id          => 5,
    :name        => "Turing School",
    :created_at  => Time.now
    }, @mr)

    expect(m.id).to eq(5)
    expect(m.name).to eq("Turing School")
    expect(m.created_at.class).to eq(Time)
  end

  it "stores its states in a hash" do
    m = Merchant.new({
    :id          => 5,
    :name        => "Turing School",
    :created_at  => Time.now
    }, @mr)

    m_hash = m.to_hash

    expect(m_hash).to be_a(Hash)
    expect(m_hash.keys.length).to eq(3)
    expect(m_hash.values.length).to eq(3)
    expect(m_hash[:id]).to eq(m.id)
    expect(m_hash[:name]).to eq(m.name)
    expect(m_hash[:created_at].class).to eq(Time)
  end
end
