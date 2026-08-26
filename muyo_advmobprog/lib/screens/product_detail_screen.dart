import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/product.dart';
import '../services/cart_service.dart';
import '../widgets/custom_text.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final mainImage = product.images.isNotEmpty
        ? product.images.first
        : product.thumbnail;

    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 280.h,
                color: Theme.of(context).colorScheme.surface,
                child: Hero(
                  // Preserve the shared image transition from the product list.
                  tag: 'product-${product.id}',
                  child: Image.network(
                    mainImage,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.image, size: 64.0),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Chip(label: Text(product.category)),
                    const SizedBox(height: 12.0),
                    CustomText(
                      text: product.title,
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        CustomText(
                          text: '\$${product.price.toStringAsFixed(2)}',
                          fontSize: 20.0,
                          fontWeight: FontWeight.w700,
                        ),
                        const Spacer(),
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 4.0),
                        CustomText(
                          text: product.rating.toStringAsFixed(1),
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    CustomText(text: product.description, fontSize: 14.0),
                    const SizedBox(height: 24.0),
                    _DetailRow(label: 'Brand', value: _fallback(product.brand)),
                    _DetailRow(label: 'SKU', value: _fallback(product.sku)),
                    _DetailRow(label: 'Stock', value: '${product.stock} items'),
                    _DetailRow(
                      label: 'Availability',
                      value: _fallback(product.availabilityStatus),
                    ),
                    _DetailRow(
                      label: 'Warranty',
                      value: _fallback(product.warrantyInformation),
                    ),
                    _DetailRow(
                      label: 'Shipping',
                      value: _fallback(product.shippingInformation),
                    ),
                    _DetailRow(
                      label: 'Return Policy',
                      value: _fallback(product.returnPolicy),
                    ),
                    if (product.tags.isNotEmpty) ...[
                      const SizedBox(height: 16.0),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: product.tags
                            .map((tag) => Chip(label: Text(tag)))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 24.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        // Enhancement 3: Add the displayed product to user 1's cart.
                        onPressed: () async {
                          try {
                            await CartService().addToCart(product.id, 1, 1);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Product added to cart'),
                              ),
                            );
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Unable to add product: $error'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Add to Cart'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fallback(String value) {
    return value.trim().isEmpty ? 'N/A' : value;
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.0,
            child: CustomText(
              text: label,
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(child: CustomText(text: value, fontSize: 13.0)),
        ],
      ),
    );
  }
}
