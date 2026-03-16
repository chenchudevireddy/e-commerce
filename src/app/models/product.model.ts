export interface Product {
  id: number;
  name: string;
  price: number;
  originalPrice: number;
  discount: number;
  rating: number;
  reviews: number;
  category: string;
  image: string;
  description: string;
  inStock: boolean;
  deliveryDays: number;
}

export interface CartItem {
  product: Product;
  quantity: number;
}

export interface Order {
  id: number;
  items: CartItem[];
  totalAmount: number;
  orderDate: Date;
  status: string;
}
