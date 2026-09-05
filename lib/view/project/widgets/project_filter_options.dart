import '../../../screen.dart';

const List<AppDropdownItem<String>> projectBillingMethodItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'fixed', label: 'Fixed'),
      AppDropdownItem(value: 'time_and_material', label: 'Time And Material'),
      AppDropdownItem(value: 'milestone', label: 'Milestone'),
      AppDropdownItem(value: 'cost_plus', label: 'Cost Plus'),
    ];

const List<AppDropdownItem<String>> projectStatusItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'draft', label: 'Draft'),
      AppDropdownItem(value: 'open', label: 'Open'),
      AppDropdownItem(value: 'working', label: 'Working'),
      AppDropdownItem(value: 'on_hold', label: 'In Review'),
      AppDropdownItem(value: 'completed', label: 'Completed'),
      AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
    ];
