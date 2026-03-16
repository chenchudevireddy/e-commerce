# ShopHub - Angular E-Commerce Application

A fully functional e-commerce application built with Angular, styled similar to Flipkart and Amazon.

## Features

✨ **Core Features:**
- **Product Browsing**: View products with filtering by category, price, rating, and discount
- **Product Details**: Detailed product pages with images, ratings, reviews, and specifications
- **Shopping Cart**: Add/remove products, adjust quantities, persistent cart storage using localStorage
- **Checkout**: Multi-step checkout process with shipping, address, and payment information
- **Search**: Search products by name and description
- **Responsive Design**: Mobile-friendly interface that works on all devices
- **Dummy Products**: 16 pre-loaded products across multiple categories

## Technology Stack

- **Framework**: Angular 17
- **Language**: TypeScript 5.2
- **Styling**: SCSS
- **Build Tool**: Angular CLI
- **Icons**: Font Awesome 6

## Installation & Quick Start

### Prerequisites
- Node.js (v16+ recommended)
- npm (v8+)

### Steps

1. Navigate to the project directory:
```bash
cd d:\project_2026\e-commerce
```

2. Install dependencies:
```bash
npm install
```

3. Start the development server:
```bash
npm start
```

4. Open your browser and navigate to:
```
http://localhost:4200
```

## Available Commands

```bash
# Start development server
npm start

# Build for production
npm run build

# Run tests
npm test

# Watch mode for development
npm run watch
```

## Features Overview

### 🏠 Home Page
- Hero banner with call-to-action
- Category browsing section
- Top-rated products showcase
- Benefits/features section

### 🛍️ Product Listing
- Grid view of products
- Sidebar filters by category
- Sort options (price, rating, discount, relevance)
- Product cards with quick preview
- "Add to Cart" functionality

### 📦 Product Detail
- High-quality product images
- Detailed product information
- Customer ratings and reviews
- Price comparison (original vs discounted)
- Quantity selector
- Related products section
- Add to cart and buy now options

### 🛒 Shopping Cart
- View all cart items
- Update product quantities
- Remove items
- Order summary with breakdown:
  - Subtotal
  - Discount amount
  - Delivery charges (free above ₹500)
  - Final total
- Continue shopping button
- Proceed to checkout

### 💳 Checkout
- **Step 1**: Shipping Details (name, email, phone)
- **Step 2**: Delivery Address (street, city, state, pincode)
- **Step 3**: Payment Information (card details)
- Order summary with all items
- Order confirmation

## Dummy Products

The application comes with 16 pre-loaded dummy products across multiple categories including Electronics, Mobile Phones, Computers, Tablets, and more.

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)
- Mobile browsers

## Project Structure

```
e-commerce/
├── src/
│   ├── app/
│   │   ├── components/       # UI components
│   │   ├── services/         # Data services
│   │   ├── models/          # TypeScript interfaces
│   │   └── app.component.*  # Root component
│   ├── styles.scss          # Global styles
│   └── main.ts              # Entry point
└── package.json             # Dependencies
```

---

**Happy Shopping! 🛍️**
