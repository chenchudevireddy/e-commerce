import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { ProductService } from '../../services/product.service';
import { Product } from '../../models/product.model';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.scss']
})
export class HomeComponent implements OnInit {
  featuredProducts: Product[] = [];
  categories: string[] = [];

  constructor(
    private productService: ProductService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadFeaturedProducts();
    this.loadCategories();
  }

  loadFeaturedProducts(): void {
    this.productService.getProducts().subscribe(products => {
      this.featuredProducts = products
        .sort((a, b) => b.rating - a.rating)
        .slice(0, 8);
    });
  }

  loadCategories(): void {
    this.productService.getCategories().subscribe(categories => {
      this.categories = categories;
    });
  }

  browseCategory(category: string): void {
    this.router.navigate(['/products'], {
      queryParams: { category }
    });
  }

  viewProduct(product: Product): void {
    this.router.navigate(['/product', product.id]);
  }

  viewAllProducts(): void {
    this.router.navigate(['/products']);
  }

  getCategoryIcon(category: string): string {
    const icons: { [key: string]: string } = {
      'Electronics': 'fas fa-laptop',
      'Computers': 'fas fa-desktop',
      'Mobile Phones': 'fas fa-mobile-alt',
      'Wearables': 'fas fa-watch',
      'Tablets': 'fas fa-tablet-alt',
      'Cameras': 'fas fa-camera',
      'Gaming': 'fas fa-gamepad',
      'Accessories': 'fas fa-headphones',
      'Monitors': 'fas fa-monitor',
      'Storage': 'fas fa-database'
    };
    return icons[category] || 'fas fa-box';
  }
}
