import '../../screen.dart';

/// Categorised, searchable picker for `{{binding}}` chips used in the
/// document print-template inspector.
///
/// Groups the flat list of binding keys returned by
/// [availablePrintBindings] into labelled sections so users can quickly
/// find the placeholder they want without scrolling through an unsorted
/// wall of chips.
///
/// The [onSelected] callback receives the raw key (without `{{ }}`), and
/// the caller decides how to insert it into the target field.
///
/// Search is hidden by default; toggling the search icon reveals a text
/// field that filters chips across all sections in real time. The filter
/// is a simple O(n) linear scan over a bounded list (~25-35 keys).
class DocumentBindingPicker extends StatefulWidget {
  const DocumentBindingPicker({
    super.key,
    required this.bindings,
    required this.onSelected,
  });

  /// All scalar binding keys available in the current document data.
  /// Supplied by `availablePrintBindings(documentDataJson)`.
  final List<String> bindings;

  /// Called when the user taps a chip; receives the raw key without `{{ }}`.
  final ValueChanged<String> onSelected;

  @override
  State<DocumentBindingPicker> createState() => _DocumentBindingPickerState();
}

class _DocumentBindingPickerState extends State<DocumentBindingPicker> {
  bool _searchVisible = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchVisible = !_searchVisible;
      if (!_searchVisible) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim().toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Bindings',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton(
              tooltip: _searchVisible ? 'Clear search' : 'Search bindings',
              onPressed: _toggleSearch,
              icon: Icon(
                _searchVisible ? Icons.search_off_outlined : Icons.search,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            ),
          ],
        ),
        if (_searchVisible) ...[
          const SizedBox(height: AppUiConstants.spacingXs),
          TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Filter bindings…',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            onChanged: _onSearchChanged,
          ),
        ],
        const SizedBox(height: AppUiConstants.spacingXs),
        _BindingSections(
          bindings: widget.bindings,
          filter: _searchQuery,
          onSelected: widget.onSelected,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Internal section renderer
// ---------------------------------------------------------------------------

/// Breaks the flat binding list into labelled groups and renders chips.
///
/// All grouping logic is O(n) over the bounded binding list. Each key is
/// classified once via a static [Set] membership check (O(1) per key).
class _BindingSections extends StatelessWidget {
  const _BindingSections({
    required this.bindings,
    required this.filter,
    required this.onSelected,
  });

  final List<String> bindings;
  final String filter;
  final ValueChanged<String> onSelected;

  // -----------------------------------------------------------------------
  // Static key-to-section maps (O(1) membership, bounded size)
  // -----------------------------------------------------------------------

  static const Set<String> _documentInfoKeys = <String>{
    'company_name',
    'company_logo_url',
    'company_gstin',
    'document_number',
    'document_date',
    'reference_number',
    'amount_in_words',
    'notes',
    'terms_conditions',
  };

  static const Set<String> _partyKeys = <String>{
    'party_name',
    'party_address',
    'party_contact',
    'party_gstin',
  };

  static const Set<String> _totalsKeys = <String>{
    'subtotal',
    'tax_amount',
    'total_amount',
    'taxable_total_amount',
    'discount_amount',
    'round_off_amount',
    'adjustment_amount',
  };

  static const Set<String> _gstKeys = <String>{
    'cgst_amount',
    'sgst_amount',
    'igst_amount',
    'cess_amount',
    'total_cgst_amount',
    'total_sgst_amount',
    'total_igst_amount',
    'total_cess_amount',
    'cgst_summary_label',
    'sgst_summary_label',
    'igst_summary_label',
    'cgst_summary_currency',
    'sgst_summary_currency',
    'igst_summary_currency',
    'discount_summary_label',
    'discount_summary_currency',
    'round_off_summary_label',
    'round_off_summary_currency',
  };

  _BindingGroup _classify(List<String> allKeys) {
    final documentInfo = <String>[];
    final party = <String>[];
    final totals = <String>[];
    final gst = <String>[];
    final extra = <String>[];

    for (final key in allKeys) {
      if (_documentInfoKeys.contains(key)) {
        documentInfo.add(key);
      } else if (_partyKeys.contains(key)) {
        party.add(key);
      } else if (_totalsKeys.contains(key)) {
        totals.add(key);
      } else if (_gstKeys.contains(key)) {
        gst.add(key);
      } else {
        extra.add(key);
      }
    }

    return _BindingGroup(
      documentInfo: documentInfo,
      party: party,
      totals: totals,
      gst: gst,
      extra: extra,
    );
  }

  List<String> _applyFilter(List<String> keys) {
    if (filter.isEmpty) return keys;
    return keys.where((k) => k.contains(filter)).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final group = _classify(bindings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionChips(
          label: 'Document',
          keys: _applyFilter(group.documentInfo),
          onSelected: onSelected,
        ),
        _SectionChips(
          label: 'Party',
          keys: _applyFilter(group.party),
          onSelected: onSelected,
        ),
        _SectionChips(
          label: 'Totals',
          keys: _applyFilter(group.totals),
          onSelected: onSelected,
        ),
        _SectionChips(
          label: 'GST',
          keys: _applyFilter(group.gst),
          onSelected: onSelected,
        ),
        _SectionChips(
          label: 'Custom',
          keys: _applyFilter(group.extra),
          onSelected: onSelected,
        ),
      ],
    );
  }
}

class _BindingGroup {
  const _BindingGroup({
    required this.documentInfo,
    required this.party,
    required this.totals,
    required this.gst,
    required this.extra,
  });

  final List<String> documentInfo;
  final List<String> party;
  final List<String> totals;
  final List<String> gst;
  final List<String> extra;
}

// ---------------------------------------------------------------------------
// Single labelled section of chips
// ---------------------------------------------------------------------------

class _SectionChips extends StatelessWidget {
  const _SectionChips({
    required this.label,
    required this.keys,
    required this.onSelected,
  });

  final String label;
  final List<String> keys;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (keys.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: AppUiConstants.spacingXxs),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: keys
              .map(
                (key) => ActionChip(
                  label: Text('{{$key}}'),
                  onPressed: () => onSelected(key),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: AppUiConstants.spacingXs),
      ],
    );
  }
}
