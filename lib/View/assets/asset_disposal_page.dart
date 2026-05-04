import '../../screen.dart';
import '../hr/hr_workflow_dialogs.dart';

Map<String, dynamic>? _disposalJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

String _disposalAssetLabel(Map<String, dynamic> data) {
  final asset = _disposalJsonMap(data['asset']);
  if (asset == null) {
    return '';
  }
  final code = stringValue(asset, 'asset_code');
  final name = stringValue(asset, 'asset_name');
  if (code.isNotEmpty && name.isNotEmpty) {
    return '$code - $name';
  }
  return code.isNotEmpty ? code : name;
}

int? _disposalAssetCompanyId(Map<String, dynamic> data) {
  final asset = _disposalJsonMap(data['asset']);
  if (asset == null) {
    return null;
  }
  return intValue(asset, 'company_id');
}

String _disposalPartyName(Map<String, dynamic> data) {
  final party = _disposalJsonMap(data['saleParty']);
  if (party == null) {
    return '';
  }
  final displayName = stringValue(party, 'display_name');
  if (displayName.isNotEmpty) {
    return displayName;
  }
  return stringValue(party, 'party_name');
}

class AssetDisposalPage extends StatefulWidget {
  const AssetDisposalPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<AssetDisposalPage> createState() => _AssetDisposalPageState();
}

