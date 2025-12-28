# Rails Engine Installation & Usage Guide

## What is Budget?

Budget is a **Rails Engine** that provides complete quote/budget management functionality for businesses with advance payments and installment tracking.

**Features:**
- ✅ ActiveRecord models with associations
- ✅ Database migrations
- ✅ REST JSON API with JBuilder
- ✅ Business logic (calculations, validations)
- ✅ Complete Rails Engine integration

## Installation Steps

### 1. Add to Gemfile

```ruby
gem 'budget'
```

### 2. Install the Gem

```bash
bundle install
```

### 3. Generate Migrations

```bash
rails generate budget:install
```

This creates three migration files in `db/migrate/`:
- `create_budget_quotes.rb`
- `create_budget_line_items.rb`
- `create_budget_payments.rb`

### 4. Run Migrations

```bash
rails db:migrate
```

This creates three tables:
- `budget_quotes`
- `budget_line_items`
- `budget_payments`

## Database Tables Created

### budget_quotes
Stores customer quote information.

| Column | Type | Description |
|--------|------|-------------|
| id | integer | Primary key |
| customer_name | string | Customer name (required) |
| customer_contact | string | Phone/email |
| notes | text | Additional notes |
| quote_date | datetime | Quote creation date |
| created_at | datetime | Timestamp |
| updated_at | datetime | Timestamp |

### budget_line_items
Stores individual items in each quote.

| Column | Type | Description |
|--------|------|-------------|
| id | integer | Primary key |
| budget_quote_id | integer | Foreign key to quotes |
| description | string | Item description (required) |
| price | decimal(10,2) | Unit price (required) |
| category | string | lente, montura, tratamiento, other |
| quantity | integer | Quantity (default: 1) |
| created_at | datetime | Timestamp |
| updated_at | datetime | Timestamp |

### budget_payments
Stores payments made towards quotes.

| Column | Type | Description |
|--------|------|-------------|
| id | integer | Primary key |
| budget_quote_id | integer | Foreign key to quotes |
| amount | decimal(10,2) | Payment amount (required) |
| payment_date | datetime | When payment was made |
| payment_method | string | efectivo, tarjeta, transferencia, cheque, other |
| notes | text | Payment notes |
| created_at | datetime | Timestamp |
| updated_at | datetime | Timestamp |

## Usage Examples

### Creating a Quote

```ruby
# In a controller or service
quote = Budget::Quote.create!(
  customer_name: "María González",
  customer_contact: "maria@example.com"
)
```

### Adding Line Items

```ruby
# Add lenses
quote.add_line_item(
  description: "Lentes progresivos alta gama",
  price: 150.00,
  category: "lente"
)

# Add frame
quote.add_line_item(
  description: "Montura titanio ligera",
  price: 80.00,
  category: "montura"
)

# Add treatment (multiple quantity)
quote.line_items.create!(
  description: "Protección UV",
  price: 25.00,
  category: "tratamiento",
  quantity: 2
)
```

### Adding Payments

```ruby
# Initial payment (adelanto)
quote.add_payment(
  amount: 150.00,
  payment_method: "efectivo",
  notes: "Adelanto 50%"
)

# Later payment
quote.add_payment(
  amount: 100.00,
  payment_method: "tarjeta",
  notes: "Pago parcial"
)
```

### Querying Quotes

```ruby
# Find quote by ID
quote = Budget::Quote.find(1)

# Recent quotes
recent = Budget::Quote.recent.limit(10)

# Find by customer name
quotes = Budget::Quote.by_customer("María")

# Pending quotes (not fully paid)
pending = Budget::Quote.pending

# With associations
quote = Budget::Quote.includes(:line_items, :payments).find(1)
```

### Calculations

```ruby
quote = Budget::Quote.find(1)

# Total price
quote.total  # => 300.0

# Total paid
quote.total_paid  # => 150.0

# Remaining balance
quote.remaining_balance  # => 150.0

# Check if fully paid
quote.fully_paid?  # => false

# Category breakdown
quote.category_breakdown
# => { lente: 150.0, montura: 80.0, tratamiento: 50.0, other: 20.0 }

# Initial payment
quote.initial_payment  # => first Payment record

# Summary hash
quote.summary
# => { id: 1, customer_name: "María", total: 300.0, ... }
```

