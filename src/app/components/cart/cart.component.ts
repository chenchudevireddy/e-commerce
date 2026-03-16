import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { CartService } from '../../services/cart.service';
import { CartItem } from '../../models/product.model';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-cart',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './cart.component.html',
  styleUrls: ['./cart.component.scss']
})
export class CartComponent implements OnInit {
  cartItems: CartItem[] = [];
  cartTotal: number = 0;

  constructor(
    private cartService: CartService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadCart();
  }

  loadCart(): void {
    this.cartService.getCart().subscribe(items => {
      this.cartItems = items;
      this.updateTotal();
    });
  }

  updateTotal(): void {
    this.cartTotal = this.cartService.getCartTotal();
  }

  updateQuantity(cartItem: CartItem, quantity: number): void {
    if (quantity > 0) {
      this.cartService.updateQuantity(cartItem.product.id, quantity);
    }
  }

  removeItem(productId: number): void {
    this.cartService.removeFromCart(productId);
  }

  continueShopping(): void {
    this.router.navigate(['/products']);
  }

  checkout(): void {
    if (this.cartItems.length > 0) {
      this.router.navigate(['/checkout']);
    }
  }

  getDiscount(item: CartItem): number {
    return (item.product.originalPrice - item.product.price) * item.quantity;
  }

  getTotalDiscount(): number {
    return this.cartItems.reduce((total, item) => {
      return total + this.getDiscount(item);
    }, 0);
  }

  getDeliveryCharge(): number {
    return this.cartTotal > 500 ? 0 : 50;
  }

  getFinalTotal(): number {
    return this.cartTotal + this.getDeliveryCharge();
  }
}
