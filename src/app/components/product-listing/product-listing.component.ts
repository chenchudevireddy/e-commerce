import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { ProductService } from '../../services/product.service';
import { CartService } from '../../services/cart.service';
import { Product } from '../../models/product.model';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-product-listing',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './product-listing.component.html',
  styleUrls: ['./product-listing.component.scss']
})
export class ProductListingComponent implements OnInit {
  products: Product[] = [];
  filteredProducts: Product[] = [];
  categories: string[] = [];
  selectedCategory: string = '';
  sortBy: string = 'relevance';
  viewType: string = 'grid';

  constructor(
    private productService: ProductService,
    private cartService: CartService,
    private route: ActivatedRoute,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadProducts();
    this.loadCategories();

    this.route.queryParams.subscribe(params => {
      if (params['search']) {
        this.searchProducts(params['search']);
      }
      if (params['category']) {
        this.filterByCategory(params['category']);
      }
    });
  }

  loadProducts(): void {
    this.productService.getProducts().subscribe(products => {
      this.products = products;
      this.filteredProducts = products;
      this.applySort();
    });
  }

  loadCategories(): void {
    this.productService.getCategories().subscribe(categories => {
      this.categories = categories;
    });
  }

  filterByCategory(category: string): void {
    this.selectedCategory = category;
    if (category === '') {
      this.filteredProducts = this.products;
    } else {
      this.productService.getProductsByCategory(category).subscribe(products => {
        this.filteredProducts = products;
        this.applySort();
      });
    }
  }

  searchProducts(query: string): void {
    this.productService.searchProducts(query).subscribe(products => {
      this.filteredProducts = products;
      this.applySort();
    });
  }

  applySort(): void {
    const products = [...this.filteredProducts];

    switch (this.sortBy) {
      case 'price-low':
        products.sort((a, b) => a.price - b.price);
        break;
      case 'price-high':
        products.sort((a, b) => b.price - a.price);
        break;
      case 'rating':
        products.sort((a, b) => b.rating - a.rating);
        break;
      case 'discount':
        products.sort((a, b) => b.discount - a.discount);
        break;
      default:
        break;
    }

    this.filteredProducts = products;
  }

  onSortChange(): void {
    this.applySort();
  }

  viewProduct(product: Product): void {
    this.router.navigate(['/product', product.id]);
  }

  addToCart(product: Product, event: Event): void {
    event.stopPropagation();
    this.cartService.addToCart(product, 1);
    alert(`${product.name} added to cart!`);
  }

  getDiscountedPrice(product: Product): number {
    return Math.round(product.price);
  }
}
