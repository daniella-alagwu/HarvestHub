import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../application/products/product_provider.dart';
import '../../../theme/colors/app_colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/pill_search_field.dart';
import '../../../widgets/product_list_tile.dart';
import '../product/product_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  static const routeName = '/customer/search';

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      if (provider.filteredProducts.isEmpty) provider.load();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final results = products.filteredProducts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Find local food', style: AppTextStyles.headingLarge),
              const SizedBox(height: 14),
              PillSearchField(
                hint: 'Search fruits, veggies, farmers…',
                controller: _controller,
                onChanged: products.setSearchQuery,
              ),
              const SizedBox(height: 16),
              Text('FILTER BY', style: AppTextStyles.caption.copyWith(letterSpacing: 0.8)),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = products.categories[index];
                    final isSelected = products.selectedCategory == category;
                    return ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (_) => products.setCategory(category),
                      selectedColor: AppColors.mainGreen,
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                      labelStyle: AppTextStyles.caption.copyWith(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${results.length} results', style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      Text('Closest first', style: AppTextStyles.bodyMuted),
                      const Icon(Icons.expand_more, size: 18, color: AppColors.textSecondary),
                    ],
                  ),
                ],
              ),
              const Divider(height: 16, color: AppColors.border),
              Expanded(
                child: results.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off,
                        title: 'No matches found',
                        subtitle: 'Try a different search term or filter.',
                      )
                    : ListView.separated(
                        itemCount: results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (context, index) {
                          final product = results[index];
                          return ProductListTile(
                            product: product,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProductDetailsScreen(productId: product.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}