import '../../controller/hr/hr_statutory_settings_controller.dart';
import '../../screen.dart';

/// State/UT names for PT - slabs should match that jurisdiction's official schedule.
const List<AppDropdownItem<String>> _kProfessionalTaxStateItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: '', label: '- Select state / UT -'),
      AppDropdownItem(value: 'Andhra Pradesh', label: 'Andhra Pradesh'),
      AppDropdownItem(value: 'Arunachal Pradesh', label: 'Arunachal Pradesh'),
      AppDropdownItem(value: 'Assam', label: 'Assam'),
      AppDropdownItem(value: 'Bihar', label: 'Bihar'),
      AppDropdownItem(value: 'Chhattisgarh', label: 'Chhattisgarh'),
      AppDropdownItem(value: 'Goa', label: 'Goa'),
      AppDropdownItem(value: 'Gujarat', label: 'Gujarat'),
      AppDropdownItem(value: 'Haryana', label: 'Haryana'),
      AppDropdownItem(value: 'Himachal Pradesh', label: 'Himachal Pradesh'),
      AppDropdownItem(value: 'Jharkhand', label: 'Jharkhand'),
      AppDropdownItem(value: 'Karnataka', label: 'Karnataka'),
      AppDropdownItem(value: 'Kerala', label: 'Kerala'),
      AppDropdownItem(value: 'Madhya Pradesh', label: 'Madhya Pradesh'),
      AppDropdownItem(value: 'Maharashtra', label: 'Maharashtra'),
      AppDropdownItem(value: 'Manipur', label: 'Manipur'),
      AppDropdownItem(value: 'Meghalaya', label: 'Meghalaya'),
      AppDropdownItem(value: 'Mizoram', label: 'Mizoram'),
      AppDropdownItem(value: 'Nagaland', label: 'Nagaland'),
      AppDropdownItem(value: 'Odisha', label: 'Odisha'),
      AppDropdownItem(value: 'Punjab', label: 'Punjab'),
      AppDropdownItem(value: 'Rajasthan', label: 'Rajasthan'),
      AppDropdownItem(value: 'Sikkim', label: 'Sikkim'),
      AppDropdownItem(value: 'Tamil Nadu', label: 'Tamil Nadu'),
      AppDropdownItem(value: 'Telangana', label: 'Telangana'),
      AppDropdownItem(value: 'Tripura', label: 'Tripura'),
      AppDropdownItem(value: 'Uttar Pradesh', label: 'Uttar Pradesh'),
      AppDropdownItem(value: 'Uttarakhand', label: 'Uttarakhand'),
      AppDropdownItem(value: 'West Bengal', label: 'West Bengal'),
      AppDropdownItem(
        value: 'Andaman and Nicobar Islands',
        label: 'Andaman and Nicobar Islands',
      ),
      AppDropdownItem(value: 'Chandigarh', label: 'Chandigarh'),
      AppDropdownItem(
        value: 'Dadra and Nagar Haveli and Daman and Diu',
        label: 'Dadra and Nagar Haveli and Daman and Diu',
      ),
      AppDropdownItem(value: 'Delhi', label: 'Delhi'),
      AppDropdownItem(value: 'Jammu and Kashmir', label: 'Jammu and Kashmir'),
      AppDropdownItem(value: 'Ladakh', label: 'Ladakh'),
      AppDropdownItem(value: 'Lakshadweep', label: 'Lakshadweep'),
      AppDropdownItem(value: 'Puducherry', label: 'Puducherry'),
    ];

class HrStatutorySettingsPage extends StatefulWidget {
  const HrStatutorySettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<HrStatutorySettingsPage> createState() =>
      _HrStatutorySettingsPageState();
}

