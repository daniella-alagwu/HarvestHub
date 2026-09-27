import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/product_model.dart';
import '../../data/models/farmer_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/farmer_repository.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider({
    ProductRepository? productRepository,
    FarmerRepository? farmerRepository,
  })  : _productRepository =
            productRepository ?? ProductRepository(),
        _farmerRepository =
            farmerRepository ?? FarmerRepository();

  final ProductRepository _productRepository;
  final FarmerRepository _farmerRepository;

  List<Product> _allProducts = [];
  List<Farmer> _farmers = [];

  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedCategory;

  StreamSubscription<List<Product>>? _productsSubscription;
  StreamSubscription<List<Farmer>>? _farmersSubscription;

  bool get isLoading => _isLoading;

  List<Farmer> get farmers =>
      List.unmodifiable(_farmers);

  List<Product> get allProducts =>
      List.unmodifiable(_allProducts);

  String get searchQuery => _searchQuery;

  String? get selectedCategory =>
      _selectedCategory;

  List<String> get categories {
    final values = _allProducts
        .map((p) => p.category?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return values;
  }

  List<Product> get freshToday => _allProducts
      .where((product) => product.isInStock)
      .take(4)
      .toList();

  List<Product> productsByFarmer(
    String farmerId,
  ) {
    return _allProducts
        .where(
          (product) =>
              product.farmerId == farmerId,
        )
        .toList();
  }

  List<Product> get filteredProducts {
    return _allProducts.where((product) {
      final query =
          _searchQuery.trim().toLowerCase();

      final matchesQuery =
          query.isEmpty ||
          product.name
              .toLowerCase()
              .contains(query) ||
          (product.category ?? '')
              .toLowerCase()
              .contains(query) ||
          product.farmerName
              .toLowerCase()
              .contains(query);

      final matchesCategory =
          _selectedCategory == null ||
          product.category == _selectedCategory;

      return matchesQuery && matchesCategory;
    }).toList();
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    await _productsSubscription?.cancel();
    await _farmersSubscription?.cancel();

    try {
      final initial = await Future.wait([
        _productRepository.fetchAll(),
        _farmerRepository.fetchAll(),
      ]);

      _applyData(
        initial[0] as List<Product>,
        initial[1] as List<Farmer>,
      );

      _productsSubscription =
          _productRepository.watchAll().listen(
        (products) {
          _applyData(
            products,
            _farmers,
          );
        },
      );

      _farmersSubscription =
          _farmerRepository.watchAll().listen(
        (farmers) {
          _applyData(
            _allProducts,
            farmers,
          );
        },
      );
    } catch (e) {
      debugPrint(
        'Product load failed: $e',
      );

      _allProducts = [];
      _farmers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyData(
    List<Product> products,
    List<Farmer> farmers,
  ) {
    final farmersById = {
      for (final farmer in farmers)
        farmer.id: farmer,
    };

    _allProducts = products.map((product) {
      final farmer =
          farmersById[product.farmerId];

      if (farmer == null) {
        return product;
      }

      return product.copyWith(
        farmerName:
            product.farmerName.isNotEmpty
                ? product.farmerName
                : farmer.businessName,
        marketName:
            product.marketName.isNotEmpty
                ? product.marketName
                : farmer.marketName,
        distanceMiles:
            product.distanceMiles > 0
                ? product.distanceMiles
                : farmer.distanceMiles,
      );
    }).toList();

    _farmers = List.of(farmers);

    notifyListeners();
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    _farmersSubscription?.cancel();
    super.dispose();
  }

  Future<Product?> productById(
    String id,
  ) async {
    final product =
        await _productRepository.fetchById(id);

    if (product == null) {
      return null;
    }

    final farmer =
        await farmerById(product.farmerId);

    if (farmer == null) {
      return product;
    }

    return product.copyWith(
      farmerName:
          product.farmerName.isNotEmpty
              ? product.farmerName
              : farmer.businessName,
      marketName:
          product.marketName.isNotEmpty
              ? product.marketName
              : farmer.marketName,
      distanceMiles:
          product.distanceMiles > 0
              ? product.distanceMiles
              : farmer.distanceMiles,
    );
  }

  Future<Farmer?> farmerById(
    String id,
  ) {
    return _farmerRepository.fetchById(id);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String? category) {
    _selectedCategory =
        _selectedCategory == category
            ? null
            : category;

    notifyListeners();
  }
}