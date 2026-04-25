# Controller Architecture & Connectivity

## Visual Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    APPLICATION LAYER                         │
│                  (HighlightsApp.java)                        │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ Creates
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              MAIN CONTROLLER LAYER                           │
│           DashboardController.java                           │
│                                                               │
│  Responsibilities:                                           │
│  • Initialize application layout                             │
│  • Create all sub-controllers                               │
│  • Display home/dashboard view                              │
│  • Show statistics and graphs                               │
└──────┬──────────┬──────────┬──────────┬────────────┬────────┘
       │          │           │          │            │
       │ creates  │ creates   │ creates  │ creates    │ creates
       ▼          ▼           ▼          ▼            ▼
┌──────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌──────────┐
│Navigation│ │Customer │ │ Product │ │ Invoice │ │  Profit  │
│Controller│ │Controller│ │Controller│ │Controller│ │Calculator│
└──────────┘ └─────────┘ └─────────┘ └─────────┘ └──────────┘
     │            │            │           │             │
     │            │            │           │             │
     │            └────────────┼───────────┘             │
     │                         │ (uses)                  │
     │                         │                         │
     └─────────────────────────┴─────────────────────────┘
                               │
                               │ All use
                               ▼
                    ┌──────────────────────┐
                    │  DatabaseHandler     │
                    │  (database layer)    │
                    └──────────────────────┘
                               │
                               │ queries
                               ▼
                    ┌──────────────────────┐
                    │   SQLite Database    │
                    │   (Highlights.db)    │
                    └──────────────────────┘
```

## Detailed Controller Connections

### 1. DashboardController (Orchestrator)
```java
public class DashboardController {
    // Holds references to all sub-controllers
    private NavigationController navigationController;
    private CustomerController customerController;
    private ProductController productController;
    private InvoiceController invoiceController;
    private ProfitCalculatorController profitCalculatorController;
    
    // Shared content area where all views render
    private VBox contentArea;
}
```

**Creates & Manages:**
- NavigationController → for routing
- CustomerController → for customer operations
- ProductController → for product operations
- InvoiceController → for invoice operations
- ProfitCalculatorController → for calculations

**Displays:**
- Home dashboard with statistics
- Weekly sales graph
- Overview cards

### 2. NavigationController (Router)
```java
public class NavigationController {
    // Receives method references from DashboardController
    private Runnable showHomeAction;
    private Runnable showCustomersAction;
    private Runnable showProductsAction;
    private Runnable showInvoicesAction;
    private Runnable showProfitCalculatorAction;
}
```

**Receives:**
- Method references (callbacks) from DashboardController
- Example: `this::showHome` → `showHomeAction`

**Provides:**
- Navigation panel UI
- Button click handling
- Navigation to appropriate sections

### 3. CustomerController
```java
public class CustomerController {
    private VBox contentArea; // Shared with DashboardController
    
    public void showCustomers() { ... }
    private void showCustomerDetails(Customer customer) { ... }
    private void showEditCustomerDialog(Customer customer) { ... }
    private void deleteCustomer(Customer customer) { ... }
}
```

**Database Operations:**
```sql
SELECT * FROM customers
INSERT INTO customers (name, phone, email, address) VALUES (?, ?, ?, ?)
UPDATE customers SET name=?, phone=?, email=?, address=? WHERE id=?
DELETE FROM customers WHERE id=?
SELECT i.invoice_date, p.name, ii.quantity ... -- Purchase history
```

**Dependencies:**
- DatabaseHandler
- Customer model
- PurchaseHistory (inner class)

### 4. ProductController
```java
public class ProductController {
    private VBox contentArea;
    
    public void showProducts() { ... }
    public ObservableList<Product> loadProducts() { ... } // Used by InvoiceController
}
```

**Database Operations:**
```sql
SELECT * FROM products
INSERT INTO products (name, description, price, stock, category) VALUES (?, ?, ?, ?, ?)
```

**Dependencies:**
- DatabaseHandler
- Product model

**Used By:**
- InvoiceController (for product selection)

### 5. InvoiceController
```java
public class InvoiceController {
    private VBox contentArea;
    private TableView<Invoice> invoicesTable;
    
    public void showInvoices() { ... }
    private void showInvoiceDetails(Invoice invoice) { ... }
    private int saveInvoice(...) { ... }
    private void generateInvoicePdf(...) { ... }
}
```

**Database Operations:**
```sql
-- Invoice operations
INSERT INTO invoices (customer_id, invoice_date, total_amount, ...) VALUES (?, ?, ?, ...)
SELECT i.*, c.name as customer_name FROM invoices i LEFT JOIN customers c ...

-- Invoice items
INSERT INTO invoice_items (invoice_id, product_id, quantity, price, total) VALUES (?, ?, ?, ?, ?)
SELECT p.id, p.name, ii.quantity, ii.price, ii.total FROM invoice_items ii ...

-- Lookup queries
SELECT id FROM customers WHERE name = ?
SELECT id FROM products WHERE name = ?
SELECT price FROM products WHERE name = ?
```

**Dependencies:**
- DatabaseHandler
- Invoice model
- Product data (via ProductController methods)
- InvoiceItem (inner class)
- iTextPDF library for PDF generation

### 6. ProfitCalculatorController
```java
public class ProfitCalculatorController {
    private VBox contentArea;
    
