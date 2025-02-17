require 'csv'
require 'bigdecimal'
require 'time'
require_relative 'invoice_item'
require_relative 'helper_methods'

class InvoiceItemRepository
  include HelperMethods
  attr_reader :all, :engine

  def initialize(file_path, engine)
    @file_path = file_path.to_s
    @engine = engine
    @all = Array.new
    create_invoice_items
  end

  def create_invoice_items
    data = CSV.parse(File.read(@file_path), headers: true, header_converters: :symbol) do |line|
      @all << InvoiceItem.new(line.to_h, self)
    end
  end

  def inspect
    "#<#{self.class} #{@all.size} rows>"
  end

  def find_all_by_item_id(item_id)
    result = @all.select do |line|
      line.item_id.to_i == item_id.to_i
    end
  end

  def group_invoice_items_by_invoice_id
    grouping = @all.group_by do |invoice_item|
      invoice_item.invoice_id
    end
    grouping.transform_values do |value|
      value.sum { |invoice_items| (invoice_items.quantity.to_f * invoice_items.unit_price) }
    end
  end

  def group_invoice_items_by_item_id
    grouping = @all.group_by do |invoice_item|
      invoice_item.item_id
    end
  end

  def invoice_total(invoice_id)
    result = find_all_by_invoice_id(invoice_id)
    invoice_total = 0
    result.each do |invoice|
      invoice_total += (invoice.quantity.to_i * invoice.unit_price)
    end
    invoice_total
  end

  def create(attributes)
    @all << InvoiceItem.new(
      {
        :id => create_new_id,
        :item_id => attributes[:item_id],
        :invoice_id => attributes[:invoice_id],
        :quantity => attributes[:quantity],
        :unit_price => attributes[:unit_price],
        :created_at => attributes[:created_at],
        :updated_at => attributes[:updated_at],
      }, self
    )
  end

  def update(id, attributes)
    result = find_by_id(id)
    unless result == nil
      @all.delete(result)
      result.quantity = attributes[:quantity] if attributes[:quantity] != nil
      result.unit_price = attributes[:unit_price] if attributes[:unit_price] != nil
      result.updated_at = Time.now
      @all << result
    end
  end

end
