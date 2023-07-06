import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_macro_nutrients.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_nutriments_table.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_info_button.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_placeholder.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MealDetailScreen extends StatefulWidget {
  const MealDetailScreen({Key? key}) : super(key: key);

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  static const _containerSize = 300.0;

  final log = Logger('ItemDetailScreen');

  late MealDetailBloc _mealDetailBloc;
  final _scrollController = ScrollController();

  late MealEntity product;
  late IntakeTypeEntity intakeTypeEntity;
  late TextEditingController quantityTextController;

  late double totalQuantity;
  late double totalKcal;
  late double totalCarbs;
  late double totalFat;
  late double totalProtein;

  @override
  void initState() {
    _mealDetailBloc = locator<MealDetailBloc>();
    quantityTextController = TextEditingController();
    quantityTextController.text = '100';
    totalQuantity = 100;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    final args =
        ModalRoute.of(context)?.settings.arguments as MealDetailScreenArguments;
    product = args.productEntity;
    intakeTypeEntity = args.intakeTypeEntity;
    totalKcal = product.nutriments.energyKcal100 ?? 0;
    totalCarbs = product.nutriments.carbohydrates100g ?? 0;
    totalFat = product.nutriments.fat100g ?? 0;
    totalProtein = product.nutriments.fat100g ?? 0;
    quantityTextController.addListener(() {
      _onQuantityChanged(quantityTextController.text);
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${product.name}')),
      body: ListView(
        controller: _scrollController,
        children: [
          Stack(children: [
            CachedNetworkImage(
              cacheManager: locator<CacheManager>(),
              imageUrl: product.mainImageUrl ?? "",
              imageBuilder: (context, imageProvider) {
                return Container(
                  height: _containerSize,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: imageProvider, fit: BoxFit.cover)),
                );
              },
              placeholder: (context, string) => const MealPlaceholder(),
              errorWidget: (context, url, error) => const MealPlaceholder(),
            ),
            product.brands != null
                ? Align(
                    alignment: AlignmentDirectional.topStart,
                    child: Card(
                      child: SizedBox(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${product.brands}',
                              style: Theme.of(context).textTheme.bodyLarge),
                        ),
                      ),
                    ),
                  )
                : const SizedBox(),
            product.mealQuantity != null
                ? Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: Card(
                        child: SizedBox(
                            child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                    '${product.mealQuantity} ${product.mealUnit ?? S.of(context).gramMilliliterUnit}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge)))),
                  )
                : const SizedBox()
          ]),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('${totalKcal.toInt()} ${S.of(context).kcalLabel}',
                        style: Theme.of(context).textTheme.headlineSmall),
                    Text(
                        ' / ${totalQuantity.toInt()} ${product.mealUnit ?? S.of(context).gramMilliliterUnit}')
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    MealDetailMacroNutrients(
                        typeString: S.of(context).carbsLabel,
                        value: totalCarbs),
                    MealDetailMacroNutrients(
                        typeString: S.of(context).fatLabel, value: totalFat),
                    MealDetailMacroNutrients(
                        typeString: S.of(context).proteinLabel,
                        value: totalProtein)
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16.0),
                MealDetailNutrimentsTable(product: product),
                const SizedBox(height: 32.0),
                MealInfoButton(url: product.url, source: product.source),
                const SizedBox(height: 200.0) // height added to scroll
              ],
            ),
          )
        ],
      ),
      bottomSheet: MealDetailBottomSheet(
          product: product,
          intakeTypeEntity: intakeTypeEntity,
          quantityTextController: quantityTextController,
          mealDetailBloc: _mealDetailBloc),
    );
  }

  void scrollToCalorieText() {
    _scrollController.animateTo(_containerSize - 50,
        duration: const Duration(seconds: 1), curve: Curves.easeInOut);
  }

  void _onQuantityChanged(String quantityString) {
    setState(() {
      try {
        final energyPerUnit = (product.nutriments.energyPerUnit ?? 0);
        final carbsPerUnit = (product.nutriments.carbohydratesPerUnit ?? 0);
        final fatPerUnit = (product.nutriments.fatPerUnit ?? 0);
        final proteinPerUnit = (product.nutriments.proteinsPerUnit ?? 0);

        final quantity = double.parse(quantityString);
        totalQuantity = quantity;
        totalKcal = (quantity * energyPerUnit);
        totalCarbs = (quantity * carbsPerUnit);
        totalFat = (quantity * fatPerUnit);
        totalProtein = (quantity * proteinPerUnit);
        scrollToCalorieText();
      } on FormatException catch (_) {
        log.warning("Error while parsing: \"$quantityString\"");
      }
    });
  }
}

class MealDetailScreenArguments {
  final MealEntity productEntity;
  final IntakeTypeEntity intakeTypeEntity;

  MealDetailScreenArguments(this.productEntity, this.intakeTypeEntity);
}
