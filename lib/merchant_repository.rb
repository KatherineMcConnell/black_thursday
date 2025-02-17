require 'csv'
require 'time'
require_relative 'merchant'
require_relative 'helper_methods'

class MerchantRepository
  include HelperMethods
  attr_reader :all, :engine

  def initialize(file_path, engine)
    @file_path = file_path.to_s
    @engine = engine
    @all = Array.new
    create_merchants
  end

  def create_merchants
    data = CSV.parse(File.read(@file_path), headers: true, header_converters: :symbol) do |line|
      @all << Merchant.new(line.to_h, self)
    end
  end

  def inspect
    "#<#{self.class} #{@all.size} rows>"
  end

  def group_merchants_by_created_month
    @all.group_by do |merchant|
      Date.parse(merchant.created_at.to_s).strftime("%B")
    end
  end

  def create(attributes)
    @all << Merchant.new(
      {
        :id => create_new_id,
        :name => attributes[:name],
        :created_at => attributes[:created_at]
        }, self
      )
  end

  def update(id, attributes)
    result = find_by_id(id)
    unless result == nil
      @all.delete(result)
      result.name = attributes[:name] if attributes[:name] != nil
      @all << result
    end
  end

end