### Formatting for Display

```ruby
# Print formatted quote
puts quote

# Output:
# ============================================================
# PRESUPUESTO #1
# ============================================================
# Cliente: María González
# Contacto: maria@example.com
# Fecha: 29/11/2025
# 
# DETALLE:
# ------------------------------------------------------------
# 1. Lente - Lentes progresivos: $150.00
# 2. Montura - Montura titanio: $80.00
# ...
```

## Controller Example

```ruby
class QuotesController < ApplicationController
  def create
    @quote = Budget::Quote.create!(quote_params)
    
    # Add items from form
    params[:line_items].each do |item|
      @quote.add_line_item(
        description: item[:description],
        price: item[:price],
        category: item[:category]
      )
    end
    
    redirect_to quote_path(@quote), notice: "Quote created successfully"
  end
  
  def add_payment
    @quote = Budget::Quote.find(params[:id])
    @quote.add_payment(payment_params)
    
    redirect_to quote_path(@quote), notice: "Payment added"
  end
  
  private
  
  def quote_params
    params.require(:quote).permit(:customer_name, :customer_contact, :notes)
  end
  
  def payment_params
    params.require(:payment).permit(:amount, :payment_method, :notes)
  end
end
```

## View Example (ERB)

```erb
<h1>Quote #<%= @quote.id %></h1>

<div class="customer-info">
  <p><strong>Customer:</strong> <%= @quote.customer_name %></p>
  <p><strong>Contact:</strong> <%= @quote.customer_contact %></p>
  <p><strong>Date:</strong> <%= @quote.quote_date.strftime('%d/%m/%Y') %></p>
</div>

<h2>Line Items</h2>
<table>
  <% @quote.line_items.each do |item| %>
    <tr>
      <td><%= item.category_name %></td>
      <td><%= item.description %></td>
      <td><%= number_to_currency(item.price) %></td>
      <td><%= item.quantity %></td>
      <td><%= number_to_currency(item.subtotal) %></td>
    </tr>
  <% end %>
</table>

<div class="totals">
  <p><strong>Total:</strong> <%= number_to_currency(@quote.total) %></p>
  <p><strong>Paid:</strong> <%= number_to_currency(@quote.total_paid) %></p>
  <p><strong>Balance:</strong> <%= number_to_currency(@quote.remaining_balance) %></p>
  <p><strong>Status:</strong> 
    <span class="<%= @quote.fully_paid? ? 'paid' : 'pending' %>">
      <%= @quote.fully_paid? ? 'PAID' : 'PENDING' %>
    </span>
  </p>
</div>

<h2>Payments</h2>
<ul>
  <% @quote.payments.ordered.each do |payment| %>
    <li><%= payment %></li>
  <% end %>
</ul>
```

## API (JSON) Example

```ruby
# app/controllers/api/quotes_controller.rb
module Api
  class QuotesController < ApplicationController
    def show
      @quote = Budget::Quote.includes(:line_items, :payments).find(params[:id])
      
      render json: {
        id: @quote.id,
        customer_name: @quote.customer_name,
        customer_contact: @quote.customer_contact,
        quote_date: @quote.quote_date,
        total: @quote.total,
        total_paid: @quote.total_paid,
        remaining_balance: @quote.remaining_balance,
        fully_paid: @quote.fully_paid?,
        line_items: @quote.line_items.map do |item|
          {
            description: item.description,
            price: item.price,
            category: item.category,
            quantity: item.quantity,
            subtotal: item.subtotal
          }
        end,
        payments: @quote.payments.ordered.map do |payment|
          {
            amount: payment.amount,
            payment_date: payment.payment_date,
            payment_method: payment.payment_method_name,
            notes: payment.notes
          }
        end
      }
    end
  end
end
```

## Routes Example

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :quotes do
    member do
      post :add_payment
      post :add_line_item
    end
  end
  
  namespace :api do
    resources :quotes, only: [:index, :show, :create]
  end
