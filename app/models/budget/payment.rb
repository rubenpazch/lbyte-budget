# frozen_string_literal: true

module Budget
  # ActiveRecord model for payments within quotes
  # Tracks payment transactions for quotes
  class Payment < ActiveRecord::Base
    self.table_name = 'budget_payments'

    PAYMENT_METHODS = %w[efectivo tarjeta transferencia cheque other].freeze

    # Associations
    belongs_to :quote, class_name: 'Budget::Quote', foreign_key: 'budget_quote_id'

    # Validations
    validates :amount, presence: true, numericality: { greater_than: 0 }
    validates :payment_date, presence: true
    validates :payment_method, presence: true, inclusion: { in: PAYMENT_METHODS }

    # Callbacks
    before_validation :set_default_payment_method
    before_validation :set_default_payment_date

    # Scopes
    scope :ordered, -> { order(:payment_date) }
    scope :by_method, ->(method) { where(payment_method: method) }

    # Get payment method in Spanish
    # @return [String] Payment method in Spanish
    def payment_method_name
      {
        'efectivo' => 'Efectivo',
        'tarjeta' => 'Tarjeta',
        'transferencia' => 'Transferencia',
        'cheque' => 'Cheque',
        'other' => 'Otro'
      }[payment_method] || payment_method.to_s.capitalize
    end

    # Format payment for display
    # @return [String] Formatted payment
    def to_s
      output = "$#{format('%.2f', amount)}, #{payment_method_name} (#{payment_date.strftime('%d/%m/%Y')})"
      output += " - #{notes}" if notes.present?
      output
    end

    private

    def set_default_payment_method
      self.payment_method = 'efectivo' if payment_method.blank?
      self.payment_method = 'other' unless PAYMENT_METHODS.include?(payment_method)
    end

    def set_default_payment_date
      self.payment_date ||= Time.current
    end
  end
end
