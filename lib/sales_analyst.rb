require 'date'
require_relative 'helper_methods'

class SalesAnalyst
  include HelperMethods
  attr_reader :items,
              :merchants,
              :invoices,
              :invoice_items,
              :transactions,
              :customers,
              :engine,
              :all

  def initialize(item_repo, merchant_repo, invoice_repo, invoice_item_repo, transaction_repo, customer_repo, engine)
    @items = item_repo
    @merchants = merchant_repo
    @invoices = invoice_repo
    @invoice_items = invoice_item_repo
    @transactions = transaction_repo
    @customers = customer_repo
    @engine = engine
    @all = nil
  end

  def set_all(repo)
    @all = repo.all
  end

  def reset_all
    @all = nil
  end

  def group_items_by_merchant_id
    @items.all.group_by do |item|
      item.merchant_id
    end
  end

  def group_invoices_by_merchant_id
    @invoices.all.group_by do |invoice|
      invoice.merchant_id
    end
  end

  def group_invoices_by_created_date
    @invoices.all.group_by do |invoice|
      Date.parse(invoice.created_at.to_s).strftime("%A")
    end
  end

  def group_invoice_items_by_invoice_id
    grouping = @invoice_items.all.group_by do |invoice_item|
      invoice_item.invoice_id
    end
    grouping.each do |invoice_id, invoice_items|
      grouping[invoice_id] = invoice_items.sum { |invoice_items| (invoice_items.quantity.to_i * invoice_items.unit_price) }
    end
  end

  def average_items_per_merchant
    grouping = group_items_by_merchant_id
    total = group_items_by_merchant_id.values.sum do |items_array|
      items_array.length
    end
    (total / grouping.values.length.to_f).round(2)
  end

  def average_items_per_merchant_standard_deviation
    grouping = group_items_by_merchant_id
    mean = average_items_per_merchant
    result = grouping.values.reduce(0) do |total, items|
      total + ((items.length - mean)**2)
    end
    (Math.sqrt(result/(grouping.values.length.to_f - 1))).round(2)
  end

  def merchants_with_high_item_count
    collection_arr = []
    group_items_by_merchant_id.each do |merchant_id, items|
      if items.length >= (average_items_per_merchant + average_items_per_merchant_standard_deviation)
        collection_arr << merchant_id
      end
    end
    set_all(@merchants)
    result = collection_arr.map { |merchant_id| find_by_id(merchant_id) }
    reset_all
    result
  end

  def average_item_price_for_merchant(merchant_id)
    total = group_items_by_merchant_id[merchant_id.to_s].sum { |item| item.unit_price }
    mean = (total / (group_items_by_merchant_id[merchant_id.to_s].length))
    BigDecimal(mean.to_f, 4)
  end

  def average_average_price_per_merchant
    total = 0
    group_items_by_merchant_id.each do |merchant_id, items|
      total += (average_item_price_for_merchant(merchant_id) / 100)
    end
    mean = (total / group_items_by_merchant_id.values.length)
    # BigDecimal(mean, 4)
  end

  def avg_item_price_std_dev
    total = @items.all.sum { |item| item.unit_price }
    mean = total / @items.all.length
    result = @items.all.reduce(0) do |total, item|
      total + ((item.unit_price - mean)**2)
    end
    Math.sqrt(result/(@items.all.length - 1))
  end

  def golden_items
    total = @items.all.sum { |item| item.unit_price }
    mean = total / @items.all.length
    @items.all.select do |item|
      item.unit_price >= (mean + (avg_item_price_std_dev * 2))
    end
  end

  def average_invoices_per_merchant
    grouping = group_invoices_by_merchant_id
    total = group_invoices_by_merchant_id.values.sum do |invoices_array|
      invoices_array.length
    end
    (total / grouping.values.length.to_f).round(2)
  end

  def average_invoices_per_merchant_standard_deviation
    grouping = group_invoices_by_merchant_id
    mean = average_invoices_per_merchant
    result = grouping.values.reduce(0) do |total, invoices|
      total + ((invoices.length - mean)**2)
    end
    (Math.sqrt(result/(grouping.values.length.to_f - 1))).round(2)
  end

  def top_merchants_by_invoice_count
    collection_arr = []
    group_invoices_by_merchant_id.each do |merchant_id, invoices|
      if invoices.length >= (average_invoices_per_merchant + (average_invoices_per_merchant_standard_deviation * 2))
        collection_arr << merchant_id
      end
    end
    set_all(@merchants)
    result = collection_arr.map { |merchant_id| find_by_id(merchant_id) }
    reset_all
    result
  end

  def bottom_merchants_by_invoice_count
    collection_arr = []
    group_invoices_by_merchant_id.each do |merchant_id, invoices|
      if invoices.length <= (average_invoices_per_merchant - (average_invoices_per_merchant_standard_deviation * 2))
        collection_arr << merchant_id
      end
    end
    set_all(@merchants)
    result = collection_arr.map { |merchant_id| find_by_id(merchant_id) }
    reset_all
    result
  end

  def avg_invoices_created_per_day
    grouping = group_invoices_by_created_date
    total = grouping.values.sum { |invoices| invoices.length }
    total.to_f / grouping.values.length
  end

  def avg_invoices_created_per_day_std_dev
    mean = avg_invoices_created_per_day
    result = group_invoices_by_created_date.values.reduce(0) do |total, invoices|
      total + ((invoices.length - mean)**2)
    end
    Math.sqrt(result/(group_invoices_by_created_date.values.length - 1))
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
    set_all(@invoices)
    result = (find_all_by_status(status).length / @invoices.all.length.to_f)
    reset_all
    (result * 100).round(2)
  end

  def total_revenue_by_date(date)
    date = date.getgm.to_s.split(' ')[0]
    result = @invoices.all.find do |invoice|
      invoice.created_at.to_s.split(' ')[0]
    end
    group_invoice_items_by_invoice_id[result.id]
  end

  def top_revenue_earners(x=20)
    collection_array = Array.new
    set_all(@invoices)
    group_invoice_items_by_invoice_id.each do |invoice_id, total_revenue|
      collection_array << [find_by_id(invoice_id).merchant_id, total_revenue]
    end
    grouping = collection_array.group_by { |invoice| invoice[0] }
    grouping.each do |merchant_id, invoices|
      grouping[merchant_id] = invoices.sum { |invoice| invoice[1] }
    end
    sorted = grouping.sort_by { |merchant, total_revenue| -total_revenue }
    set_all(@merchants)
    output_array = sorted[0..x-1].map do |merchant|
      find_by_id(merchant[0])
    end
    # require "pry"; binding.pry
  end

  def merchants_with_pending_invoices
    # stuff
  end

  def merchants_with_only_one_item
    # stuff
  end

  def merchants_with_only_one_item_registered_in_month(month_name)
    # stuff
  end

  def most_sold_item_for_merchant(merchant_id)
    # stuff
  end

  def best_item_for_merchant(merchant_id)
    # stuff
  end

end
