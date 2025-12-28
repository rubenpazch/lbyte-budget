# frozen_string_literal: true

module Budget
  # ActiveRecord model for line items within quotes
  # Represents individual items/services in a quote
  class LineItem < ActiveRecord::Base
    self.table_name = 'budget_line_items'

    CATEGORIES = %w[lente montura tratamiento accesorio servicio other].freeze

    # Associations
    belongs_to :quote, class_name: 'Budget::Quote', foreign_key: 'budget_quote_id'

    # Validations
    validates :description, presence: true
    validates :price, presence: true, numericality: { greater_than: 0 }
    validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
    validates :category, presence: true, inclusion: { in: CATEGORIES }

    # Callbacks
    before_validation :set_default_category

    # Calculate subtotal (price * quantity)
    # @return [Float] Subtotal
    def subtotal
      price * quantity
    end

    # Get category in Spanish
    # @return [String] Category name in Spanish
    def category_name
      {
        'lente' => 'Lente',
        'montura' => 'Montura',
        'tratamiento' => 'Tratamiento',
        'accesorio' => 'Accesorio',
        'servicio' => 'Servicio',
        'other' => 'Otro'
      }[category] || category.to_s.capitalize
    end

    # Format line item for display
    # @return [String] Formatted line item
    def to_s
      if quantity > 1
        "#{category_name} - #{description} (#{quantity} x $#{format('%.2f', price)}) = $#{format('%.2f', subtotal)}"
      else
        "#{category_name} - #{description}: $#{format('%.2f', price)}"
      end
    end

    private

    def set_default_category
      self.category = 'other' if category.blank?
      self.category = 'other' unless CATEGORIES.include?(category)
    end
  end
end
