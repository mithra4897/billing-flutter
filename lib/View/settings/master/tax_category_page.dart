import '../../../screen.dart';

class TaxCategoryManagementPage extends StatefulWidget {
  const TaxCategoryManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<TaxCategoryManagementPage> createState() =>
      _TaxCategoryManagementPageState();
}

class _TaxCategoryManagementPageState extends State<TaxCategoryManagementPage> {
  static const List<AppDropdownItem<String>> _taxTypeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'gst', label: 'GST'),
        AppDropdownItem(value: 'igst', label: 'IGST'),
        AppDropdownItem(value: 'cgst_sgst', label: 'CGST + SGST'),
        AppDropdownItem(value: 'cess', label: 'CESS'),
        AppDropdownItem(value: 'none', label: 'No Tax'),
      ];

  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _cessRateController = TextEditingController();
  final TextEditingController _hsnSacController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<TaxCodeModel> _taxCodes = const <TaxCodeModel>[];
  List<TaxCodeModel> _filteredTaxCodes = const <TaxCodeModel>[];
  TaxCodeModel? _selectedTaxCode;
  String _taxType = 'gst';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadTaxCodes();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _searchController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _rateController.dispose();
    _cessRateController.dispose();
    _hsnSacController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadTaxCodes({int? selectId}) async {
    setState(() {
      _initialLoading = _taxCodes.isEmpty;
      _pageError = null;
    });

    try {
      final response = await _masterService.taxCodes(
        filters: const {'per_page': 100, 'sort_by': 'tax_name'},
      );
      final items = response.data ?? const <TaxCodeModel>[];
      if (!mounted) {
        return;
      }

      setState(() {
        _taxCodes = items;
        _filteredTaxCodes = filterMasterList(items, _searchController.text, (
          taxCode,
        ) {
          return [
            taxCode.taxCode ?? '',
            taxCode.taxName ?? '',
            taxCode.taxType ?? '',
          ];
        });
        _initialLoading = false;
      });

      final selected = selectId != null
          ? items.cast<TaxCodeModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedTaxCode == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<TaxCodeModel?>().firstWhere(
                    (item) => item?.id == _selectedTaxCode?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        _selectTaxCode(selected);
      } else {
        _resetForm();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _initialLoading = false;
        _pageError = error.toString();
      });
    }
  }

  void _applySearch() {
    setState(() {
      _filteredTaxCodes = filterMasterList(
        _taxCodes,
        _searchController.text,
        (taxCode) => [
          taxCode.taxCode ?? '',
          taxCode.taxName ?? '',
          taxCode.taxType ?? '',
        ],
      );
    });
  }

  void _selectTaxCode(TaxCodeModel taxCode) {
    _selectedTaxCode = taxCode;
    _codeController.text = taxCode.taxCode ?? '';
    _nameController.text = taxCode.taxName ?? '';
    _rateController.text = taxCode.taxRate?.toString() ?? '';
    _cessRateController.text = taxCode.cessRate?.toString() ?? '';
    _hsnSacController.text = taxCode.hsnSacCode ?? '';
    _remarksController.text = taxCode.remarks ?? '';
    _taxType = taxCode.taxType ?? 'gst';
    _isActive = taxCode.isActive;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedTaxCode = null;
    _codeController.clear();
    _nameController.clear();
    _rateController.clear();
    _cessRateController.clear();
    _hsnSacController.clear();
    _remarksController.clear();
    _taxType = 'gst';
    _isActive = true;
    _formError = null;
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final model = TaxCodeModel(
      id: _selectedTaxCode?.id,
      taxCode: _codeController.text.trim(),
      taxName: _nameController.text.trim(),
      taxType: _taxType,
      taxRate: double.tryParse(_rateController.text.trim()),
      cessRate: double.tryParse(_cessRateController.text.trim()),
      hsnSacCode: nullIfEmpty(_hsnSacController.text),
      remarks: nullIfEmpty(_remarksController.text),
      isActive: _isActive,
    );

    try {
      final response = _selectedTaxCode == null
          ? await _masterService.createTaxCode(model)
          : await _masterService.updateTaxCode(_selectedTaxCode!.id!, model);
      final saved = response.data;
      if (!mounted) {
        return;
      }
      if (saved == null) {
        setState(() {
          _formError = response.message;
        });
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadTaxCodes(selectId: saved.id);
    } catch (error) {
      setState(() {
        _formError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    final id = _selectedTaxCode?.id;
    if (id == null) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await _masterService.destroy('/masters/tax-codes/$id');
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadTaxCodes();
    } catch (error) {
      setState(() {
        _formError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _resetForm,
        icon: Icons.add_chart_outlined,
        label: 'New Tax Category',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Tax Categories',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading tax categories...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load tax categories',
        message: _pageError!,
        onRetry: _loadTaxCodes,
      );
    }

    final fieldWidth = settingsResponsiveFieldWidth(context);

    return SettingsWorkspace(
      scrollController: _pageScrollController,
      list: SettingsListCard<TaxCodeModel>(
        title: 'Tax Categories',
        subtitle:
            'Define GST and cess combinations used across your item and document flows.',
        searchController: _searchController,
        searchHint: 'Search tax categories',
        items: _filteredTaxCodes,
        selectedItem: _selectedTaxCode,
        emptyMessage: 'No tax categories found.',
        itemBuilder: (taxCode, selected) => SettingsListTile(
          title: taxCode.taxName ?? '-',
          subtitle: [
            taxCode.taxCode ?? '',
            taxCode.taxType?.toUpperCase() ?? '',
            if (taxCode.taxRate != null) '${taxCode.taxRate}%',
          ].where((value) => value.isNotEmpty).join(' • '),
          selected: selected,
          onTap: () => _selectTaxCode(taxCode),
          trailing: SettingsStatusPill(
            label: taxCode.isActive ? 'Active' : 'Inactive',
            active: taxCode.isActive,
          ),
        ),
      ),
      editor: SettingsEditorCard(
        title: _selectedTaxCode == null
            ? 'Create Tax Category'
            : 'Edit Tax Category',
        subtitle:
            'Keep GST classification, rate, and cess rules consistent from master level.',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_formError != null) ...[
                AppErrorStateView.inline(message: _formError!),
                const SizedBox(height: 16),
              ],
              SettingsFormWrap(
                children: [
                  AppFormTextField(
                    width: fieldWidth,
                    labelText: 'Tax Code',
                    controller: _codeController,
                    validator: Validators.required('Tax code'),
                  ),
                  AppFormTextField(
                    width: fieldWidth,
                    labelText: 'Tax Name',
                    controller: _nameController,
                    validator: Validators.required('Tax name'),
                  ),
                  AppDropdownField<String>.fromMapped(
                    width: fieldWidth,
                    labelText: 'Tax Type',
                    mappedItems: _taxTypeItems,
                    initialValue: _taxType,
                    onChanged: (value) =>
                        setState(() => _taxType = value ?? 'gst'),
                  ),
                  AppFormTextField(
                    width: fieldWidth,
                    labelText: 'Tax Rate (%)',
                    controller: _rateController,
                    keyboardType: TextInputType.number,
                    validator: Validators.required('Tax rate'),
                  ),
                  AppFormTextField(
                    width: fieldWidth,
                    labelText: 'CESS Rate (%)',
                    controller: _cessRateController,
                    keyboardType: TextInputType.number,
                  ),
                  AppFormTextField(
                    width: fieldWidth,
                    labelText: 'HSN / SAC',
                    controller: _hsnSacController,
                  ),
                  AppFormTextField(
                    width: fieldWidth,
                    labelText: 'Remarks',
                    controller: _remarksController,
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: fieldWidth,
                child: AppSwitchTile(
                  label: 'Active',
                  subtitle:
                      'Inactive categories stay out of normal selection lists.',
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  AppActionButton(
                    icon: Icons.save_outlined,
                    label: _selectedTaxCode == null
                        ? 'Save Tax Category'
                        : 'Update Tax Category',
                    onPressed: _save,
                    busy: _saving,
                  ),
                  if (_selectedTaxCode?.id != null)
                    AppActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      onPressed: _saving ? null : _delete,
                      filled: false,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
