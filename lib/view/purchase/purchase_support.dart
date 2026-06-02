import '../../screen.dart';

String purchaseStatusLabel(String? status) {
  final normalized = status?.trim();
  if (normalized == null || normalized.isEmpty) {
    return '';
  }
  return normalized.replaceAll('_', ' ').titleCase;
}

bool purchaseDocumentIsDraftEditable(String? status) {
  final normalized = (status ?? '').trim().toLowerCase();
  return normalized.isEmpty || normalized == 'draft';
}

String purchaseReadOnlyMessage(String documentLabel, String? status) {
  final label = purchaseStatusLabel(status);
  if (label.isEmpty) {
    return 'This $documentLabel is read-only.';
  }
  return 'This $documentLabel is ${label.toLowerCase()}. Details are read-only.';
}

List<PartyModel> purchaseSuppliers({
  required List<PartyModel> parties,
  required List<PartyTypeModel> partyTypes,
}) {
  final supplierTypeIds = partyTypes
      .where(_looksLikeSupplierType)
      .map((item) => intValue(item.toJson(), 'id'))
      .whereType<int>()
      .toSet();

  return parties
      .where(
        (party) =>
            party.isActive && supplierTypeIds.contains(party.partyTypeId),
      )
      .toList(growable: false);
}

bool _looksLikeSupplierType(PartyTypeModel type) {
  final data = type.toJson();
  final code =
      (stringValue(data, 'code').isNotEmpty
              ? stringValue(data, 'code')
              : stringValue(data, 'type_code'))
          .trim()
          .toLowerCase();
  final name =
      (stringValue(data, 'name').isNotEmpty
              ? stringValue(data, 'name')
              : stringValue(data, 'type_name'))
          .trim()
          .toLowerCase();
  return code.contains('supplier') ||
      code.contains('vendor') ||
      name.contains('supplier') ||
      name.contains('vendor');
}

TaxCodeModel? purchaseTaxCodeById(List<TaxCodeModel> taxCodes, int? taxCodeId) {
  if (taxCodeId == null) {
    return null;
  }

  return taxCodes.cast<TaxCodeModel?>().firstWhere(
    (taxCode) => taxCode?.id == taxCodeId,
    orElse: () => null,
  );
}

class PurchaseLineTaxBreakdown {
  const PurchaseLineTaxBreakdown({
    required this.taxable,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.cess,
    required this.total,
  });

  final double taxable;
  final double cgst;
  final double sgst;
  final double igst;
  final double cess;
  final double total;
}

class PurchaseDocumentTaxSummary {
  const PurchaseDocumentTaxSummary({
    required this.taxable,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.cess,
    required this.total,
  });

  final double taxable;
  final double cgst;
  final double sgst;
  final double igst;
  final double cess;
  final double total;
}

PurchaseLineTaxBreakdown computePurchaseLineTaxBreakdown({
  required double qty,
  required double rate,
  required double discountPercent,
  required TaxCodeModel? taxCode,
  double? taxPercent,
  String? taxType,
}) {
  final gross = qty > 0 && rate >= 0 ? qty * rate : 0.0;
  final clampedDiscount = discountPercent.clamp(0, 100).toDouble();
  final taxable = roundToDouble(gross * (1 - (clampedDiscount / 100)), 2);
  var resolvedTaxPercent = (taxPercent ?? taxCode?.taxRate ?? 0).toDouble();
  final resolvedTaxType =
      (taxType ??
              taxCode?.taxType ??
              taxCode?.toJson()['tax_application']?.toString() ??
              '')
          .trim()
          .toLowerCase();
  final cessRate = (taxCode?.cessRate ?? 0).toDouble();

  var cgst = 0.0;
  var sgst = 0.0;
  var igst = 0.0;

  switch (resolvedTaxType) {
    case 'igst':
      igst = roundToDouble((taxable * resolvedTaxPercent) / 100, 2);
      break;
    case 'cess_only':
    case 'exempt':
    case 'nil_rated':
    case 'non_gst':
      resolvedTaxPercent = 0.0;
      break;
    default:
      cgst = roundToDouble((taxable * resolvedTaxPercent) / 200, 2);
      sgst = roundToDouble((taxable * resolvedTaxPercent) / 200, 2);
      break;
  }

  final cess = roundToDouble((taxable * cessRate) / 100, 2);

  return PurchaseLineTaxBreakdown(
    taxable: taxable,
    cgst: cgst,
    sgst: sgst,
    igst: igst,
    cess: cess,
    total: roundToDouble(taxable + cgst + sgst + igst + cess, 2),
  );
}