    public void showProfitCalculator() { ... }
    private String getTotalRevenue() { ... }
    private String getInvoiceCount() { ... }
}
```

**Database Operations:**
```sql
SELECT SUM(final_amount) as total FROM invoices
SELECT COUNT(*) as count FROM invoices
```

**Dependencies:**
- DatabaseHandler
- Read-only access to invoice data

## Data Flow Examples

### Example 1: Creating an Invoice
```
User clicks "Invoice" in Navigation
              ↓
NavigationController.showInvoicesAction()
              ↓
InvoiceController.showInvoices()
              ↓
Loads customer names from DB
Loads product names from DB via ProductController
              ↓
User adds items, clicks "Save Invoice"
              ↓
InvoiceController.saveInvoice()
              ↓
Inserts into invoices table
Inserts into invoice_items table
              ↓
InvoiceController.generateInvoicePdf()
              ↓
Creates PDF in Downloads folder
              ↓
Refreshes invoice table view
```

### Example 2: Viewing Customer Details
```
User double-clicks customer in table
              ↓
CustomerController.showCustomerDetails(customer)
              ↓
Loads customer info from Customer object
              ↓
Queries purchase history:
  - Joins invoice_items, invoices, products tables
  - Gets all purchases for this customer
              ↓
Displays customer info card
Displays purchase history table
Calculates total amount spent
```

### Example 3: Dashboard Statistics
```
DashboardController.showHome()
              ↓
Queries database for statistics:
  - getCustomerCount() → COUNT(*) FROM customers
  - getProductCount() → COUNT(*) FROM products
  - getInvoiceCount() → COUNT(*) FROM invoices
  - getTotalRevenue() → SUM(final_amount) FROM invoices
              ↓
Queries weekly sales data:
  - getWeeklySalesData() → Last 7 days revenue
              ↓
Creates statistics cards
Creates line chart with sales data
Displays on home view
```

## Database Schema Reference

```sql
-- Tables used by controllers

customers
├── id (PRIMARY KEY)
├── name
├── phone
├── email
└── address

products
├── id (PRIMARY KEY)
├── name
├── description
├── price
├── stock
└── category

invoices
├── id (PRIMARY KEY)
├── customer_id (FOREIGN KEY → customers.id)
├── invoice_date
├── total_amount
├── discount
├── final_amount
└── payment_status

invoice_items
├── id (PRIMARY KEY)
├── invoice_id (FOREIGN KEY → invoices.id)
├── product_id (FOREIGN KEY → products.id)
├── quantity
├── price
└── total
```

## Communication Patterns

### Pattern 1: Method Reference (Callback)
```java
// DashboardController passes methods to NavigationController
navigationController = new NavigationController(
    this::showHome,              // Method reference
    customerController::showCustomers,
    productController::showProducts,
    invoiceController::showInvoices,
    profitCalculatorController::showProfitCalculator
);
```

### Pattern 2: Shared State (ContentArea)
```java
// All controllers share the same VBox contentArea
contentArea = new VBox(20);

customerController = new CustomerController(contentArea);
productController = new ProductController(contentArea);
invoiceController = new InvoiceController(contentArea);
profitCalculatorController = new ProfitCalculatorController(contentArea);

// When a controller renders its view:
contentArea.getChildren().clear();  // Clear previous content
contentArea.getChildren().addAll(/* new content */);  // Add new content
```

### Pattern 3: Direct Method Calls
```java
// InvoiceController uses ProductController methods
ObservableList<Product> products = productController.loadProducts();

// DatabaseHandler is used directly by all controllers
Connection conn = DatabaseHandler.getConnection();
```

## Thread Safety & Concurrency

Currently, all controllers operate on the JavaFX Application Thread:
- Database queries are synchronous
- UI updates happen immediately
- No threading concerns in current implementation

**Future Enhancement Recommendation:**
```java
// Move database operations to background threads
Task<ObservableList<Customer>> loadTask = new Task<>() {
    @Override
    protected ObservableList<Customer> call() throws Exception {
        return loadCustomersFromDatabase();
    }
};

loadTask.setOnSucceeded(event -> {
    table.setItems(loadTask.getValue());
});

new Thread(loadTask).start();
```

## Error Handling Strategy

All controllers follow the same pattern:
```java
try {
    // Database operation
} catch (SQLException e) {
    e.printStackTrace();
    showAlert("Error", "Operation failed: " + e.getMessage(), Alert.AlertType.ERROR);
}
```

## Styling & Theming

All controllers share common styling constants:
```java
GRADIENT_BG = "linear-gradient(to bottom right, #0f0f0f, #1a1a1a, #262626)"
CARD_BG = "background-color: #111111; border-color: #B71C1C"
ACCENT_PINK = "background-color: #C62828; text-fill: white"
TEXT_ON_DARK = "text-fill: #E0E0E0"
```

This ensures consistent look and feel across all views.

---

This architecture provides:
✅ Clear separation of concerns
✅ Easy to test individual components
✅ Simple to add new features
✅ Maintainable and scalable code structure
