# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :budget_quotes, force: true do |t|
    t.string :customer_name, null: false
    t.string :customer_contact
    t.date :quote_date, null: false
    t.text :notes
    t.integer :prescription_id
    t.timestamps
  end

  add_index :budget_quotes, :prescription_id
  add_index :budget_quotes, :quote_date

  create_table :budget_line_items, force: true do |t|
    t.references :budget_quote, null: false, foreign_key: true, index: true
    t.string :description, null: false
    t.decimal :price, precision: 10, scale: 2, null: false
    t.string :category, null: false, default: 'other'
    t.integer :quantity, default: 1, null: false
    t.timestamps
  end

  create_table :budget_payments, force: true do |t|
    t.references :budget_quote, null: false, foreign_key: true, index: true
    t.decimal :amount, precision: 10, scale: 2, null: false
    t.date :payment_date, null: false
    t.string :payment_method, null: false, default: 'efectivo'
    t.text :notes
    t.timestamps
  end

  add_index :budget_payments, :payment_date
end