PurchaseDocumentTaxSummary summarizePurchaseLineTaxes(
  Iterable<PurchaseLineTaxBreakdown> lines,
) {
  double taxable = 0;
  double cgst = 0;
  double sgst = 0;
  double igst = 0;
  double cess = 0;

  for (final line in lines) {
    taxable += line.taxable;
    cgst += line.cgst;
    sgst += line.sgst;
    igst += line.igst;
    cess += line.cess;
  }

  return PurchaseDocumentTaxSummary(
    taxable: taxable,
    cgst: cgst,
    sgst: sgst,
    igst: igst,
    cess: cess,
    total: taxable + cgst + sgst + igst + cess,
  );
}

Set<int> allowedUomIdsForItem(
  ItemModel? item,
  List<UomConversionModel> conversions,
) {
  if (item == null) {
    return <int>{};
  }

  final seedIds = <int>{
    if (item.baseUomId != null) item.baseUomId!,
    if (item.purchaseUomId != null) item.purchaseUomId!,
    if (item.salesUomId != null) item.salesUomId!,
  };

  if (seedIds.isEmpty) {
    return <int>{};
  }

  final allowed = <int>{...seedIds};
  final pending = List<int>.from(seedIds);

  while (pending.isNotEmpty) {
    final currentId = pending.removeLast();
    for (final conversion in conversions) {
      final fromId = conversion.fromUomId;
      final toId = conversion.toUomId;
      if (fromId == null || toId == null) {
        continue;
      }

      if (fromId == currentId && allowed.add(toId)) {
        pending.add(toId);
      }
      if (toId == currentId && allowed.add(fromId)) {
        pending.add(fromId);
      }
    }
  }

  return allowed;
}

List<UomModel> allowedUomsForItem(
  ItemModel? item,
  List<UomModel> uoms,
  List<UomConversionModel> conversions,
) {
  final allowedIds = allowedUomIdsForItem(item, conversions);
  if (allowedIds.isEmpty) {
    return const <UomModel>[];
  }

  return uoms
      .where((uom) => uom.id != null && allowedIds.contains(uom.id))
      .toList(growable: false);
}

int? defaultUomIdForItem(
  ItemModel? item,
  List<UomModel> uoms,
  List<UomConversionModel> conversions, {
  int? current,
}) {
  final allowedIds = allowedUomIdsForItem(item, conversions);
  if (current != null && (allowedIds.isEmpty || allowedIds.contains(current))) {
    return current;
  }

  final preferred = <int?>[
    item?.purchaseUomId,
    item?.baseUomId,
    item?.salesUomId,
  ];
  for (final id in preferred) {
    if (id != null && (allowedIds.isEmpty || allowedIds.contains(id))) {
      return id;
    }
  }

  final allowed = allowedUomsForItem(item, uoms, conversions);
  return allowed.isNotEmpty ? allowed.first.id : null;
}

class PurchaseListCard<T> extends StatefulWidget {
  const PurchaseListCard({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.emptyMessage,
    required this.searchController,
    required this.searchHint,
    this.statusValue,
    this.statusItems = const <AppDropdownItem<String>>[],
    this.onStatusChanged,
    required this.itemBuilder,
  });

  final List<T> items;
  final T? selectedItem;
  final String emptyMessage;
  final TextEditingController searchController;
  final String searchHint;
  final String? statusValue;
  final List<AppDropdownItem<String>> statusItems;
  final ValueChanged<String?>? onStatusChanged;
  final Widget Function(T item, bool selected) itemBuilder;

  static const double listViewportHeight = 520;

  @override
  State<PurchaseListCard<T>> createState() => _PurchaseListCardState<T>();
}

class _PurchaseListCardController extends GetxController {
  int currentPage = 1;

  int totalPages(int itemCount) {
    if (itemCount <= 0) {
      return 1;
    }
    return ((itemCount + kLocalListPageSize - 1) / kLocalListPageSize).floor();
  }

