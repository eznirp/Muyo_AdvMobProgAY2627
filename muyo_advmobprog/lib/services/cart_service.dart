import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/cart.dart';

class CartService extends ChangeNotifier {
  CartService._internal();

  static final CartService _instance = CartService._internal();

  factory CartService() => _instance;

  final Map<int, Cart> _cachedCarts = {};

  Future<List<Cart>> getAllCarts() async {
    final response = await http.get(Uri.parse('$host/carts'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      return cartsJson.map((json) => Cart.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load carts');
    }
  }

  Future<Cart> getCartById(int userId) async {
    final cachedCart = _cachedCarts[userId];
    if (cachedCart != null) {
      return cachedCart;
    }

    final response = await http.get(Uri.parse('$host/carts/user/$userId'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      if (cartsJson.isNotEmpty) {
        // Enhancement 3: Render the selected user's cart exactly as returned
        // by DummyJSON through /carts/user/{userId}.
        final cart = Cart.fromJson(cartsJson[0]);
        _cachedCarts[userId] = cart;
        notifyListeners();
        return cart;
      }
      throw Exception('Cart not found for user $userId');
    } else {
      throw Exception('Failed to load cart');
    }
  }

  Future<Cart> addToCart(int productId, int quantity, int userId) async {
    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'products': [
          {'id': productId, 'quantity': quantity},
        ],
        'userId': userId,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final addedCart = Cart.fromJson(jsonDecode(response.body));
      final existingCart = _cachedCarts[userId];
      final updatedCart = existingCart == null
          ? addedCart
          : _mergeAddedProduct(existingCart, addedCart, productId, quantity);
      _cachedCarts[userId] = updatedCart;
      notifyListeners();
      return updatedCart;
    } else {
      throw Exception(
        'Failed to add to cart (${response.statusCode}): ${response.body}',
      );
    }
  }

  Cart _mergeAddedProduct(
    Cart existingCart,
    Cart addedCart,
    int productId,
    int quantity,
  ) {
    final addedProduct = addedCart.products.firstWhere(
      (product) => product.id == productId,
      orElse: () => throw Exception('Added product was not returned by API'),
    );
    final products = [...existingCart.products];
    final existingIndex = products.indexWhere(
      (product) => product.id == productId,
    );
    if (existingIndex == -1) {
      products.add(addedProduct);
    } else {
      final currentProduct = products[existingIndex];
      products[existingIndex] = _copyWithQuantity(
        currentProduct,
        currentProduct.quantity + quantity,
      );
    }

    final total = products.fold<double>(
      0,
      (sum, product) => sum + product.price * product.quantity,
    );
    final discountedTotal = products.fold<double>(
      0,
      (sum, product) => sum + product.discountedTotal,
    );
    return Cart(
      id: existingCart.id,
      products: products,
      total: total,
      discountedTotal: discountedTotal,
      userId: existingCart.userId,
      totalProducts: products.length,
      totalQuantity: products.fold<int>(
        0,
        (sum, product) => sum + product.quantity,
      ),
    );
  }

  CartProduct _copyWithQuantity(CartProduct product, int quantity) {
    final total = product.price * quantity;
    final discountedTotal = total * (1 - product.discountPercentage / 100);
    return CartProduct(
      id: product.id,
      title: product.title,
      price: product.price,
      quantity: quantity,
      total: total,
      discountPercentage: product.discountPercentage,
      discountedTotal: discountedTotal,
      thumbnail: product.thumbnail,
    );
  }
}
