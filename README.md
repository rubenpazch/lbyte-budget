# Budget

A Rails Engine for managing quotes/budgets for eyeglasses businesses (or any business with advance payments and installment tracking). Perfect for optical stores that need to track customer orders with deposits and remaining balances.

## Features

- 📋 Create detailed quotes with line items (lentes, montura, tratamiento, etc.)
- 💰 Track multiple payments (adelanto/deposit and subsequent payments)
- 🧮 Automatic calculation of totals, paid amounts, and remaining balances
- 📊 Category breakdown for different product types
- 📄 Formatted output for printing or display
- ✅ Payment status tracking (fully paid vs. pending)
- 🚂 **Rails Engine** - Automatically creates database migrations
- 💾 **ActiveRecord Models** - Persist quotes, line items, and payments
- 🔧 **Easy Installation** - One command to set up
- 🌐 **REST JSON API** - Complete API with JBuilder views
- 📱 **API-Ready** - Perfect for React, Vue, or mobile apps

## Installation for Rails Projects

Add this line to your application's Gemfile:

```ruby
gem 'lbyte-budget'
```

And then execute:

```bash
bundle install
```

### Generate Migrations

Run the install generator to copy migrations:

```bash
rails generate budget:install
```

This will create three migrations:
- `create_budget_quotes` - For storing quotes
- `create_budget_line_items` - For storing line items
- `create_budget_payments` - For storing payments

Then run the migrations:

```bash
rails db:migrate
```

### Mount the Engine (For API Access)

Add to your `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount Budget::Engine => "/budget"
  # Your other routes...
end
```

Now you have access to all budget API endpoints at `/budget/*`.

## JSON API Quick Start

### Fetch All Quotes

```bash
curl http://localhost:3000/budget/quotes
```

```json
[
  {
    "id": 1,
    "customer_name": "María González",
    "customer_contact": "555-1234",
    "line_items_count": 2,
    "payments_count": 1,
    "total": "230.00",
    "total_paid": "115.00",
    "remaining_balance": "115.00",
    "fully_paid": false
  }
]
```

### Create a Quote with JavaScript

```javascript
const response = await fetch('http://localhost:3000/budget/quotes', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    quote: {
      customer_name: "María González",
      customer_contact: "555-1234"
    }
  })
});

const quote = await response.json();
console.log(quote.id); // => 1
```

### Add Line Items and Payments

```javascript
// Add line item
await fetch(`http://localhost:3000/budget/quotes/${quoteId}/line_items`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    line_item: {
      description: "Lentes progresivos",
      price: 150.00,
      category: "lente",
      quantity: 1
    }
  })
});

// Record payment
await fetch(`http://localhost:3000/budget/quotes/${quoteId}/payments`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    payment: {
      amount: 75.00,
      payment_method: "tarjeta"
    }
  })
});
```

📖 **See [API_DOCUMENTATION.md](API_DOCUMENTATION.md) for complete endpoint reference.**

## Usage in Rails

### Creating a Quote with ActiveRecord

```ruby
# 1. Create a new quote (persisted to database)
quote = Budget::Quote.create!(
  customer_name: "María González",
  customer_contact: "555-1234",
  notes: "Prefiere montura liviana"
)

# 2. Add line items
quote.add_line_item(
  description: "Lentes progresivos alta gama",
  price: 150.00,
  category: "lente"
)

quote.add_line_item(
  description: "Montura de titanio",
  price: 80.00,
  category: "montura"
)

quote.add_line_item(
  description: "Tratamiento anti-reflejante",
  price: 35.00,
  category: "tratamiento"
)

# 3. Add initial payment (adelanto)
adelanto = quote.total * 0.5
quote.add_payment(
  amount: adelanto,
  payment_method: "efectivo",
  notes: "Adelanto inicial (50%)"
)

# 4. Check status
puts "Total: $#{quote.total}"
puts "Pagado: $#{quote.total_paid}"
puts "Pendiente: $#{quote.remaining_balance}"
puts "Estado: #{quote.fully_paid? ? 'COMPLETO' : 'PENDIENTE'}"

# 5. Later, customer returns to complete payment
quote.add_payment(
  amount: quote.remaining_balance,
  payment_method: "tarjeta",
  notes: "Pago final - retira lentes"
)

