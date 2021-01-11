class SettingsController < ApplicationController
  after_action :user_introduction, only: [:index], if: -> { current_user.introduction.present? &&  !current_user.introduction.setting? }

  def create
    user = current_user
    @language_changed = false
    if params[:multi_currency].present? and params[:multi_currency].eql?('On')
      Settings.currency = "On"
    else
      Settings.currency = "Off"
    end
    if params[:side_nav_opened].present? and params[:side_nav_opened].eql?('Open')
      user.settings.side_nav_opened = true
    else
      user.settings.side_nav_opened = false
    end
    if params[:date_format].present?
      Settings.date_format = params[:date_format]
    end
    if params[:records_per_page].present?
      user.settings.records_per_page = params[:records_per_page]
    end
    if params[:user_locale].present?
      params[:locale] = params[:user_locale]
      user.settings.language = params[:user_locale]
      @language_changed = true
    end
    if params[:default_currency].present?
      Settings.default_currency = params[:default_currency]
    end
    if params[:index_page_format].present? && params[:index_page_format].eql?('card')
      user.settings.index_page_format = 'card'
      session[:view] = 'card'
    else
      user.settings.index_page_format = 'table'
      session[:view] = 'table'
    end
    if params[:invoice_number_format].present? && params[:invoice_number_format].include?('{{invoice_number}}')
      Settings.invoice_number_format = params[:invoice_number_format]
    end
    respond_to { |format| format.js }
  end

  def invoice_number_format

  end

  def nav_format
    if params[:nav_state] == "true"
      current_user.settings.side_nav_opened = true
    elsif params[:nav_state] == "false"
      current_user.settings.side_nav_opened = false
    end
    render plain: "ok"
  end

  def index
    @email_templates = EmailTemplate.all
    authorize @email_templates
    @roles = Role.all.where(for_client: false)
    @client_roles = Role.all.where(for_client: true)
    @companies = Company.all
    @users = User.all
    @payment_terms = PaymentTerm.where.not(number_of_days: -1)
    @recurring_frequencies = RecurringFrequency.all
    @authentication_token = current_user.authentication_token
  end

  def set_default_currency
    currency = Currency.find(params[:currency_id]) rescue Currency.default_currency
    Settings.default_currency = currency.unit
    flash[:notice] = t('views.settings.currency_updated_msg_html', unit: currency.unit)
    render plain: 'OK' if request.xhr?
  end
end
