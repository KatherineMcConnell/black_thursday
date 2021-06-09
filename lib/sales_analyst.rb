require 'date'
require_relative 'helper_methods'

class SalesAnalyst
  include HelperMethods
  attr_reader :items, :merchants, :invoices, :invoice_items, :transactions, :customers, :engine

  def initialize(item_repo, merchant_repo, invoice_repo, invoice_item_repo, transaction_repo, customer_repo, engine)
    @items = item_repo
    @merchants = merchant_repo
    @invoices = invoice_repo
    @invoice_items = invoice_item_repo
    @transactions = transaction_repo
    @customers = customer_repo
    @engine = engine
  end

  def average_items_per_merchant
    @items.avg_items_per_merchant
  end

  def average_items_per_merchant_standard_deviation
    @items.avg_items_per_merchant_std_dev
  end

  def average_item_price_for_merchant(merchant_id)
    @items.avg_item_price_for_merchant(merchant_id)
  end

  def average_average_price_per_merchant
    @items.avg_avg_price_per_merchant
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

  def merchants_with_high_item_count
    collection_arr = []
    @items.group_items_by_merchant_id.each do |merchant_id, items|
      if items.length >= (average_items_per_merchant + average_items_per_merchant_standard_deviation)
        collection_arr << merchant_id
      end
    end
    collection_arr.map { |merchant_id| @merchants.find_by_id(merchant_id) }
  end

  def top_merchants_by_invoice_count
    collection_arr = []
    @invoices.group_invoices_by_merchant_id.each do |merchant_id, invoices|
      if invoices.length >= (average_invoices_per_merchant + (average_invoices_per_merchant_standard_deviation * 2))
        collection_arr << merchant_id
      end
    end
    collection_arr.map { |merchant_id| @merchants.find_by_id(merchant_id) }
  end

  def bottom_merchants_by_invoice_count
    collection_arr = []
    @invoices.group_invoices_by_merchant_id.each do |merchant_id, invoices|
      if invoices.length <= (average_invoices_per_merchant - (average_invoices_per_merchant_standard_deviation * 2))
        collection_arr << merchant_id
      end
    end
    collection_arr.map { |merchant_id| @merchants.find_by_id(merchant_id) }
  end

  def total_revenue_by_date(date)
    result = @invoices.all.find do |invoice|
      invoice.created_at.to_s.split(' ')[0] == date.getgm.to_s.split(' ')[0]
    end
    @invoice_items.group_invoice_items_by_invoice_id[result.id]
  end

  def top_revenue_earners(x=20)
    @merchants.all.max_by(x) { |merchant| revenue_by_merchant(merchant.id) }
  end

  def revenue_by_merchant(merchant_id)
    @invoices.find_all_by_merchant_id(merchant_id).sum do |invoice|
      if @transactions.invoice_paid_in_full?(invoice.id)
        @invoice_items.group_invoice_items_by_invoice_id[invoice.id]
      else
        0
      end
    end
  end

  def merchants_with_pending_invoices
    collection_arr = Array.new
    @invoices.all.each do |invoice|
      if invoice_paid_in_full?(invoice.id) != true
        collection_arr << invoice
      end
    end
    collection_arr.map { |invoice_id| @merchants.find_by_id(invoice_id.merchant_id) }.uniq
  end

  def merchants_with_only_one_item
    collection_arr = Array.new
    @items.group_items_by_merchant_id.each do |merchant, items|
      collection_arr << merchant if items.length == 1
    end
    collection_arr.map { |merchant_id| @merchants.find_by_id(merchant_id) }
  end

  def merchants_with_only_one_item_registered_in_month(month_name)
    merchants = @merchants.group_merchants_by_created_month[month_name]
    merchants_with_only_one_item.select { |merchant| merchants.index(merchant) != nil }
  end

  def most_sold_item_for_merchant(merchant_id)
    grouping = @invoice_items.group_invoice_items_by_item_id
    quantity_by_item = @items.find_all_by_merchant_id(merchant_id).each_with_object(Hash.new(0)) do |item, hash|
      hash[item.id] = grouping[item.id].sum { |invoice_item| invoice_item.quantity.to_i }
    end
    result = quantity_by_item.max_by { |item_id, quantity_sold| quantity_sold }
    [@items.find_by_id(result[0])]
  end

  def best_item_for_merchant(merchant_id)
  end
end
