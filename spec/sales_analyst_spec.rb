require_relative 'spec_helper'

RSpec.describe SalesAnalyst do

  context 'iteration1' do
    before :each do
      @paths = {
        :items => "./data/items.csv",
        :merchants => "./data/merchants.csv",
        :invoices => "./data/invoices.csv",
        :invoice_items => "./data/invoice_items.csv",
        :transactions => "./data/transactions.csv",
        :customers => "./data/customers.csv"
      }
      @se = SalesEngine.from_csv(@paths)
    end

    it 'can initialize from SalesEngine #.from_csv class method' do
      sales_analyst = @se.analyst

      expect(sales_analyst.class).to eq(SalesAnalyst)
    end

    it 'can read repos from SalesEngine' do
      sales_analyst = @se.analyst

      expect(sales_analyst.items.class).to eq(ItemRepository)
      expect(sales_analyst.merchants.class).to eq(MerchantRepository)
      expect(sales_analyst.invoices.class).to eq(InvoiceRepository)
      expect(sales_analyst.invoice_items.class).to eq(InvoiceItemRepository)
      expect(sales_analyst.transactions.class).to eq(TransactionRepository)
      expect(sales_analyst.customers.class).to eq(CustomerRepository)
      expect(sales_analyst.engine.class).to eq(SalesEngine)
    end

    it 'returns average items per merchant' do
      sales_analyst = @se.analyst
      result = sales_analyst.average_items_per_merchant

      expect(result).to eq 2.88
      expect(result.class).to eq Float
    end

    it 'returns standard deviation from average items per merchant' do
      sales_analyst = @se.analyst
      result = sales_analyst.average_items_per_merchant_standard_deviation

      expect(result).to eq 3.26
      expect(result.class).to eq Float
    end

    it 'returns merchants more than one standard deviation above the average' do
      sales_analyst = @se.analyst
      result = sales_analyst.merchants_with_high_item_count

      expect(result.length).to eq 52
      expect(result.first.class).to eq Merchant
    end

    it 'returns the average item price for a given merchant' do
      sales_analyst = @se.analyst
      merchant_id = 12334105
      result = sales_analyst.average_item_price_for_merchant(merchant_id)

      expect(result).to eq 16.66
      expect(result.class).to eq BigDecimal
    end

    xit 'returns the average price for all merchants' do
      sales_analyst = @se.analyst
      result = sales_analyst.average_average_price_per_merchant

      expect(result).to eq 350.29
      expect(result.class).to eq BigDecimal
    end

    it 'returns items that are two standard deviations above the average price' do
      sales_analyst = @se.analyst
      result = sales_analyst.golden_items

      expect(result.length).to eq 5
      expect(result.first.class).to eq Item
    end
  end

  context 'iteration2' do
    before :each do
      @paths = {
        :items => "./data/items.csv",
        :merchants => "./data/merchants.csv",
        :invoices => "./data/invoices.csv",
        :invoice_items => "./data/invoice_items.csv",
        :transactions => "./data/transactions.csv",
        :customers => "./data/customers.csv"
      }
      @se = SalesEngine.from_csv(@paths)
    end

    it 'returns average number of invoices per merchant' do
      sales_analyst = @se.analyst
      result = sales_analyst.average_invoices_per_merchant

      expect(result).to eq 10.49
      expect(result.class).to eq Float
    end

    it 'returns the standard deviation from average invoices per merchant' do
      sales_analyst = @se.analyst
      result = sales_analyst.average_invoices_per_merchant_standard_deviation

      expect(result).to eq 3.29
      expect(result.class).to eq Float
    end

    it 'returns merchants that are two standard deviations above average' do
      sales_analyst = @se.analyst
      result = sales_analyst.top_merchants_by_invoice_count

      expect(result.length).to eq 12
      expect(result.first.class).to eq Merchant
    end

    it 'returns merchants that are two standard deviations below average' do
      sales_analyst = @se.analyst
      result = sales_analyst.bottom_merchants_by_invoice_count

      expect(result.length).to eq 4
      expect(result.first.class).to eq Merchant
    end

    it 'returns days with an invoice count more than one standard deviation above average' do
      sales_analyst = @se.analyst
      result = sales_analyst.top_days_by_invoice_count

      expect(result.length).to eq 1
      expect(result.first).to eq "Wednesday"
      expect(result.first.class).to eq String
    end

    it 'returns the percentage of invoices with given status' do
      sales_analyst = @se.analyst

      result = sales_analyst.invoice_status(:pending)
      expect(result).to eq 29.55

      result = sales_analyst.invoice_status(:shipped)
      expect(result).to eq 56.95

      result = sales_analyst.invoice_status(:returned)
      expect(result).to eq 13.5
    end
  end

  context 'iteration3' do
    before :each do
      @paths = {
        :items => "./data/items.csv",
        :merchants => "./data/merchants.csv",
        :invoices => "./data/invoices.csv",
        :invoice_items => "./data/invoice_items.csv",
        :transactions => "./data/transactions.csv",
        :customers => "./data/customers.csv"
      }
      @se = SalesEngine.from_csv(@paths)
    end

    xit 'returns true if the invoice with the corresponding id is paid in full' do
      sales_analyst = @se.analyst

      result = sales_analyst.invoice_paid_in_full?(1)
      expect(result).to eq true

      result = sales_analyst.invoice_paid_in_full?(200)
      expect(result).to eq true

      result = sales_analyst.invoice_paid_in_full?(203)
      expect(result).to eq false

      result = sales_analyst.invoice_paid_in_full?(204)
      expect(result).to eq false
    end

    it 'returns the total amount of the invoice with the corresponding id' do
      sales_analyst = @se.analyst

      result = sales_analyst.invoice_total(1)

      expect(result).to eq(21067.77)
      expect(result.class).to eq(BigDecimal)
    end
  end

  context 'iteration4' do
    before :each do
      @paths = {
        :items => "./data/items.csv",
        :merchants => "./data/merchants.csv",
        :invoices => "./data/invoices.csv",
        :invoice_items => "./data/invoice_items.csv",
        :transactions => "./data/transactions.csv",
        :customers => "./data/customers.csv"
      }
      @se = SalesEngine.from_csv(@paths)
    end

    it 'returns total revenue for given date' do
      sales_analyst = @se.analyst
      date = Time.parse('2009-02-07')
      result = sales_analyst.total_revenue_by_date(date)

      expect(result).to eq 21067.77
      expect(result.class).to eq BigDecimal
    end

    xit 'returns the top x merchants ranked by revenue' do
      sales_analyst = @se.analyst
      result = sales_analyst.top_revenue_earners(10)
      first = result.first
      last = result.last

      expect(result.length).to eq 10

      expect(first.class).to eq Merchant
      expect(first.id).to eq 12334634

      expect(last.class).to eq Merchant
      expect(last.id).to eq 12335747
    end

    xit 'returns by default the top 20 merchants ranked by revenue if no argument is given' do
      sales_analyst = @se.analyst
      result = sales_analyst.top_revenue_earners
      first = result.first
      last = result.last

      expect(result.length).to eq 20

      expect(first.class).to eq Merchant
      expect(first.id).to eq 12334634

      expect(last.class).to eq Merchant
      expect(last.id).to eq 12334159
    end

    xit 'returns merchants with pending invoices' do
      sales_analyst = @se.analyst
      result = sales_analyst.merchants_with_pending_invoices

      expect(result.length).to eq 467
      expect(result.first.class).to eq Merchant
    end

    xit 'returns merchants with only one item' do
      sales_analyst = @se.analyst
      result = sales_analyst.merchants_with_only_one_item

      expect(result.length).to eq 243
      expect(result.first.class).to eq Merchant
    end

    xit 'returns merchants with only one invoice in given month' do
      sales_analyst = @se.analyst
      result = sales_analyst.merchants_with_only_one_item_registered_in_month('March')

      expect(result.length).to eq 21
      expect(result.first.class).to eq Merchant

      result = sales_analyst.merchants_with_only_one_item_registered_in_month('June')

      expect(result.length).to eq 18
      expect(result.first.class).to eq Merchant
    end

    xit 'returns the revenue for given merchant' do
      sales_analyst = @se.analyst
      result = sales_analyst.revenue_by_merchant(12334194)

      expect(result).to eq BigDecimal(result)
      expect(result.class).to eq BigDecimal
    end

    xit 'returns the most sold items for merchant' do
      sales_analyst = @se.analyst
      # find a merchant_id to test on
      merchant_id = nil
      result = sales_analyst.most_sold_item_for_merchant(merchant_id)

      # per directions, add blog post as a team to describe method
      expect(result.class).to eq Array
      expect(result.class.first.class).to eq Item
    end

    xit 'returns the most sold items for merchant' do
      sales_analyst = @se.analyst
      # find a merchant_id to test on
      merchant_id = nil
      result = sales_analyst.best_item_for_merchant(merchant_id)

      # per directions, add blog post as a team to describe method
      expect(result.class).to eq Item
      # expect(result.something).to eq something
    end
  end

end
