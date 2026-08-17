import '../../../screen.dart';

typedef MonthlyAttendanceCellBuilder =
    Widget Function(
      MonthlyAttendanceEmployeeModel employee,
      int day,
      MonthlyAttendanceSheetModel sheet,
    );

class MonthlyAttendanceCalendarGrid extends StatelessWidget {
  const MonthlyAttendanceCalendarGrid({
    required this.sheet,
    required this.employees,
    required this.year,
    required this.month,
    required this.scrollController,
    required this.cellBuilder,
    required this.manualOnly,
    required this.page,
    required this.perPage,
    required this.selectedEmployeeIds,
    this.onEmployeeSelected,
    super.key,
  });

  final MonthlyAttendanceSheetModel sheet;
  final List<MonthlyAttendanceEmployeeModel> employees;
  final int year;
  final int month;
  final ScrollController scrollController;
  final MonthlyAttendanceCellBuilder cellBuilder;
  final bool manualOnly;
  final int page;
  final int perPage;
  final Set<int> selectedEmployeeIds;
  final void Function(int employeeId, bool selected)? onEmployeeSelected;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    return AppSectionCard(
      padding: EdgeInsets.zero,
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          child: DataTable(
            border: TableBorder(
              horizontalInside: BorderSide(
                color: appTheme.tableBorder,
                width: 0.7,
              ),
            ),
            headingRowColor: WidgetStatePropertyAll<Color>(
              appTheme.tableHeaderBackground,
            ),
            showCheckboxColumn: manualOnly,
            headingRowHeight: 58,
            dataRowMinHeight: 62,
            dataRowMaxHeight: 62,
            columnSpacing: 12,
            columns: <DataColumn>[
              const DataColumn(
                label: SizedBox(
                  width: 32,
                  child: Text('#', textAlign: TextAlign.center),
                ),
              ),
              DataColumn(
                label: SizedBox(width: 230, child: const Text('Employee')),
              ),
              const DataColumn(
                label: SizedBox(width: 150, child: Text('Department')),
              ),
              for (var day = 1; day <= sheet.daysInMonth; day++)
                DataColumn(
                  label: SizedBox(
                    width: 38,
                    child: Text(
                      '$day\n${_weekdayLabel(day)}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
            rows: employees.indexed
                .map((entry) => _row(context, entry.$1, entry.$2, appTheme))
                .toList(growable: false),
          ),
        ),
      ),
    );
  }

  DataRow _row(
    BuildContext context,
    int rowIndex,
    MonthlyAttendanceEmployeeModel employee,
    AppThemeExtension appTheme,
  ) {
    return DataRow(
      selected: manualOnly && selectedEmployeeIds.contains(employee.id),
      onSelectChanged: manualOnly && onEmployeeSelected != null
          ? (selected) => onEmployeeSelected!(employee.id, selected == true)
          : null,
      cells: <DataCell>[
        DataCell(
          SizedBox(
            width: 32,
            child: Center(
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: appTheme.subtleFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${((page - 1) * perPage) + rowIndex + 1}'),
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(width: 230, child: _employeeIdentity(context, employee)),
        ),
        DataCell(
          SizedBox(
            width: 150,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _metadataPill(
                context,
                (employee.departmentName ?? '').trim().isEmpty
                    ? 'Unassigned'
                    : employee.departmentName!,
                appTheme.subtleFill,
                appTheme.tableCellText,
              ),
            ),
          ),
        ),
        for (var day = 1; day <= sheet.daysInMonth; day++)
          DataCell(cellBuilder(employee, day, sheet)),
      ],
    );
  }

  Widget _employeeIdentity(
    BuildContext context,
    MonthlyAttendanceEmployeeModel employee,
  ) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    final details = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          employee.employeeName,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if ((employee.employeeCode ?? '').isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: AppUiConstants.spacingXxs),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: appTheme.subtleFill,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              employee.employeeCode!,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: appTheme.mutedText,
              ),
            ),
          ),
      ],
    );
    final initials = employee.employeeName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Row(
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: Text(
            initials.isEmpty ? 'E' : initials,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppUiConstants.spacingSm),
        Expanded(child: details),
      ],
    );
  }

  Widget _metadataPill(
    BuildContext context,
    String label,
    Color background,
    Color foreground,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 145),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _weekdayLabel(int day) => const <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ][DateTime(year, month, day).weekday - 1];
}
