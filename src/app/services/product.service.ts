import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { Product } from '../models/product.model';

@Injectable({
  providedIn: 'root'
})
export class ProductService {
  private products: Product[] = [
    {
      id: 1,
      name: 'Wireless Headphones Pro',
      price: 2999,
      originalPrice: 5999,
      discount: 50,
      rating: 4.5,
      reviews: 1250,
      category: 'Electronics',
      image: 'https://via.placeholder.com/300x300?text=Wireless+Headphones',
      description: 'Premium wireless headphones with active noise cancellation and 30-hour battery life.',
      inStock: true,
      deliveryDays: 1
    },
    {
      id: 2,
      name: 'Ultra 4K Smart TV 55"',
      price: 39999,
      originalPrice: 89999,
      discount: 56,
      rating: 4.7,
      reviews: 2340,
      category: 'Electronics',
      image: 'https://via.placeholder.com/300x300?text=Smart+TV',
      description: '55 inch Ultra HD 4K Smart TV with AI upscaling and HDR support.',
      inStock: true,
      deliveryDays: 2
    },
    {
      id: 3,
      name: 'Gaming Laptop RTX 4060',
      price: 74999,
      originalPrice: 129999,
      discount: 42,
      rating: 4.6,
      reviews: 890,
      category: 'Computers',
      image: 'https://via.placeholder.com/300x300?text=Gaming+Laptop',
      description: 'High-performance gaming laptop with RTX 4060, 16GB RAM, and 512GB SSD.',
      inStock: true,
      deliveryDays: 2
    },
    {
      id: 4,
      name: 'Samsung Galaxy S24',
      price: 79999,
      originalPrice: 99999,
      discount: 20,
      rating: 4.8,
      reviews: 5680,
      category: 'Mobile Phones',
      image: 'https://via.placeholder.com/300x300?text=Galaxy+S24',
      description: 'Latest Samsung flagship with 200MP camera and 120Hz AMOLED display.',
      inStock: true,
      deliveryDays: 1
    },
    {
      id: 5,
      name: 'Apple Watch Series 9',
      price: 34999,
      originalPrice: 44999,
      discount: 22,
      rating: 4.7,
      reviews: 3450,
      category: 'Wearables',
      image: 'https://via.placeholder.com/300x300?text=Apple+Watch',
      description: 'Advanced fitness tracking with ECG monitoring and always-on display.',
      inStock: true,
      deliveryDays: 1
    },
    {
      id: 6,
      name: 'Sony WH-1000XM5 Headphones',
      price: 24999,
      originalPrice: 34999,
      discount: 29,
      rating: 4.9,
      reviews: 4120,
      category: 'Electronics',
      image: 'https://via.placeholder.com/300x300?text=Sony+Headphones',
      description: 'Premium noise-canceling headphones with superior sound quality.',
      inStock: true,
      deliveryDays: 1
    },
    {
      id: 7,
      name: 'iPad Pro 12.9"',
      price: 89999,
      originalPrice: 119999,
      discount: 25,
      rating: 4.6,
      reviews: 2890,
      category: 'Tablets',
      image: 'https://via.placeholder.com/300x300?text=iPad+Pro',
      description: 'Powerful tablet with M2 chip and stunning 120Hz display.',
      inStock: true,
      deliveryDays: 2
    },
    {
      id: 8,
      name: 'AirPods Pro 2',
      price: 19999,
      originalPrice: 24999,
      discount: 20,
      rating: 4.7,
      reviews: 6750,
      category: 'Electronics',
      image: 'https://via.placeholder.com/300x300?text=AirPods+Pro',
      description: 'Wireless earbuds with adaptive audio and active noise cancellation.',
      inStock: true,
      deliveryDays: 1
    },
    {
      id: 9,
      name: 'Canon EOS R6 Camera',
      price: 159999,
      originalPrice: 199999,
      discount: 20,
      rating: 4.8,
      reviews: 1560,
      category: 'Cameras',
      image: 'https://via.placeholder.com/300x300?text=Canon+Camera',
      description: 'Professional mirrorless camera with 20MP full-frame sensor.',
      inStock: false,
      deliveryDays: 3
    },
    {
      id: 10,
      name: 'Mechanical Gaming Keyboard RGB',
      price: 7999,
      originalPrice: 14999,
      discount: 47,
      rating: 4.5,
      reviews: 3210,
      category: 'Gaming',
      image: 'https://via.placeholder.com/300x300?text=Gaming+Keyboard',
      description: 'RGB mechanical keyboard with Cherry MX switches.',
      inStock: true,
      deliveryDays: 1
    },
    {
      id: 11,
      name: 'Logitech MX Master 3S Mouse',
      price: 8999,
      originalPrice: 11999,
      discount: 25,
      rating: 4.6,
      reviews: 2340,
      category: 'Accessories',
      image: 'https://via.placeholder.com/300x300?text=Logitech+Mouse',
      description: 'Advanced wireless mouse with customizable buttons.',
      inStock: true,
      deliveryDays: 1
    },
    {
      id: 12,
      name: 'Ultra Wide Monitor 34"',
      price: 34999,
      originalPrice: 54999,
      discount: 36,
      rating: 4.4,
      reviews: 890,
      category: 'Monitors',
      image: 'https://via.placeholder.com/300x300?text=Ultra+Monitor',
      description: '34 inch curved ultra-wide LED monitor with 165Hz refresh rate.',
      inStock: true,
      deliveryDays: 2
    },
    {
      id: 13,
      name: 'Portable SSD 2TB',
      price: 12999,
      originalPrice: 19999,
      discount: 35,
      rating: 4.7,
      reviews: 4560,
      category: 'Storage',
      image: 'https://via.placeholder.com/300x300?text=SSD+Storage',
      description: 'Fast 2TB portable SSD with USB-C connectivity.',
      inStock: true,
      deliveryDays: 1
    },
    {
      id: 14,
      name: 'Power Bank 65W 25000mAh',
      price: 3499,
      originalPrice: 7999,
      discount: 56,
      rating: 4.5,
      reviews: 7890,
      category: 'Accessories',
      image: 'https://via.placeholder.com/300x300?text=Power+Bank',
      description: 'High-capacity power bank with fast charging support.',
      inStock: true,
      deliveryDays: 1
    },
    {
      id: 15,
      name: 'USB-C Docking Station',
      price: 5999,
      originalPrice: 9999,
      discount: 40,
      rating: 4.3,
      reviews: 1230,
      category: 'Accessories',
      image: 'https://via.placeholder.com/300x300?text=Docking+Station',
      description: 'Multi-port USB-C docking station with HDMI and Ethernet.',
      inStock: true,
      deliveryDays: 1
    },
    {
      id: 16,
      name: 'Webcam 4K Pro',
      price: 4999,
      originalPrice: 8999,
      discount: 44,
      rating: 4.4,
      reviews: 2450,
      category: 'Electronics',
      image: 'https://via.placeholder.com/300x300?text=4K+Webcam',
      description: '4K webcam with auto-focus for streaming and video calls.',
      inStock: true,
      deliveryDays: 1
    }
  ];

  private productsSubject = new BehaviorSubject<Product[]>(this.products);

  constructor() {}

  getProducts(): Observable<Product[]> {
    return this.productsSubject.asObservable();
  }

  getProductById(id: number): Observable<Product | undefined> {
    return new Observable(observer => {
      const product = this.products.find(p => p.id === id);
      observer.next(product);
      observer.complete();
    });
  }

  getProductsByCategory(category: string): Observable<Product[]> {
    return new Observable(observer => {
      const filtered = this.products.filter(p => p.category.toLowerCase() === category.toLowerCase());
      observer.next(filtered);
      observer.complete();
    });
  }

  getCategories(): Observable<string[]> {
    return new Observable(observer => {
      const categories = [...new Set(this.products.map(p => p.category))];
      observer.next(categories);
      observer.complete();
    });
  }

  searchProducts(query: string): Observable<Product[]> {
    return new Observable(observer => {
      const filtered = this.products.filter(p =>
        p.name.toLowerCase().includes(query.toLowerCase()) ||
        p.description.toLowerCase().includes(query.toLowerCase())
      );
      observer.next(filtered);
      observer.complete();
    });
  }
}
