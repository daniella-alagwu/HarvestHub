import 'package:flutter/foundation.dart';
import '../../data/models/product_model.dart';
import '../../data/models/farmer_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/farmer_repository.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider({
    ProductRepository? productRepository,
    FarmerRepository? farmerRepository,
  })  : _productRepository = productRepository ?? ProductRepository(),
        _farmerRepository = farmerRepository ?? FarmerRepository();

  final ProductRepository _productRepository;
  final FarmerRepository _farmerRepository;

  List<Product> _allProducts = [];
  List<Farmer> _farmers = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedCategory;

  bool get isLoading => _isLoading;
  List<Farmer> get farmers => _farmers;
  List<Product> get allProducts => _allProducts;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  List<String> get categories => _productRepository.categories;

  List<Product> get freshToday => _allProducts.take(4).toList();

  List<Product> productsByFarmer(String farmerId) =>
      _allProducts.where((product) => product.farmerId == farmerId).toList();

  List<Product> get filteredProducts {
    return _allProducts.where((product) {
      final matchesQuery = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == null || product.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    final results = await Future.wait([
      _productRepository.fetchAll(),
      _farmerRepository.fetchAll(),
    ]);
    _allProducts = results[0] as List<Product>;
    _farmers = results[1] as List<Farmer>;
    _isLoading = false;
    notifyListeners();
  }

  Future<Product?> productById(String id) => _productRepository.fetchById(id);

  Future<Farmer?> farmerById(String id) => _farmerRepository.fetchById(id);

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String? category) {
    _selectedCategory = _selectedCategory == category ? null : category;
    notifyListeners();
  }
}