end
```

## Validations

The models include built-in validations:

### Budget::Quote
- `customer_name` - required
- `quote_date` - automatically set if not provided

### Budget::LineItem
- `description` - required
- `price` - required, must be >= 0
- `quantity` - required, must be > 0
- `category` - must be in: lente, montura, tratamiento, other

### Budget::Payment
- `amount` - required, must be > 0
- `payment_date` - automatically set if not provided
- `payment_method` - must be in: efectivo, tarjeta, transferencia, cheque, other

## Scopes

### Budget::Quote
- `recent` - Orders by created_at DESC
- `by_customer(name)` - Search by customer name
- `pending` - Only quotes not fully paid

### Budget::Payment
- `ordered` - Orders by payment_date ASC
- `by_method(method)` - Filter by payment method

## Testing in Your Rails App

```ruby
# spec/models/budget/quote_spec.rb
require 'rails_helper'

RSpec.describe Budget::Quote, type: :model do
  it "calculates total correctly" do
    quote = create(:budget_quote)
    quote.line_items.create!(description: "Test", price: 100, category: "other")
    
    expect(quote.total).to eq(100)
  end
  
  it "tracks payments correctly" do
    quote = create(:budget_quote)
    quote.line_items.create!(description: "Test", price: 100, category: "other")
    quote.payments.create!(amount: 50, payment_method: "efectivo")
    
    expect(quote.remaining_balance).to eq(50)
    expect(quote.fully_paid?).to be false
  end
end
```

## Troubleshooting

### Migrations not found
If migrations aren't generated, ensure you've run:
```bash
rails generate budget:install
```

### Models not loading
Ensure Rails is properly loading the engine. Check that `config/application.rb` doesn't exclude engines.

### Foreign key errors
Ensure migrations were run in the correct order:
1. budget_quotes
2. budget_line_items
3. budget_payments

## JSON API Usage

The Budget Engine includes a complete REST JSON API. See **API_DOCUMENTATION.md** for full details.

### Mounting the Engine

In your Rails app's `config/routes.rb`:

```ruby
mount Budget::Engine => '/budget'
```

This makes all API endpoints available at `/budget/*`.

### Quick API Examples

#### Create a quote via API
```bash
curl -X POST http://localhost:3000/budget/quotes \
  -H "Content-Type: application/json" \
  -d '{"quote":{"customer_name":"María González","customer_contact":"555-1234"}}'
```

#### Add line item
```bash
curl -X POST http://localhost:3000/budget/quotes/1/line_items \
  -H "Content-Type: application/json" \
  -d '{"line_item":{"description":"Lentes","price":150.00,"category":"lente"}}'
```

#### Add payment
```bash
curl -X POST http://localhost:3000/budget/quotes/1/payments \
  -H "Content-Type: application/json" \
  -d '{"payment":{"amount":75.00,"payment_method":"efectivo"}}'
```

#### Get quote with calculations
```bash
curl http://localhost:3000/budget/quotes/1
```

Response:
```json
{
  "id": 1,
  "customer_name": "María González",
  "line_items": [...],
  "payments": [...],
  "totals": {
    "total": 150.00,
    "total_paid": 75.00,
    "remaining_balance": 75.00,
    "fully_paid": false
  }
}
```

### Available Endpoints

- `GET /budget/quotes` - List all quotes
- `GET /budget/quotes/:id` - Get quote details
- `POST /budget/quotes` - Create quote
- `PATCH /budget/quotes/:id` - Update quote
- `DELETE /budget/quotes/:id` - Delete quote
- `GET /budget/quotes/:id/summary` - Get quote summary
- `GET /budget/quotes/:quote_id/line_items` - List line items
- `POST /budget/quotes/:quote_id/line_items` - Add line item
- `PATCH /budget/quotes/:quote_id/line_items/:id` - Update line item
- `DELETE /budget/quotes/:quote_id/line_items/:id` - Delete line item
- `GET /budget/quotes/:quote_id/payments` - List payments
- `POST /budget/quotes/:quote_id/payments` - Add payment
- `PATCH /budget/quotes/:quote_id/payments/:id` - Update payment
- `DELETE /budget/quotes/:quote_id/payments/:id` - Delete payment

See **API_DOCUMENTATION.md** for complete API reference with request/response examples.

## Support

For issues or questions, visit:
https://github.com/rubenpazch/budget