class _HrStatutorySettingsPageState extends State<HrStatutorySettingsPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('HrStatutorySettingsController');
    Get.put(
      HrStatutorySettingsController(),
      tag: _controllerTag,
      permanent: true,
    );
  }

  List<AppDropdownItem<String>> _ptStateItemsForDropdown(
    HrStatutorySettingsController controller,
  ) {
    const items = _kProfessionalTaxStateItems;
    final state = controller.professionalTaxStateCode;
    if (state.isEmpty ||
        items.any((AppDropdownItem<String> item) => item.value == state)) {
      return items;
    }
    return <AppDropdownItem<String>>[
      items.first,
      AppDropdownItem<String>(value: state, label: '$state (saved)'),
      ...items.skip(1),
    ];
  }

  Future<void> _delete(HrStatutorySettingsController controller) async {
    final id = controller.selectedProfileId;
    if (id == null) {
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete statutory profile'),
        content: const Text('Remove this PF/ESI/PT configuration?'),
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
    if (ok == true && mounted) {
      await controller.deleteProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HrStatutorySettingsController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: controller.saving ? null : controller.startNewForm,
            icon: Icons.add_outlined,
            label: 'New Profile',
          ),
        ];
        final body = controller.loading
            ? const AppLoadingView(message: 'Loading statutory settings...')
            : controller.error != null &&
                  controller.profiles.isEmpty &&
                  controller.companyId == null
            ? AppErrorStateView(
                title: 'Statutory settings',
                message: controller.error!,
                onRetry: controller.load,
              )
            : SingleChildScrollView(
                controller: controller.scroll,
                padding: const EdgeInsets.all(AppUiConstants.pagePadding),
                child: Form(
                  key: controller.profileFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (controller.error != null)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppUiConstants.spacingMd,
                          ),
                          child: AppErrorStateView.inline(
                            message: controller.error!,
                          ),
                        ),
                      Text(
                        'Configure PF, ESI, and professional tax per company. Payroll uses the active profile for the salary month. PT slabs must use fixed monthly amounts from the selected state/UT schedule (not %). Gross for PT is the employee monthly gross on the active salary structure-confirm with your consultant that this matches how that state defines taxable salary. Use Employees → salary structures for CTC and %-based components.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppUiConstants.spacingMd),
                      if (controller.companies.length > 1)
                        const SizedBox(height: AppUiConstants.spacingMd),
                      if (controller.profiles.isNotEmpty)
                        AppDropdownField<int?>.fromMapped(
                          labelText: 'Saved profile',
                          mappedItems: <AppDropdownItem<int?>>[
                            const AppDropdownItem<int?>(
                              value: null,
                              label: '- New profile -',
                            ),
                            ...controller.profiles.map(
                              (ErpRecordModel profile) => AppDropdownItem<int?>(
                                value: profile.id,
                                label:
                                    '${profile.toJson()['profile_name'] ?? 'Profile'} · ${((profile.toJson())['effective_from'] ?? '')}',
                              ),
                            ),
                          ],
                          initialValue: controller.selectedProfileId,
                          onChanged: (int? value) async {
                            if (value == null) {
                              controller.startNewForm();
                              return;
                            }
                            await controller.hydrateProfile(value);
                          },
                        ),
                      const SizedBox(height: AppUiConstants.spacingLg),
                      AppSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppUiConstants.spacingMd),
                            AppFormTextField(
                              controller: controller.nameCtrl,
                              labelText: 'Profile name',
                              validator: Validators.optionalMaxLength(
                                100,
                                'Profile name',
                              ),
                            ),
                            AppFormTextField(
                              controller: controller.effFromCtrl,
                              labelText: 'Effective from',
                              keyboardType: TextInputType.datetime,
                              inputFormatters: const [DateInputFormatter()],
                              validator: Validators.compose([
                                Validators.required('Effective from'),
                                Validators.date('Effective from'),
                              ]),
                            ),
                            AppFormTextField(
                              controller: controller.effToCtrl,
                              labelText: 'Effective to (optional)',
                              keyboardType: TextInputType.datetime,
                              inputFormatters: const [DateInputFormatter()],
                              validator: Validators.compose([
                                Validators.optionalDate('Effective to'),
                                Validators.optionalDateOnOrAfter(
                                  'Effective to',
                                  () => controller.effFromCtrl.text.trim(),
                                  startFieldName: 'Effective from',
                                ),
                              ]),
                            ),
                            AppFormTextField(
                              controller: controller.remarksCtrl,
                              labelText: 'Remarks (optional)',
                              validator: Validators.optionalMaxLength(
                                500,
                                'Remarks',
                              ),
                            ),
                            AppDropdownField<String>.fromMapped(
                              labelText: 'Professional tax - state / UT',
                              mappedItems: _ptStateItemsForDropdown(controller),
                              initialValue:
                                  controller.professionalTaxStateCode.isEmpty
                                  ? ''
                                  : controller.professionalTaxStateCode,
                              onChanged: controller.setProfessionalTaxStateCode,
                              validator: Validators.optionalMaxLength(
                                64,
                                'Professional tax state',
                              ),
                            ),
                            AppSwitchTile(
                              label: 'Active',
                              value: controller.isActive,
                              onChanged: controller.setIsActive,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppUiConstants.spacingMd),
                      AppSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Provident fund (PF)',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppUiConstants.spacingMd),
                            AppDropdownField<String>.fromMapped(
                              labelText: 'Calculate employee share on',
                              mappedItems:
                                  HrStatutorySettingsController.basisItems,
                              initialValue: controller.pfOn,
                              onChanged: controller.setPfOn,
                            ),
                            AppFormTextField(
                              controller: controller.pfEmpCtrl,
                              labelText: 'Employee %',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: percentField0To100Optional(
                                'Employee %',
                              ),
                            ),
                            AppFormTextField(
                              controller: controller.pfErCtrl,
                              labelText: 'Employer %',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: percentField0To100Optional(
                                'Employer %',
                              ),
                            ),
                            AppFormTextField(
                              controller: controller.pfCeilCtrl,
                              labelText: 'Wage ceiling (optional, e.g. 15000)',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: Validators.optionalNonNegativeNumber(
                                'Wage ceiling',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppUiConstants.spacingMd),
                      AppSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ESI',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppUiConstants.spacingMd),
                            AppDropdownField<String>.fromMapped(
                              labelText: 'Calculate on',
                              mappedItems:
                                  HrStatutorySettingsController.basisItems,
                              initialValue: controller.esiOn,
                              onChanged: controller.setEsiOn,
                            ),
                            AppFormTextField(
                              controller: controller.esiEmpCtrl,
                              labelText: 'Employee %',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: percentField0To100Optional(
                                'Employee %',
                              ),
                            ),
                            AppFormTextField(
                              controller: controller.esiErCtrl,
                              labelText: 'Employer %',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: percentField0To100Optional(
                                'Employer %',
                              ),
                            ),
                            AppFormTextField(
                              controller: controller.esiCeilCtrl,
                              labelText: 'Gross ceiling (optional, e.g. 21000)',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: Validators.optionalNonNegativeNumber(
                                'Gross ceiling',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppUiConstants.spacingMd),
                      AppSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Professional tax - gross slabs (state schedule)',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: controller.addPtSlab,
                                  icon: const Icon(Icons.add, size: 20),
                                  label: const Text('Add slab'),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppUiConstants.spacingSm),
                            Text(
                              'Enter each slab as in the notified rules: monthly gross from/to (₹) and fixed tax per month (₹). Employer column is usually zero; use only if your schedule includes it.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: AppUiConstants.spacingSm),
                            ...List<
                              Widget
                            >.generate(controller.ptSlabs.length, (int index) {
                              final slab = controller.ptSlabs[index];
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppUiConstants.spacingSm,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: AppFormTextField(
                                        controller: slab.grossFrom,
                                        labelText: 'Monthly gross from (₹)',
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        validator:
                                            Validators.optionalNonNegativeNumber(
                                              'Gross from',
                                            ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: AppUiConstants.spacingSm,
                                    ),
                                    Expanded(
                                      child: AppFormTextField(
                                        controller: slab.grossTo,
                                        labelText:
                                            'Monthly gross to (₹, empty = no upper)',
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        validator:
                                            Validators.optionalNonNegativeNumber(
                                              'Gross to',
                                            ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: AppUiConstants.spacingSm,
                                    ),
                                    Expanded(
                                      child: AppFormTextField(
                                        controller: slab.empTax,
                                        labelText: 'Employee PT / month (₹)',
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        validator:
                                            Validators.optionalNonNegativeNumber(
                                              'Employee PT',
                                            ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: AppUiConstants.spacingSm,
                                    ),
                                    Expanded(
                                      child: AppFormTextField(
                                        controller: slab.erTax,
                                        labelText: 'Employer PT / month (₹)',
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        validator:
                                            Validators.optionalNonNegativeNumber(
                                              'Employer PT',
                                            ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Remove',
                                      onPressed: () =>
                                          controller.removePtSlabAt(index),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppUiConstants.spacingLg),
                      Wrap(
                        spacing: AppUiConstants.spacingSm,
                        runSpacing: AppUiConstants.spacingSm,
                        children: [
                          FilledButton(
                            onPressed: controller.saving
                                ? null
                                : controller.save,
                            child: controller.saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    controller.selectedProfileId == null
                                        ? 'Create profile'
                                        : 'Update profile',
                                  ),
                          ),
                          if (controller.selectedProfileId != null)
                            FilledButton.tonal(
                              onPressed: controller.saving
                                  ? null
                                  : () => _delete(controller),
                              child: const Text('Delete'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: body);
        }
        return AppStandaloneShell(
          title: 'HR · PF, ESI & PT',
          scrollController: controller.scroll,
          actions: actions,
          child: body,
        );
      },
    );
  }
}
