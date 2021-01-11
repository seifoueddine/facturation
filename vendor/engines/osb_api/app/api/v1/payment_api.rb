module V1
  class PaymentAPI < Grape::API
    version 'v1', using: :path, vendor: 'osb'
    format :json
    #prefix :api

    resource :payments do

     before {current_user}


      desc 'Return all Payments'
      get do
        @payments = Payment.unarchived
        @payments = @payments.by_company(@current_user.current_company)
        @payments = @payments.joins('LEFT JOIN clients as payments_clients ON  payments_clients.id = payments.client_id').joins('LEFT JOIN invoices ON invoices.id = payments.invoice_id LEFT JOIN clients ON clients.id = invoices.client_id ').order("payments.created_at #{params[:direction].present? ? params[:direction] : 'desc'}")
                        .select('payments.*, clients.organization_name')
      end

      desc 'Fetch a single Payment'
      params do
        requires :id, type: String
      end

      get ':id' do
        payment = Payment.find_by(id: params[:id])
        payment.present? ? payment : {error: "Payment not found", message: nil }
      end

      desc 'Create Payment'
      params do
        requires :payment, type: Hash do
          requires :invoice_id, type: Integer, message: :required
          requires :payment_amount, type: BigDecimal, message: :required
          optional :payment_type, type: String
          optional :payment_method, type: String
          optional :payment_date, type: Date
          optional :notes, type: String
          optional :send_payment_notification, type: Boolean
          optional :paid_full, type: Boolean
          optional :archive_number, type: String
          optional :archived_at, type: DateTime
          optional :deleted_at, type: DateTime
          optional :credit_applied, type: Integer
          optional :client_id, type: Integer
          optional :company_id, type: Integer
        end
      end
      post do
        Services::Apis::PaymentApiService.create(params)
      end


      desc 'Update Payment'
      params do
        requires :payment, type: Hash do
          optional :invoice_id, type: Integer
          optional :payment_amount, type: Integer
          optional :payment_type, type: String
          optional :payment_method, type: String
          optional :payment_date, type: Date
          optional :notes, type: String
          optional :send_payment_notification, type: Boolean
          optional :paid_full, type: Boolean
          optional :archive_number, type: String
          optional :archived_at, type: DateTime
          optional :deleted_at, type: DateTime
          optional :credit_applied, type: Integer
          optional :client_id, type: Integer
          optional :company_id, type: Integer
        end
      end

      patch ':id' do
        payment = Payment.find_by(id: params[:id])
        if payment.present?
          Services::Apis::PaymentApiService.update(params)
        else
          {error: "Payment not found", message: nil }
        end
      end


      desc 'Delete  Payment'
      params do
        requires :id, type: Integer, desc: "Delete payment"
      end
      delete ':id' do
        payment = Payment.find_by(id: params[:id])
        if payment.present?
          Services::Apis::PaymentApiService.destroy(payment)
        else
          {error: "Payment not found", message: nil }
        end
      end
    end
  end
end



