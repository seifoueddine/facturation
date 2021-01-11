#
# Open Source Billing - A super simple software to create & send invoices to your customers and
# collect payments.
# Copyright (C) 2013 Mark Mian <mark.mian@opensourcebilling.org>
#
# This file is part of Open Source Billing.
#
# Open Source Billing is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Open Source Billing is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Open Source Billing.  If not, see <http://www.gnu.org/licenses/>.
#
class User < ApplicationRecord
  include UserSearch
  acts_as_token_authenticatable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :encryptable, :encryptor => :restful_authentication_sha1
  validates_uniqueness_of :email, :uniqueness => :true
  after_create :set_default_settings, :set_introduction

  mount_uploader :avatar, ImageUploader

  has_one :staff
  belongs_to :role
  has_many :logs, dependent: :destroy
  has_many :invoices
  has_and_belongs_to_many :companies
  has_one :introduction, dependent: :destroy

  attr_accessor :account,:login, :notify_user
  include RailsSettings::Extend
  has_and_belongs_to_many :accounts, :join_table => 'account_users'

  #Scopes
  scope :created_at, -> (created_at) { where(created_at: created_at) }
  scope :role_id, -> (role_id) { where(role_id: role_id) }

  class << self
    def current=(user)
      Thread.current[:current_user] = user
    end

    def current
      Thread.current[:current_user]
    end

    def filter(params, per_page)
      date_format = current.nil? ? '%Y-%m-%d' : (current.settings.date_format || '%Y-%m-%d')
      users = params[:search].present? ? self.search(params[:search]).records : self
      users = users.role_id(params[:role_id]) if params[:role_id].present?
      users = users.created_at(
          (Date.strptime(params[:create_at_start_date], date_format).in_time_zone .. Date.strptime(params[:create_at_end_date], date_format).in_time_zone)
      ) if params[:create_at_start_date].present?

      users.page(params[:page]).per(per_page)
    end
  end

  def assigned_companies
    if self.have_all_companies_access?
      Company.all.order('company_name asc')
    else
      self.companies
    end
  end

  def set_default_settings
    self.settings.records_per_page = 9
    self.settings.side_nav_opened = true
    self.settings.index_page_format = 'cart'
  end

  def set_introduction
    intro = Introduction.new
    intro.user_id = self.id
    intro.save
  end

  def reset_default_settings
    self.settings.language = 'en'
    self.settings.records_per_page = '9'
    self.settings.index_page_format = 'table'
    self.settings.side_nav_opened = true
    self.introduction.update(dashboard: false, invoice: false, new_invoice: false, estimate: false,
                             new_estimate: false, payment: false, new_payment: false, client: false,
                             new_client: false, item: false, new_item: false, tax: false, new_tax: false,
                             report: false, setting: false, invoice_table: false, estimate_table: false,
                             payment_table: false, client_table: false, item_table: false, tax_table: false)
    Settings.default_currency = 'PKR'
    Settings.invoice_number_format = "{{invoice_number}}"
  end

  def currency_symbol
    "$"
  end

  def currency_code
    "USD"
  end

  def already_exists?(email)
    User.where('email = ?',email).present?
  end

  def current_account
    accounts.first
  end

  def first_company_id
    accounts.first.companies.first.id
  end

  def companies_email_templates
    templates = []
    accounts.first.companies.each do |company|
       company.email_templates.each do |template|
         templates << template
       end
    end
    templates
  end

  def name
    user_name
  end

  def clients
    Client.unscoped.where(account_id: account_id)  rescue nil
  end

  def invoices
    Invoice.unscoped.where(account_id: account_id)  rescue nil
  end

  def invoices_revenues
    invoices.collect(&:invoice_total).sum rescue nil
  end


  def group_date
    created_at.strftime('%B %Y')
  end

  def card_name
    user_name.first.capitalize rescue nil
  end

  def group_role
    roles.first.name rescue nil
  end

  def role_name
    roles.first.try(:name).try(:humanize) rescue nil
  end

  def profile_picture
    avatar_url(:thumb) || 'img-user.png'
  end
end
