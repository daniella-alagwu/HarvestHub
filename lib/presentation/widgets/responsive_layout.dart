import 'package:flutter/material.dart';


const double kContentMaxWidth = 1100;

double pageSidePadding(BuildContext context, {double base = 16}) {
  final width = MediaQuery.sizeOf(context).width;
  return width > kContentMaxWidth
      ? (width - kContentMaxWidth) / 2 + base
      : base;
}

const productGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 190,
  mainAxisSpacing: 16,
  crossAxisSpacing: 14,
  childAspectRatio: 0.76,
);