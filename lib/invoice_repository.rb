require 'csv'
require 'bigdecimal'
require 'time'
require_relative 'invoice'
require_relative 'helper_methods'

class InvoiceRepository
  include HelperMethods
  attr_reader :all, :engine

  def initialize(file_path, engine)
    @file_path = file_path.to_s
    @engine = engine
    @all = Array.new
    create_invoices
  end

  def create_invoices
    data = CSV.parse(File.read(@file_path), headers: true, header_converters: :symbol) do |line|
      @all << Invoice.new(line.to_h, self)
    end
  end

  def inspect
    "#<#{self.class} #{@all.size} rows>"
  end

  def find_all_by_customer_id(customer_id)
    result = @all.select do |line|
      line.customer_id.to_s == customer_id.to_s
    end
  end

  def find_all_by_merchant_id(merchant_id)
    result = @all.select do |line|
      line.merchant_id.to_i == merchant_id.to_i
    end
  end

  def group_invoices_by_merchant_id
    @all.group_by do |invoice|
      invoice.merchant_id
    end
  end

  def group_invoices_by_created_date
    @all.group_by do |invoice|
      Date.parse(invoice.created_at.to_s).strftime("%A")
    end
  end

  def avg_invoices_created_per_day_std_dev
    mean = avg_invoices_created_per_day
    result = group_invoices_by_created_date.values.reduce(0) do |total, invoices|
      total + ((invoices.length - mean)**2)
    end
    Math.sqrt(result/(group_invoices_by_created_date.values.length - 1))
  end

  def avg_invoices_created_per_day
    grouping = group_invoices_by_created_date
    total = grouping.values.sum { |invoices| invoices.length }
    total.to_f / grouping.values.length
  end

  def avg_invoices_per_merchant
    grouping = group_invoices_by_merchant_id
    total = grouping.values.sum do |invoices_array|
      invoices_array.length
    end
    (total / grouping.values.length.to_f).round(2)
  end

  def avg_invoices_per_merchant_std_dev
    grouping = group_invoices_by_merchant_id
    mean = avg_invoices_per_merchant
    result = grouping.values.reduce(0) do |total, invoices|
      total + ((invoices.length - mean)**2)
    end
    (Math.sqrt(result/(grouping.values.length.to_f - 1))).round(2)
  end

  def top_days_by_invoice_count
    collection_arr = []
    group_invoices_by_created_date.each do |day, invoices|
      if invoices.length >= (avg_invoices_created_per_day + (avg_invoices_created_per_day_std_dev))
        collection_arr << day
      end
    end
    collection_arr
  end

  def invoice_status(status)
    result = (find_all_by_status(status).length / @all.length.to_f)
    (result * 100).round(2)
  end

  def create(attributes)
    @all << Invoice.new(
      {
        :id => create_new_id,
        :customer_id => attributes[:customer_id],
        :merchant_id => attributes[:merchant_id],
        :status => attributes[:status],
        :created_at => attributes[:created_at],
        :updated_at => attributes[:updated_at],
      }, self
    )
  end

  def update(id, attributes)
    result = find_by_id(id)
    unless result == nil
      @all.delete(result)
      result.status = attributes[:status] if attributes[:status] != nil
      result.updated_at = Time.now
      @all << result
    end
  end

end