# 6. Print formatted quote
puts quote
```

## Database Schema

The gem creates three tables:

### budget_quotes
- `customer_name` (string, required)
- `customer_contact` (string)
- `notes` (text)
- `quote_date` (datetime)
- timestamps

### budget_line_items
- `budget_quote_id` (foreign key)
- `description` (string, required)
- `price` (decimal, required)
- `category` (string) - lente, montura, tratamiento, other
- `quantity` (integer, default: 1)
- timestamps

### budget_payments
- `budget_quote_id` (foreign key)
- `amount` (decimal, required)
- `payment_date` (datetime, required)
- `payment_method` (string) - efectivo, tarjeta, transferencia, cheque, other
- `notes` (text)
- timestamps

## Documentation

- 📘 **[Rails Integration Guide](RAILS_USAGE.md)** - Detailed Rails/ActiveRecord usage
- 🌐 **[API Documentation](API_DOCUMENTATION.md)** - Complete REST API reference with examples
- 🧹 **[Cleanup Guide](CLEANUP.md)** - Understanding the codebase structure

## Model Methods

### Available Categories

- `lente` - Lenses
- `montura` - Frame
- `tratamiento` - Treatment (anti-reflective, UV protection, etc.)
- `accesorio` - Accessories
- `servicio` - Services
- `other` - Other items

### Available Payment Methods

- `efectivo` - Cash
- `tarjeta` - Card
- `transferencia` - Bank transfer
- `cheque` - Check
- `other` - Other methods

### Core Methods

#### Quote

```ruby
# Create a quote
quote = Budget::Quote.create!(customer_name: "John Doe")

# Add line items
quote.add_line_item(description: "Product", price: 100.0, category: 'lente', quantity: 1)

# Add payments
quote.add_payment(amount: 50.0, payment_method: "efectivo")

# Calculations
quote.total              # Total price of all items
quote.total_paid         # Total amount paid
quote.remaining_balance  # Amount still owed
quote.fully_paid?        # true if remaining_balance <= 0

# Get breakdown
quote.category_breakdown # Hash of totals by category
quote.summary           # Complete summary hash

# Access payments
quote.initial_payment   # First payment (adelanto)
quote.payments          # All payments array
```

### Running the Example

See the complete example in action:

```bash
ruby examples/basic_usage.rb
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.

### Running Tests

Run the test suite:

```bash
bundle exec rspec
```

Or use the test script for a nicer output with coverage:

```bash
bundle exec rspec
```

Run specific test suites:

```bash
# ActiveRecord model tests
bundle exec rspec spec/models/

# Controller/API tests
bundle exec rspec spec/controllers/

# Engine tests
bundle exec rspec spec/lib/

# Module tests
bundle exec rspec spec/budget_spec.rb
```

View the coverage report:

```bash
bundle exec rspec
open coverage/index.html
```

The gem has **100% test coverage** across all modules:
- ✅ 145 ActiveRecord model tests
- ✅ 80 controller/API tests
- ✅ 8 engine configuration tests
- ✅ 4 module tests
- **Total: 237+ test examples**

See [TESTING.md](TESTING.md) for detailed testing documentation.

### Interactive Console

Run `bin/console` for an interactive prompt that will allow you to experiment.

### Installation

To install this gem onto your local machine, run `bundle exec rake install`.

## Releasing a New Version

To release a new version of the gem:

1. **Update the version number** in [lib/budget/version.rb](lib/budget/version.rb)
2. **Update the CHANGELOG** in [CHANGELOG.md](CHANGELOG.md) with the new version and release notes
3. **Build the gem**:
   ```bash
   gem build budget.gemspec
   ```
4. **Push to RubyGems** (requires authentication):
   ```bash
   gem push lbyte-budget-X.X.X.gem
   ```
   Note: You'll need to enter your OTP code if MFA is enabled.
5. **Commit and tag the release**:
   ```bash
   git add lib/budget/version.rb CHANGELOG.md
   git commit -m "Bump version to X.X.X"
   git tag vX.X.X
   git push origin main
   git push origin vX.X.X
   ```

## Testing

The Budget gem includes comprehensive test coverage:

- **LineItem tests**: 20+ test cases covering initialization, calculations, formatting, and edge cases
- **Payment tests**: 20+ test cases covering payment methods, validation, and formatting
- **Quote tests**: 40+ test cases covering the complete workflow including line items, payments, calculations, and integration scenarios
- **100% code coverage** as verified by SimpleCov

Run tests with:

```bash
bundle exec rspec --format documentation
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rubenpazch/lbyte-budget. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/rubenpazch/lbyte-budget/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Budget project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/rubenpazch/lbyte-budget/blob/main/CODE_OF_CONDUCT.md).
