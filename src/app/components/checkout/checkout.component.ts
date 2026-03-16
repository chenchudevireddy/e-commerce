import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { CartService } from '../../services/cart.service';
import { CartItem } from '../../models/product.model';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-checkout',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './checkout.component.html',
  styleUrls: ['./checkout.component.scss']
})
export class CheckoutComponent implements OnInit {
  cartItems: CartItem[] = [];
  cartTotal: number = 0;
  deliveryCharge: number = 0;
  finalTotal: number = 0;

  // Form data
  firstName: string = '';
  lastName: string = '';
  email: string = '';
  phone: string = '';
  address: string = '';
  city: string = '';
  state: string = '';
  pincode: string = '';
  cardNumber: string = '';
  expiryDate: string = '';
  cvv: string = '';

  currentStep: number = 1;
  orderPlaced: boolean = false;

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
      this.calculateTotals();
      if (items.length === 0) {
        this.router.navigate(['/cart']);
      }
    });
  }

  calculateTotals(): void {
    this.cartTotal = this.cartService.getCartTotal();
    this.deliveryCharge = this.cartTotal > 500 ? 0 : 50;
    this.finalTotal = this.cartTotal + this.deliveryCharge;
  }

  goToStep(step: number): void {
    if (step < this.currentStep || this.validateStep(this.currentStep)) {
      this.currentStep = step;
    }
  }

  validateStep(step: number): boolean {
    if (step === 1) {
      return (
        this.firstName.trim() !== '' &&
        this.lastName.trim() !== '' &&
        this.email.trim() !== '' &&
        this.phone.trim() !== ''
      );
    } else if (step === 2) {
      return (
        this.address.trim() !== '' &&
        this.city.trim() !== '' &&
        this.state.trim() !== '' &&
        this.pincode.trim() !== ''
      );
    }
    return true;
  }

  nextStep(): void {
    if (this.validateStep(this.currentStep)) {
      this.currentStep++;
    } else {
      alert('Please fill all required fields');
    }
  }

  placeOrder(): void {
    if (this.cardNumber.length >= 13 && this.cvv.length === 3) {
      this.orderPlaced = true;
      setTimeout(() => {
        this.cartService.clearCart();
        this.router.navigate(['/']);
      }, 3000);
    } else {
      alert('Please enter valid payment details');
    }
  }

  goBack(): void {
    this.router.navigate(['/cart']);
  }
}
