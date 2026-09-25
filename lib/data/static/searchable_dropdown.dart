import 'package:flutter/material.dart';
import '../../presentation/theme/colors/app_colors.dart';
import '../../presentation/theme/text_styles.dart';

class SearchableDropdown<T> extends FormField<T> {
  SearchableDropdown({
    super.key,
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
    IconData? icon,
    String? hint,
    String searchHint = 'Search',
    String? Function(T?)? validator,
  }) : super(
          initialValue: value,
          validator: validator,
          builder: (state) {
            Future<void> open(BuildContext context) async {
              final result = await showModalBottomSheet<T>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => _SearchSheet<T>(
                  items: items,
                  itemLabel: itemLabel,
                  searchHint: searchHint,
                ),
              );
              if (result != null) {
                state.didChange(result);
                onChanged(result);
              }
            }

            final current = state.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyRegular
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) => InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => open(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: state.hasError
                                ? AppColors.error
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (icon != null) ...[
                              Icon(icon, color: AppColors.mainGreen, size: 20),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: Text(
                                current != null
                                    ? itemLabel(current)
                                    : (hint ?? ''),
                                style: AppTextStyles.bodyRegular.copyWith(
                                  color: current != null
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        state.errorText ?? '',
                        style: AppTextStyles.bodyMuted
                            .copyWith(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                ],
              ),
            );
          },
        );
}

class _SearchSheet<T> extends StatefulWidget {
  const _SearchSheet({
    required this.items,
    required this.itemLabel,
    required this.searchHint,
  });

  final List<T> items;
  final String Function(T) itemLabel;
  final String searchHint;

  @override
  State<_SearchSheet<T>> createState() => _SearchSheetState<T>();
}

class _SearchSheetState<T> extends State<_SearchSheet<T>> {
  final _query = TextEditingController();
  late List<T> _filtered = widget.items;

  void _filter(String q) {
    setState(() {
      final needle = q.trim().toLowerCase();
      _filtered = widget.items
          .where((item) =>
              needle.isEmpty ||
              widget.itemLabel(item).toLowerCase().contains(needle))
          .toList();
    });
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  controller: _query,
                  autofocus: false,
                  onChanged: _filter,
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    hintStyle: AppTextStyles.bodyMuted,
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textSecondary, size: 20),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text('No matches',
                            style: AppTextStyles.bodyMuted),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: AppColors.border),
                        itemBuilder: (context, i) {
                          final item = _filtered[i];
                          return ListTile(
                            title: Text(widget.itemLabel(item),
                                style: AppTextStyles.bodyRegular),
                            onTap: () => Navigator.of(context).pop(item),
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