require 'date'
require_relative 'helper_methods'

class SalesAnalyst
  include HelperMethods
  attr_reader :items, :merchants, :invoices, :invoice_items, :transactions, :customers, :engine, :all

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

  def average_items_per_merchant
    @items.avg_items_per_merchant
  end

  def average_items_per_merchant_standard_deviation
    @items.avg_items_per_merchant_std_dev
  end

  def merchants_with_high_item_count
    collection_arr = []
    @items.group_items_by_merchant_id.each do |merchant_id, items|
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
    total = @items.group_items_by_merchant_id[merchant_id.to_s].sum { |item| item.unit_price }
    mean = (total / (@items.group_items_by_merchant_id[merchant_id.to_s].length))
    BigDecimal(mean.to_f, 4)
  end

  def average_average_price_per_merchant
    total = 0
    @items.group_items_by_merchant_id.each do |merchant_id, items|
      total += (average_item_price_for_merchant(merchant_id))
    end
    mean = ((total / @items.group_items_by_merchant_id.values.length).to_f).floor(2)
  end

  def golden_items
    @items.gldn_items
  end

  def average_invoices_per_merchant
    @invoices.avg_invoices_per_merchant
  end

  def average_invoices_per_merchant_standard_deviation
    @invoices.avg_invoices_per_merchant_std_dev
  end

  def top_merchants_by_invoice_count
    collection_arr = []
    @invoices.group_invoices_by_merchant_id.each do |merchant_id, invoices|
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
    @invoices.group_invoices_by_merchant_id.each do |merchant_id, invoices|
      if invoices.length <= (average_invoices_per_merchant - (average_invoices_per_merchant_standard_deviation * 2))
        collection_arr << merchant_id
      end
    end
    set_all(@merchants)
    result = collection_arr.map { |merchant_id| find_by_id(merchant_id) }
    reset_all
    result
  end

  def top_days_by_invoice_count
    @invoices.top_days_by_invoice_count
  end

  def invoice_status(status)
    @invoices.invoice_status(status)
  end

  def invoice_paid_in_full?(invoice_id)
    @transactions.invoice_paid_in_full?(invoice_id)
  end

  def invoice_total(invoice_id)
    @invoice_items.invoice_total(invoice_id)
  end

  def total_revenue_by_date(date)
    result = @invoices.all.find do |invoice|
      invoice.created_at.to_s.split(' ')[0] == date.getgm.to_s.split(' ')[0]
    end
    @invoice_items.group_invoice_items_by_invoice_id[result.id]
  end

  def top_revenue_earners(x=20)
    collection_array = Array.new
    set_all(@invoices)
    @invoice_items.group_invoice_items_by_invoice_id.each do |invoice_id, total_revenue|
      collection_array << [find_by_id(invoice_id).merchant_id, total_revenue]
    end
    grouping = collection_array.group_by { |invoice| invoice[0] }
    grouping.each do |merchant_id, invoices|
      grouping[merchant_id] = invoices.sum { |invoice| invoice[1] }
    end
    sorted = grouping.sort_by { |merchant, total_revenue| -total_revenue }
    set_all(@merchants)
    output_array = sorted[0..x-1].map { |merchant| find_by_id(merchant[0]) }
  end

  def merchants_with_pending_invoices
    collection_arr = Array.new
    @invoices.all.each do |invoice|
      if invoice_paid_in_full?(invoice.id) != true
        collection_arr << invoice
      end
    end
    set_all(@merchants)
    result = collection_arr.map { |invoice_id| find_by_id(invoice_id.merchant_id) }
    reset_all
    result.uniq
  end

  def merchants_with_only_one_item
    collection_arr = Array.new
    @items.group_items_by_merchant_id.each do |merchant, items|
      collection_arr << merchant if items.length == 1
    end
    set_all(@merchants)
    result = collection_arr.map { |merchant_id| find_by_id(merchant_id) }
    reset_all
    result
  end

  def merchants_with_only_one_item_registered_in_month(month_name)
    merchants = @merchants.group_merchants_by_created_month[month_name]
    merchants_with_only_one_item.select { |merchant| merchants.index(merchant) != nil }
  end

  def revenue_by_merchant(merchant_id)
    set_all(@merchants)
    query = find_by_id(merchant_id).id
    collection_arr = Array.new
    set_all(@invoices)
    @invoice_items.group_invoice_items_by_invoice_id.each do |invoice_id, total_revenue|
      collection_arr << [find_by_id(invoice_id).merchant_id, total_revenue]
    end
    reset_all
    grouping = collection_arr.group_by { |invoice| invoice[0] }
    grouping[query].sum { |invoices| invoices[1] }
  end

  def most_sold_item_for_merchant(merchant_id)
  end

  def best_item_for_merchant(merchant_id)
  end
end