class _AssetDisposalPageState extends State<AssetDisposalPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final AssetsService _assets = AssetsService();
  final MasterService _master = MasterService();
  final PartiesService _partiesService = PartiesService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _disposalNoController = TextEditingController();
  final TextEditingController _disposalDateController = TextEditingController();
  final TextEditingController _disposalTypeController = TextEditingController();
  final TextEditingController _disposalValueController =
      TextEditingController();
  final TextEditingController _expenseController = TextEditingController();
  final TextEditingController _bookValueController = TextEditingController();
  final TextEditingController _gainLossController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _loading = true;
  bool _detailLoading = false;
  bool _saving = false;
  bool _actionBusy = false;
  String? _pageError;
  String? _formError;
  String? _actionMessage;
  String? _companyBanner;
  int? _sessionCompanyId;

  List<AssetDisposalModel> _rows = const <AssetDisposalModel>[];
  List<AssetModel> _assetsList = const <AssetModel>[];
  List<PartyModel> _parties = const <PartyModel>[];
  List<DocumentSeriesModel> _series = const <DocumentSeriesModel>[];

  AssetDisposalModel? _selected;
  AssetDisposalModel? _detail;

  int? _assetId;
  int? _salePartyId;
  int? _documentSeriesId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _load(selectId: widget.initialId);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _disposalNoController.dispose();
    _disposalDateController.dispose();
    _disposalTypeController.dispose();
    _disposalValueController.dispose();
    _expenseController.dispose();
    _bookValueController.dispose();
    _gainLossController.dispose();
    _remarksController.dispose();
    _pageScrollController.dispose();
    _workspaceController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _snack() {
    final msg = _actionMessage;
    _actionMessage = null;
    if (!mounted || msg == null || msg.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  List<AssetDisposalModel> get _filteredRows {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'disposal_no'),
            stringValue(data, 'disposal_status'),
            _disposalAssetLabel(data),
            _disposalPartyName(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  List<DocumentSeriesModel> get _seriesOptions {
    return _series
        .where((item) {
          if ((item.documentType ?? '').toUpperCase() != 'ASSET_DISPOSAL') {
            return false;
          }
          if (_sessionCompanyId != null &&
              item.companyId != _sessionCompanyId) {
            return false;
          }
          return item.isActive;
        })
        .toList(growable: false);
  }

  String _listTitle(AssetDisposalModel row) {
    final data = row.toJson();
    final no = stringValue(data, 'disposal_no');
    if (no.isNotEmpty) {
      return no;
    }
    final asset = _disposalAssetLabel(data);
    return asset.isNotEmpty ? asset : 'Disposal';
  }

  String _listSubtitle(AssetDisposalModel row) {
    final data = row.toJson();
    return [
      _disposalAssetLabel(data),
      _disposalPartyName(data),
      stringValue(data, 'disposal_status'),
    ].where((value) => value.trim().isNotEmpty).join(' · ');
  }

  void _resetDraft() {
    _selected = null;
    _detail = null;
    _formError = null;
    _assetId = null;
    _salePartyId = null;
    _documentSeriesId = null;
    _disposalNoController.clear();
    _disposalDateController.clear();
    _disposalTypeController.clear();
    _disposalValueController.clear();
    _expenseController.clear();
    _bookValueController.clear();
    _gainLossController.clear();
    _remarksController.clear();
    setState(() {});
  }

  void _applyFromModel(AssetDisposalModel model) {
    final data = model.toJson();
    _assetId = intValue(data, 'asset_id');
    _salePartyId = intValue(data, 'sale_party_id');
    _disposalNoController.text = stringValue(data, 'disposal_no');
    _disposalDateController.text = stringValue(data, 'disposal_date');
    _disposalTypeController.text = stringValue(data, 'disposal_type');
    _disposalValueController.text = data['disposal_value']?.toString() ?? '';
    _expenseController.text = data['disposal_expense']?.toString() ?? '';
    _bookValueController.text =
        data['book_value_at_disposal']?.toString() ?? '';
    _gainLossController.text = data['gain_or_loss_amount']?.toString() ?? '';
    _remarksController.text = stringValue(data, 'remarks');
  }

  Future<void> _load({int? selectId}) async {
    setState(() {
      _loading = true;
      _pageError = null;
    });
    try {
      final info = await hrSessionCompanyInfo();
      _sessionCompanyId = info.companyId;
      _companyBanner = info.banner;
      final assetFilters = <String, dynamic>{'per_page': 300};
      if (info.companyId != null) {
        assetFilters['company_id'] = info.companyId;
      }
      final responses = await Future.wait<dynamic>([
        _assets.disposals(filters: const {'per_page': 200}),
        _assets.assets(filters: assetFilters),
        _partiesService.parties(filters: const {'per_page': 500}),
        _master.documentSeries(filters: const {'per_page': 400}),
      ]);

      var rows =
          (responses[0] as PaginatedResponse<AssetDisposalModel>).data ??
          const <AssetDisposalModel>[];
      if (info.companyId != null) {
        rows = rows
            .where((row) {
              return _disposalAssetCompanyId(row.toJson()) == info.companyId;
            })
            .toList(growable: false);
      }

      _rows = rows;
      _assetsList =
          (responses[1] as PaginatedResponse<AssetModel>).data ??
          const <AssetModel>[];
      _parties =
          ((responses[2] as PaginatedResponse<PartyModel>).data ??
                  const <PartyModel>[])
              .where((party) => party.isActive)
              .toList(growable: false);
      _series =
          (responses[3] as PaginatedResponse<DocumentSeriesModel>).data ??
          const <DocumentSeriesModel>[];

      _loading = false;

      if (selectId != null) {
        final existing = _rows.cast<AssetDisposalModel?>().firstWhere(
          (row) => intValue(row?.toJson() ?? const {}, 'id') == selectId,
          orElse: () => null,
        );
        if (existing != null) {
          await _select(existing);
          return;
        }
        await _loadDetailById(selectId);
        return;
      }

      _resetDraft();
    } catch (e) {
      setState(() {
        _pageError = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _reloadList() async {
    final info = await hrSessionCompanyInfo();
    final response = await _assets.disposals(filters: const {'per_page': 200});
    var rows = response.data ?? const <AssetDisposalModel>[];
    if (info.companyId != null) {
      rows = rows
          .where((row) {
            return _disposalAssetCompanyId(row.toJson()) == info.companyId;
          })
          .toList(growable: false);
    }
    _rows = rows;
  }

  Future<void> _loadDetailById(int id) async {
    setState(() {
      _detailLoading = true;
      _formError = null;
    });
    try {
      final response = await _assets.disposal(id);
      if (response.success == true && response.data != null) {
        _detail = response.data;
        _selected = response.data;
        _applyFromModel(response.data!);
      } else {
        _formError = response.message;
      }
    } catch (e) {
      _formError = e.toString();
    } finally {
      if (mounted) {
        setState(() => _detailLoading = false);
      }
    }
  }

  Future<void> _select(AssetDisposalModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) {
      return;
    }
    setState(() {
      _selected = row;
      _detailLoading = true;
      _formError = null;
    });
    try {
      final response = await _assets.disposal(id);
      if (response.success == true && response.data != null) {
        _detail = response.data;
        _applyFromModel(response.data!);
      } else {
        _formError = response.message;
      }
    } catch (e) {
      _formError = e.toString();
    } finally {
      if (mounted) {
        setState(() => _detailLoading = false);
      }
    }
  }

  Future<void> _save() async {
    final assetId = _assetId;
    final disposalDate = _disposalDateController.text.trim();
    final disposalType = _disposalTypeController.text.trim();
    final disposalNo = _disposalNoController.text.trim();
    if (assetId == null) {
      setState(() => _formError = 'Asset is required.');
      return;
    }
    if (disposalDate.isEmpty) {
      setState(() => _formError = 'Disposal date is required.');
      return;
    }
    if (disposalType.isEmpty) {
      setState(() => _formError = 'Disposal type is required.');
      return;
    }
    if (disposalNo.isEmpty && _documentSeriesId == null) {
      setState(() => _formError = 'Enter disposal no. or select a series.');
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });
    try {
      final payload = <String, dynamic>{
        'asset_id': assetId,
        'disposal_date': disposalDate,
        'disposal_type': disposalType,
        if (disposalNo.isNotEmpty) 'disposal_no': disposalNo,
        if (_documentSeriesId != null) 'document_series_id': _documentSeriesId,
        if (_salePartyId != null) 'sale_party_id': _salePartyId,
        if (double.tryParse(_disposalValueController.text.trim()) != null)
          'disposal_value': double.parse(_disposalValueController.text.trim()),
        if (double.tryParse(_expenseController.text.trim()) != null)
          'disposal_expense': double.parse(_expenseController.text.trim()),
        if (nullIfEmpty(_remarksController.text.trim()) != null)
          'remarks': _remarksController.text.trim(),
      };

      final existingId = intValue(_detail?.toJson() ?? const {}, 'id');
      final response = existingId == null
          ? await _assets.createDisposal(AssetDisposalModel(payload))
          : await _assets.updateDisposal(
              existingId,
              AssetDisposalModel(payload),
            );
      if (response.success != true || response.data == null) {
        setState(() => _formError = response.message);
        return;
      }

      _detail = response.data;
      _selected = response.data;
      _applyFromModel(response.data!);
      await _reloadList();
      final savedId = intValue(response.data!.toJson(), 'id');
      if (savedId != null) {
        _selected =
            _rows.cast<AssetDisposalModel?>().firstWhere(
              (row) => intValue(row?.toJson() ?? const {}, 'id') == savedId,
              orElse: () => null,
            ) ??
            response.data;
      }
      _actionMessage = existingId == null
          ? 'Disposal created.'
          : 'Disposal updated.';
      _snack();
    } catch (e) {
      setState(() => _formError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _runAction(
    Future<ApiResponse<AssetDisposalModel>> Function() fn,
    String message,
  ) async {
    setState(() {
      _actionBusy = true;
      _formError = null;
    });
    try {
      final response = await fn();
      if (response.success != true || response.data == null) {
        setState(() => _formError = response.message);
        return;
      }
      _detail = response.data;
      _selected = response.data;
      _applyFromModel(response.data!);
      await _reloadList();
      _actionMessage = message;
      _snack();
    } catch (e) {
      setState(() => _formError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _actionBusy = false);
      }
    }
  }

  Future<void> _delete() async {
    final id = intValue(_detail?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete disposal'),
        content: const Text('Only draft disposals can be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    setState(() => _actionBusy = true);
    try {
      final response = await _assets.deleteDisposal(id);
      if (response.success != true) {
        setState(() => _formError = response.message);
        return;
      }
      await _reloadList();
      _resetDraft();
      _actionMessage = 'Disposal deleted.';
      _snack();
    } catch (e) {
      setState(() => _formError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _actionBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _loading
            ? null
            : () {
                _resetDraft();
                if (!Responsive.isDesktop(context)) {
                  _workspaceController.openEditor();
                }
              },
        icon: Icons.add_outlined,
        label: 'New disposal',
      ),
    ];

    final content = _buildContent(context);
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'Asset disposals',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loading) {
      return const AppLoadingView(message: 'Loading disposals...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load disposals',
        message: _pageError!,
        onRetry: () => _load(selectId: widget.initialId),
      );
    }

    final scopeHint = _sessionCompanyId != null
        ? 'Disposals are filtered client-side by nested asset.company_id.'
        : 'API list is not company-scoped; select a session company to filter.';

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Asset disposals',
      editorTitle: _selected == null
          ? 'New asset disposal'
          : _listTitle(_selected!),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<AssetDisposalModel>(
        searchController: _searchController,
        searchHint: 'Search no., asset, party, status',
        items: _filteredRows,
        selectedItem: _selected,
        emptyMessage: 'No disposals found.',
        itemBuilder: (item, selected) {
          return SettingsListTile(
            title: _listTitle(item),
            subtitle: _listSubtitle(item),
            selected: selected,
            onTap: () async {
              final isDesktop = Responsive.isDesktop(context);
              await _select(item);
              if (!mounted) {
                return;
              }
              if (!isDesktop) {
                _workspaceController.openEditor();
              }
            },
          );
        },
      ),
      editor: _detailLoading
          ? const AppLoadingView(message: 'Loading disposal...')
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_formError != null) ...[
                    AppErrorStateView.inline(message: _formError!),
                    const SizedBox(height: AppUiConstants.spacingSm),
                  ],
                  Text(
                    _selected == null ? 'New asset disposal' : 'Edit disposal',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppUiConstants.spacingMd),
                  if (_saving || _actionBusy) const LinearProgressIndicator(),
                  if (_companyBanner != null && _selected == null) ...[
                    Text(
                      'Session company: $_companyBanner. $scopeHint',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppUiConstants.spacingMd),
                  ],
                  SettingsFormWrap(
                    children: [
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Asset',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _assetId,
                        items: _assetsList
                            .where(
                              (asset) => intValue(asset.toJson(), 'id') != null,
                            )
                            .map(
                              (asset) => DropdownMenuItem<int>(
                                value: intValue(asset.toJson(), 'id'),
                                child: Text(_listAssetOption(asset)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: _saving || _actionBusy
                            ? null
                            : (value) => setState(() => _assetId = value),
                      ),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Document series',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _documentSeriesId,
                        items: _seriesOptions
                            .where((item) => item.id != null)
                            .map(
                              (item) => DropdownMenuItem<int>(
                                value: item.id,
                                child: Text(item.toString()),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: _saving || _actionBusy
                            ? null
                            : (value) =>
                                  setState(() => _documentSeriesId = value),
                      ),
                      AppFormTextField(
                        labelText: 'Disposal no.',
                        controller: _disposalNoController,
                      ),
                      AppFormTextField(
                        labelText: 'Disposal date',
                        controller: _disposalDateController,
                        hintText: 'YYYY-MM-DD',
                      ),
                      AppFormTextField(
                        labelText: 'Disposal type',
                        controller: _disposalTypeController,
                        hintText: 'sale, scrap, write_off',
                      ),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Sale party',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _salePartyId,
                        items: _parties
                            .where((party) => party.id != null)
                            .map(
                              (party) => DropdownMenuItem<int>(
                                value: party.id,
                                child: Text(party.toString()),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: _saving || _actionBusy
                            ? null
                            : (value) => setState(() => _salePartyId = value),
                      ),
                      AppFormTextField(
                        labelText: 'Disposal value',
                        controller: _disposalValueController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Disposal expense',
                        controller: _expenseController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Book value at disposal',
                        controller: _bookValueController,
                        readOnly: true,
                      ),
                      AppFormTextField(
                        labelText: 'Gain / loss',
                        controller: _gainLossController,
                        readOnly: true,
                      ),
                      AppFormTextField(
                        labelText: 'Remarks',
                        controller: _remarksController,
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppUiConstants.spacingMd),
                  Wrap(
                    spacing: AppUiConstants.spacingSm,
                    runSpacing: AppUiConstants.spacingSm,
                    children: [
                      AppActionButton(
                        icon: Icons.save_outlined,
                        label: _selected == null ? 'Save' : 'Update',
                        busy: _saving,
                        onPressed: _actionBusy ? null : _save,
                      ),
                      if (_selected != null)
                        AppActionButton(
                          icon: Icons.check_circle_outline,
                          label: 'Approve',
                          filled: false,
                          onPressed: _saving || _actionBusy
                              ? null
                              : () => _runAction(
                                  () => _assets.approveDisposal(
                                    intValue(_detail!.toJson(), 'id')!,
                                    const AssetDisposalModel(
                                      <String, dynamic>{},
                                    ),
                                  ),
                                  'Disposal updated.',
                                ),
                        ),
                      if (_selected != null)
                        AppActionButton(
                          icon: Icons.publish_outlined,
                          label: 'Post',
                          filled: false,
                          onPressed: _saving || _actionBusy
                              ? null
                              : () => _runAction(
                                  () => _assets.postDisposal(
                                    intValue(_detail!.toJson(), 'id')!,
                                    const AssetDisposalModel(
                                      <String, dynamic>{},
                                    ),
                                  ),
                                  'Disposal updated.',
                                ),
                        ),
                      if (_selected != null)
                        AppActionButton(
                          icon: Icons.cancel_outlined,
                          label: 'Cancel',
                          filled: false,
                          onPressed: _saving || _actionBusy
                              ? null
                              : () => _runAction(
                                  () => _assets.cancelDisposal(
                                    intValue(_detail!.toJson(), 'id')!,
                                    const AssetDisposalModel(
                                      <String, dynamic>{},
                                    ),
                                  ),
                                  'Disposal updated.',
                                ),
                        ),
                      if (_selected != null)
                        AppActionButton(
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          filled: false,
                          onPressed: _saving || _actionBusy ? null : _delete,
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  String _listAssetOption(AssetModel asset) {
    final data = asset.toJson();
    final code = stringValue(data, 'asset_code');
    final name = stringValue(data, 'asset_name');
    if (code.isNotEmpty && name.isNotEmpty) {
      return '$code - $name';
    }
    return code.isNotEmpty ? code : name;
  }
}
