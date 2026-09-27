import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/models/product_model.dart';
import '../../../data/repositories/farmer_dashboard_repository.dart';

import '../../theme/colors/app_colors.dart';

import 'farmer_add_product_screen.dart';

class FarmerProductsScreen
    extends StatefulWidget {
  const FarmerProductsScreen({
    super.key,
    this.onBackToOverview,
  });

  final VoidCallback?
      onBackToOverview;

  @override
  State<FarmerProductsScreen>
      createState() =>
          _FarmerProductsScreenState();
}

class _FarmerProductsScreenState
    extends State<FarmerProductsScreen> {
  final _repo =
      FarmerDashboardRepository();

  String? _farmerId;

  @override
  void initState() {
    super.initState();

    _farmerId =
        FirebaseAuth.instance
            .currentUser
            ?.uid;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_farmerId == null) {
      return Scaffold(
        backgroundColor:
            AppColors.background,
        appBar: _buildAppBar(),
        body: Center(
          child: Text(
            'Not signed in.',
            style: TextStyle(
              color: AppColors
                  .textSecondary,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child:
              StreamBuilder<
                  List<ProductModel>>(
            stream:
                _repo.streamProducts(
              _farmerId!,
            ),
            builder:
                (context, snap) {
              final products =
                  snap.data ?? [];

              final lowStock =
                  products
                      .where(
                        (product) =>
                            product.stockQty <=
                            5,
                      )
                      .length;

              return Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(
                    products.length,
                    lowStock,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Expanded(
                    child: products.isEmpty
                        ? Center(
                            child: Text(
                              'No products yet. '
                              'Add your first one below.',
                              style:
                                  TextStyle(
                                color:
                                    AppColors
                                        .textMuted,
                              ),
                            ),
                          )
                        : ListView
                            .separated(
                            itemCount:
                                products.length,
                            separatorBuilder:
                                (_, __) =>
                                    const SizedBox(
                              height: 10,
                            ),
                            itemBuilder:
                                (
                              context,
                              i,
                            ) =>
                                    _buildProductRow(
                              products[i],
                            ),
                          ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  _buildAddButton(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget
      _buildAppBar() {
    return AppBar(
      backgroundColor:
          AppColors.mainGreen,
      elevation: 0,
      automaticallyImplyLeading:
          false,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: Colors.white,
        ),
        onPressed:
            onBackToOverview,
      ),
      title: const Text(
        'Inventory',
        style: TextStyle(
          color: Colors.white,
          fontWeight:
              FontWeight.w600,
        ),
      ),
      iconTheme:
          const IconThemeData(
        color: Colors.white,
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.add,
            color: Colors.white,
          ),
          onPressed: () =>
              _goToAddProduct(
            context,
          ),
        ),
        const SizedBox(
          width: 4,
        ),
      ],
    );
  }

  VoidCallback? get onBackToOverview =>
      widget.onBackToOverview;

  Widget _buildStatsRow(
    int activeCount,
    int lowStockCount,
  ) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label:
                'Active products',
            value:
                '$activeCount',
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: _MiniStat(
            label: 'Low stock',
            value:
                '$lowStockCount',
            noteColor:
                lowStockCount > 0
                    ? AppColors
                        .wheatGold
                    : AppColors
                        .textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProductRow(
    ProductModel product,
  ) {
    final isOut =
        product.stockQty <= 0;

    final isLow =
        product.stockQty > 0 &&
        product.stockQty <= 5;

    final stockColor =
        isOut
            ? AppColors.error
            : (isLow
                ? AppColors.wheatGold
                : AppColors.textMuted);

    final stockLabel =
        isOut
            ? 'Out of stock'
            : '${product.stockQty} in stock';

    return Container(
      padding:
          const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:
            AppColors.surface,
        border: Border.all(
          color: AppColors.border,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                _goToEditProduct(
              context,
              product,
            ),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    AppColors.softGreen,
                borderRadius:
                    BorderRadius.circular(
                  8,
                ),
                image: product
                            .imageUrl
                            ?.isNotEmpty ==
                        true
                    ? DecorationImage(
                        image:
                            NetworkImage(
                          product
                              .imageUrl!,
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: product.imageUrl
                          ?.isEmpty !=
                      false
                  ? Icon(
                      Icons.eco_outlined,
                      color:
                          AppColors.mainGreen,
                    )
                  : null,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  _goToEditProduct(
                context,
                product,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    product.itemName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                      color: AppColors
                          .textPrimary,
                    ),
                    overflow:
                        TextOverflow
                            .ellipsis,
                  ),
                  Text(
                    '\$${product.pricePerUnit.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors
                          .textSecondary,
                    ),
                  ),
                  Text(
                    stockLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          stockColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons
                  .remove_circle_outline,
              size: 20,
              color: AppColors
                  .textSecondary,
            ),
            onPressed:
                product.stockQty > 0
                    ? () =>
                        _repo.adjustStock(
                      product.productId,
                      -1,
                    )
                    : null,
          ),
          IconButton(
            icon: Icon(
              Icons
                  .add_circle_outline,
              size: 20,
              color: AppColors
                  .textSecondary,
            ),
            onPressed: () =>
                _repo.adjustStock(
              product.productId,
              1,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              size: 18,
              color: AppColors.error,
            ),
            onPressed: () =>
                _confirmDelete(
              product,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    ProductModel product,
  ) async {
    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
        title: const Text(
          'Remove product?',
        ),
        content: Text(
          'This will remove '
          '"${product.itemName}" '
          'from your listings.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
              context,
              false,
            ),
            child:
                const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(
              context,
              true,
            ),
            child: Text(
              'Remove',
              style: TextStyle(
                color:
                    AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repo.deleteProduct(
        product.productId,
      );
    }
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () =>
            _goToAddProduct(
          context,
        ),
        icon: const Icon(
          Icons.add,
          color: Colors.white,
          size: 18,
        ),
        label: const Text(
          'Add new product',
        ),
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              AppColors.deepGreen,
          foregroundColor:
              Colors.white,
          padding:
              const EdgeInsets.symmetric(
            vertical: 14,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
        ),
      ),
    );
  }

  void _goToAddProduct(
    BuildContext context,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const FarmerAddProductScreen(),
      ),
    );
  }

  void _goToEditProduct(
    BuildContext context,
    ProductModel product,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            FarmerAddProductScreen(
          existingProduct: product,
        ),
      ),
    );
  }
}

class _MiniStat
    extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    this.noteColor,
  });

  final String label;
  final String value;
  final Color? noteColor;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            AppColors.surface,
        border: Border.all(
          color: AppColors.border,
        ),
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors
                  .textSecondary,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
              color:
                  noteColor ??
                      AppColors
                          .textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}