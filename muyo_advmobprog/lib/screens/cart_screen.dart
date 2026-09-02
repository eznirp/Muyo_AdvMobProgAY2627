import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import 'product_detail_screen.dart';
import '../widgets/custom_text.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService cartService = CartService();
  final ProductService productService = ProductService();
  late Future<Cart> futureCart;
  final Map<int, int> quantityOverrides = {};

  @override
  void initState() {
    super.initState();
    // Enhancement 3: Load one user's cart through /carts/user/{userId}.
    futureCart = cartService.getCartById(1);
    cartService.addListener(_refreshCart);
  }

  @override
  void dispose() {
    cartService.removeListener(_refreshCart);
    super.dispose();
  }

  void _refreshCart() {
    if (!mounted) return;
    setState(() {
      futureCart = cartService.getCartById(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartContent = FutureBuilder<Cart>(
      future: futureCart,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('No cart found'));
        }

        final cart = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            ...cart.products.map((product) => _buildProductCard(product)),
            const SizedBox(height: 8),
            _buildSummary(cart),
          ],
        );
      },
    );

    if (widget.embedded) {
      return cartContent;
    }

    return Scaffold(
      appBar: AppBar(title: const CustomText(text: 'Cart'), centerTitle: true),
      body: cartContent,
    );
  }

  Widget _buildProductCard(CartProduct product) {
    final quantity = quantityOverrides[product.id] ?? product.quantity;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Enhancement 1: Cart products open the detail screen.
        onTap: () async {
          try {
            final fullProduct = await productService.getProductById(product.id);
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: fullProduct),
              ),
            );
          } catch (error) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Unable to open product: $error')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Image.network(
                product.thumbnail,
                width: 76,
                height: 76,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox(
                  width: 76,
                  height: 76,
                  child: Icon(Icons.image, size: 32),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: product.title,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    CustomText(
                      text: '\$${product.price.toStringAsFixed(2)}',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    CustomText(
                      text:
                          '${product.discountPercentage.toStringAsFixed(0)}% off · '
                          '\$${product.discountedTotal.toStringAsFixed(2)} total',
                      fontSize: 10,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  _quantityButton(
                    icon: Icons.add,
                    onPressed: () => _changeQuantity(product, 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: CustomText(text: '$quantity', fontSize: 12),
                  ),
                  _quantityButton(
                    icon: Icons.remove,
                    onPressed: quantity > 1
                        ? () => _changeQuantity(product, -1)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quantityButton({required IconData icon, VoidCallback? onPressed}) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 18,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }

  Widget _buildSummary(Cart cart) {
    final subtotal = cart.products.fold<double>(
      0,
      (total, product) =>
          total +
          product.price * (quantityOverrides[product.id] ?? product.quantity),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const CustomText(text: 'Subtotal:', fontSize: 12),
            CustomText(
              text: '\$${subtotal.toStringAsFixed(2)}',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const CustomText(text: 'Delivery Fee:', fontSize: 12),
            const CustomText(
              text: '\$0.00',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Order confirmed!')));
            },
            child: const Text('Confirm Order'),
          ),
        ),
      ],
    );
  }

  void _changeQuantity(CartProduct product, int change) {
    final current = quantityOverrides[product.id] ?? product.quantity;
    setState(() {
      quantityOverrides[product.id] = (current + change).clamp(1, 99);
    });
  }
}
