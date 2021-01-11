module V1
  class InvoiceAPI < Grape::API
    version 'v1', using: :path, vendor: 'osb'
    format :json
    formatter :json, Grape::Formatter::Rabl
    #prefix :api

    helpers do

      def taxes_list list
        tax_list = Hash.new("TaxList")
        for tax, amount in list
          tax_list[tax] = amount
        end
        tax_list
      end
      def tax_details
        taxes = []
        tlist = Hash.new(0)
        self.invoice_line_items.each do |li|
          next unless [li.item_unit_cost, li.item_quantity].all?
          line_total = li.item_unit_cost * li.item_quantity
          # calculate tax1 and tax2
          taxes.push({name: li.tax1.name, pct: "#{li.tax1.percentage.to_s.gsub('.0', '')}%", amount: (line_total * li.tax1.percentage / 100.0)}) unless li.tax1.blank?
          taxes.push({name: li.tax2.name, pct: "#{li.tax2.percentage.to_s.gsub('.0', '')}%", amount: (line_total * li.tax2.percentage / 100.0)}) unless li.tax2.blank?
        end
        taxes.each do |tax|
          tlist["#{tax[:name]} #{tax[:pct]}"] += tax[:amount]
        end
        tlist
      end

      def get_company_id
        current_user = @current_user
        current_user.current_company || current_user.accounts.map {|a| a.companies.pluck(:id)}.first
      end

      def filter_by_company(elem)
        if params[:company_id].blank?
          company_id = get_company_id
        else
          company_id = params[:company_id]
        end
        elem.where("company_id IN(?)", company_id)
      end
    end

    resource :invoices do
      before {current_user}

      desc 'All invoices',
           headers: {
               "Access-Token" => {
                   description: "Validates your identity",
                   required: true
               }
           }
      get do
        @invoices = Invoice.unarchived.joins(:client).order("invoices.created_at #{params[:direction].present? ? params[:direction] : 'desc'}").select("invoices.*,clients.*, invoices.id, invoices.currency_id")
        @invoices = filter_by_company(@invoices)
        #@invoices = filter_by_company(@invoices).page(params[:page]).per(@current_user.settings.records_per_page)
        #@invoices={total_records: @invoices.total_count, total_pages: @invoices.total_pages, current_page: @invoices.current_page, per_page: @invoices.limit_value, invoices: @invoices}
      end

      desc 'All Archived invoices',
           headers: {
               "Access-Token" => {
                   description: "Validates your identity",
                   required: true
               }
           }
      get :archived_invoices do
        @invoices = Invoice.archived.joins(:client).order("invoices.created_at #{params[:direction].present? ? params[:direction] : 'desc'}").select("invoices.*,clients.*, invoices.id")
        @invoices = filter_by_company(@invoices)
      end

      desc 'All Deleted invoices',
           headers: {
               "Access-Token" => {
                   description: "Validates your identity",
                   required: true
               }
           }
      get :deleted_invoices do
        @invoices = Invoice.deleted.joins(:client).order("invoices.created_at #{params[:direction].present? ? params[:direction] : 'desc'}").select("invoices.*,clients.*, invoices.id")
        @invoices = filter_by_company(@invoices)
      end

      desc 'previews the selected invoice',
           headers: {
               "Access-Token" => {
                   description: "Validates your identity",
                   required: true
               }
           }
      params do
        requires :invoice_id
      end

      get :preview_of_invoices do
        @invoice = Services::InvoiceService.get_invoice_for_preview(params[:invoice_id])
      end

      desc 'Return unpaid-invoices',
           headers: {
               "Access-Token" => {
                   description: "Validates your identity",
                   required: true
               }
           }

      params do
        optional 'client_id'
      end
      get :unpaid_invoices do
        for_client = params[:client_id].present? ? "and client_id = #{params[:client_id]}" : ''
        @invoices = Invoice.where("(status != 'paid' or status is null) #{for_client}").order('created_at desc')
      end

      desc 'Dispute Invoice',
           headers: {
               "Access-Token" => {
                   description: "Validates your identity",
                   required: true
               }
           }

      params do
        requires :invoice_id
        requires :reason_for_dispute
      end
      get :dispute_invoice do
        @invoice = Services::InvoiceService.dispute_invoice(params[:invoice_id], params[:reason_for_dispute], @current_user)
        org_name = @current_user.accounts.first.org_name rescue org_name = ''
        @message = dispute_invoice_message(org_name)
      end

      params do
        requires :invoice_id
      end
      get :pay_with_credit_card do

      end

      desc "Send invoice to client",
           headers: {
               "Access-Token" => {
                   description: "Validates your identity",
                   required: true
               }
           }
      params do
        requires :id
      end
      get '/send_invoice/:id' do
        invoice = Invoice.find_by(id: params[:id])
        if !invoice.present?
          {error: "Invoice not found", message: nil }
        else
          invoice.send_invoice(@current_user, params[:invoice_id])
          {message: 'Invoice sent'}
        end
      end

      desc 'Create Payment for Invoice',
           headers: {
               "Access-Token" => {
                   description: "Validates your identity",
                   required: true
               }
           }

      params do
        requires :invoice_ids
      end
      get :paypal_payments do
        response = RestClient.post("https://www.sandbox.paypal.com/cgi-bin/webscr", params.merge({"cmd" => "_notify-validate"}), :content_type => "application/x-www-form-urlencoded")
        invoice = Invoice.find(params[:invoice_ids])
        # if status is verified make an entry in payments and update the status on invoice
        if response == "VERIFIED"
          invoice.payments.create({
                                      :payment_method => "paypal",
                                      :payment_amount => params[:payment_gross],
                                      :payment_date => Date.today,
                                      :notes => params[:txn_id],
                                      :paid_full => 1
                                  })
          invoice.update_attribute('status', 'paid')
        end
      end

      desc 'Return all invoice line items',
           headers: {
               "Access-Token" => {
                   description: "Validates your identity",
                   required: true
               }
           }
      params do
        requires :invoice_id
      end
      get :invoice_line_items do
        @invoice = Invoice.find_by_id(params[:invoice_id])
        if @invoice.present?
          {tax: taxes_list(@invoice.tax_details),
           invoices: @invoice.invoice_line_items}
        else
          {error: "Invoice not found", message: nil }
        end
      end

      desc 'Return all invoices'
      get do
        Invoice.where('company_id IN (?)', get_company_id)
      end

      desc 'Fetch a single invoice',
           headers: {
               "Access-Token" => {
                   description: "Validates your identity",
                   required: true
               }
           }
      params do
        requires :id, type: String
      end

      get ':id' do
        invoice = Invoice.find_by(id: params[:id])
        if !invoice.present?
          {error: "Invoice not found", message: nil }
        else
          payment_details = {amount_due: invoice.invoice_total - Payment.invoice_paid_amount(invoice.id), amount_paid: invoice.payments.sum(:payment_amount)}
          invoice_hash = []
          invoice_hash << {invoice: invoice, invoice_line_items: invoice.invoice_line_items, recurring_schedule: invoice.recurring_schedule, payment_details: payment_details}
          invoice_hash
        end
      end

      desc 'Create Single Invoice. You can also create multiple invoice line items for invoice from Rest Clients e.g Postman',
           headers: {
               "Access-Token" => {
                   description: "Validates your identity",
                   required: true
               }
           }
      params do
        requires :invoice, type: Hash do
          # requires :invoice_number, type: String
          requires :invoice_date, type: String, message: :required
          optional :po_number, type: String
          optional :discount_percentage, type: String
          requires :client_id, type: Integer, message: :required
          optional :terms, type: String
          optional :notes, type: String
          optional :status, type: String
          optional :sub_total, type: String
          optional :discount_amount, type: String
          optional :tax_amount, type: String
          optional :tax_id, type: Integer
          optional :invoice_total, type: String
          optional :archive_number, type: String
          optional :archived_at, type: Boolean
          optional :deleted_at, type: String
          optional :created_at, type: String
          optional :updated_at, type: String
          optional :currency_id, type: Integer
          optional :payment_terms_id, type: String
          requires :due_date, type: String, message: :required
          optional :last_invoice_status, type: String
          optional :discount_type, type: String
          optional :company_id, type: Integer
          optional :invoice_line_items_attributes, type: Array do
            # requires :invoice_id, type: Integer
            requires :item_id, type: Integer
            requires :item_name, type: String, message: :required
            requires :item_description, type: String, message: :required
            requires :item_unit_cost, type: Integer, message: :required
            requires :item_quantity, type: Integer, message: :required
            optional :tax_1, type: Integer
            optional :tax_2, type: Integer
            # requires :actual_price, type: String binding.pry
          end
          optional :recurring_schedule_attributes, type: Hash do
            requires :next_invoice_date, type: String, message: :required
            requires :frequency, type: String, message: :required
            requires :occurrences, type: Integer, message: :required
            optional :frequency_repetition, type: Integer
            optional :frequency_type, type: String
            requires :delivery_option, type: String, message: :required
            requires :enable_recurring, type: Boolean, message: :required
          end

        end
      end
      post do
        #params[:log][:company_id] = get_company_id
        Services::Apis::InvoiceApiService.create(params)
      end

      desc 'Update Invoice',
           headers: {
               "Access-Token" => {
                   description: "Validates your identity",
                   required: true
               }
           }
      params do
        requires :invoice, type: Hash do
          requires :invoice_number, type: String, message: :required
          requires :invoice_date, type: String, message: :required
          optional :po_number, type: String
          optional :discount_percentage, type: String
          requires :client_id, type: Integer, message: :required
          optional :notes, type: String
          optional :status, type: String
          optional :sub_total, type: String
          optional :discount_amount, type: String
          optional :tax_amount, type: String
          optional :tax_id, type: Integer
          optional :invoice_total, type: String
          optional :archive_number, type: String
          optional :archived_at, type: Boolean
          optional :deleted_at, type: String
          optional :created_at, type: String
          optional :updated_at, type: String
          optional :payment_terms_id, type: String
          optional :due_date, type: String
          optional :last_invoice_status, type: String
          optional :discount_type, type: String
          optional :company_id, type: Integer
          optional :invoice_line_items_attributes, type: Array do
            # requires :invoice_id, type: Integer
            requires :item_id, type: Integer
            requires :item_name, type: String, message: :required
            requires :item_description, type: String, message: :required
            requires :item_unit_cost, type: Integer, message: :required
            requires :item_quantity, type: Integer, message: :required
            optional :tax_1, type: Integer
            optional :tax_2, type: Integer
            # requires :actual_price, type: String binding.pry
          end
          optional :recurring_schedule_attributes, type: Hash do
            requires :next_invoice_date, type: String, message: :required
            requires :frequency, type: String, message: :required
            requires :occurrences, type: Integer, message: :required
            optional :frequency_repetition, type: Integer
            optional :frequency_type, type: String
            requires :delivery_option, type: String, message: :required
            requires :enable_recurring, type: Boolean, message: :required
          end

        end
      end

      patch ':id' do
        invoice = Invoice.find_by(id: params[:id])
        if invoice.present?
          Services::Apis::InvoiceApiService.update(params)
        else
          {error: "Invoice not found", message: nil }
        end
      end


      desc 'Delete an invoice',
           headers: {
               "Access-Token" => {
                   description: "Validates your identity",
                   required: true
               }
           }
      params do
        requires :id, type: Integer, desc: "Delete an invoice"
      end
      delete ':id' do
        invoice = Invoice.find_by(id: params[:id])
        if invoice.present?
          Services::Apis::InvoiceApiService.destroy(invoice)
        else
          {error: "Invoice not found", message: nil }
        end
      end

      desc 'Get current user invoices',
           headers: {
               "Access-Token" => {
                   description: "Validates your identity",
                   required: true
               },
               "user_id" => {
                   required: true
               }
           }
      get '/get_invoices/:user_id' do
        @invoices = @current_user.invoices
      end

      desc 'Void single invoice',
           headers: {
               "Access-Token" => {
                   description: "Validates your identity",
                   required: true
               }
           }
      params do
        requires :id, type: Integer, desc: "Void single invoice"
      end
      get '/void_invoice/:id' do
        @invoice = Invoice.find(params[:id])
        if @invoice.status == "void"
          {message: 'Already Voided', message: nil }
        else
          @invoice.status = "void"
          @invoice.base_currency_equivalent_total = 0
          @invoice.invoice_total = 0
          @invoice.sub_total = 0
          @invoice.invoice_line_items.each do |item|
            item.item_unit_cost = 0
            item.tax_1 = 0
            item.tax_2 = 0
            item.save
          end
          if @invoice.save
            {message: 'Successfully Void'}
          else
            {error: @invoice.errors.full_messages}
          end

        end

      end
    end
  end
end