  void syncItemCountChange(int itemCount) {
    final total = totalPages(itemCount);
    if (currentPage > total) {
      currentPage = total;
      update();
    }
  }

  void resetToFirstPage() {
    if (currentPage != 1) {
      currentPage = 1;
      update();
    }
  }

  void setPage(int page) {
    if (currentPage == page) {
      return;
    }
    currentPage = page;
    update();
  }
}

class _PurchaseListCardState<T> extends State<PurchaseListCard<T>> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'PurchaseListCardController',
      scope: <String, Object?>{'identity': identityHashCode(widget)},
    );
    Get.put(_PurchaseListCardController(), tag: _controllerTag);
  }

  @override
  void dispose() {
    Get.delete<_PurchaseListCardController>(tag: _controllerTag, force: true);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PurchaseListCard<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controller = Get.find<_PurchaseListCardController>(
      tag: _controllerTag,
    );
    if (!identical(oldWidget.items, widget.items)) {
      controller.resetToFirstPage();
    }
    controller.syncItemCountChange(widget.items.length);
    controller.update();
  }

  List<T> _pagedItems(int currentPage) {
    if (widget.items.isEmpty) {
      return <T>[];
    }

    final start = (currentPage - 1) * kLocalListPageSize;
    if (start >= widget.items.length) {
      return <T>[];
    }

    final end = (start + kLocalListPageSize) > widget.items.length
        ? widget.items.length
        : (start + kLocalListPageSize);
    return widget.items.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<_PurchaseListCardController>(
      tag: _controllerTag,
      builder: (controller) {
        final visibleItems = _pagedItems(controller.currentPage);

        return AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: widget.searchController,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              if (widget.statusItems.isNotEmpty &&
                  widget.onStatusChanged != null) ...[
                const SizedBox(height: AppUiConstants.spacingSm),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Status',
                  mappedItems: widget.statusItems,
                  initialValue: widget.statusValue,
                  onChanged: widget.onStatusChanged!,
                ),
              ],
              const SizedBox(height: AppUiConstants.spacingMd),
              if (widget.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppUiConstants.spacingXl,
                  ),
                  child: Text(widget.emptyMessage),
                )
              else
                SizedBox(
                  height: PurchaseListCard.listViewportHeight,
                  child: ListView.separated(
                    primary: false,
                    itemCount: visibleItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppUiConstants.spacingXs),
                    itemBuilder: (context, index) => widget.itemBuilder(
                      visibleItems[index],
                      visibleItems[index] == widget.selectedItem,
                    ),
                  ),
                ),
              LocalPageNavigation(
                totalItems: widget.items.length,
                currentPage: controller.currentPage,
                onPageChanged: controller.setPage,
              ),
            ],
          ),
        );
      },
    );
  }
}

class PurchaseCompactLineCard extends StatelessWidget {
  const PurchaseCompactLineCard({
    super.key,
    required this.index,
    required this.total,
    required this.child,
    this.onRemove,
    this.removeEnabled = true,
  });

  final int index;
  final int total;
  final Widget child;
  final VoidCallback? onRemove;
  final bool removeEnabled;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    return AppSectionCard(
      padding: const EdgeInsets.all(AppUiConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppUiConstants.spacingSm,
                  vertical: AppUiConstants.spacingXxs,
                ),
                decoration: BoxDecoration(
                  color: appTheme.subtleFill,
                  borderRadius: BorderRadius.circular(
                    AppUiConstants.pillRadius,
                  ),
                ),
                child: Text(
                  total > 1 ? '#${index + 1}' : 'Line',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: removeEnabled ? onRemove : null,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          child,
        ],
      ),
    );
  }
}

class PurchaseCompactFieldGrid extends StatelessWidget {
  const PurchaseCompactFieldGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppUiConstants.spacingSm;
        final width = constraints.maxWidth;
        final columns = width >= 1320
            ? 4
            : width >= 980
            ? 3
            : width >= 620
            ? 2
            : 1;
        final itemWidth = columns == 1
            ? width
            : (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map(
                (child) => SizedBox(
                  width: itemWidth > 0 ? itemWidth : width,
                  child: child,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}
