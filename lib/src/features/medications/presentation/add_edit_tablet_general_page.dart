import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/data/medication_repository.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:dosifi_v5/src/widgets/summary_header_card.dart';

/// Minimal Tablet editor that renders ONLY the General section.
/// This is used to isolate rendering issues step-by-step.
class AddEditTabletGeneralPage extends StatefulWidget {
  const AddEditTabletGeneralPage({super.key, this.initial});

  final Medication? initial;

  @override
  State<AddEditTabletGeneralPage> createState() =>
      _AddEditTabletGeneralPageState();
}

class _AddEditTabletGeneralPageState extends State<AddEditTabletGeneralPage> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollCtrl = ScrollController();

  // Dynamic spacer height measured from the floating summary card
  final GlobalKey _summaryKey = GlobalKey();
  double _summaryHeight = 0;

  final _nameCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  // Strength fields (current section)
  final _strengthValueCtrl = TextEditingController();
  Unit _strengthUnit = Unit.mg;
  // Inventory fields (next section)
  final _stockCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  bool _lowStockClampHint = false;
  bool _lowStockAlert = false;
  final _lowStockThresholdCtrl = TextEditingController();
  DateTime? _expiryDate;
  // Storage fields
  final _storageLocationCtrl = TextEditingController();
  final _batchNumberCtrl = TextEditingController();
  final _storageInstructionsCtrl = TextEditingController();
  bool _keepRefrigerated = false;
  bool _keepFrozen = false;
  bool _lightSensitive = false;

  // Live validation state
  String? _stockError;

  // Gating for helper-row validation (hide red until interaction)
  bool _submitted = false;
  bool _touchedName = false;
  bool _touchedStrengthAmt = false;
  bool _touchedStock = false;

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    if (m != null) {
      _nameCtrl.text = m.name;
      _manufacturerCtrl.text = m.manufacturer ?? '';
      _descriptionCtrl.text = m.description ?? '';
      _notesCtrl.text = m.notes ?? '';
      _strengthValueCtrl.text =
          (m.strengthValue == m.strengthValue.roundToDouble())
          ? m.strengthValue.toStringAsFixed(0)
          : m.strengthValue.toString();
      _strengthUnit = m.strengthUnit;
      _stockCtrl.text = (m.stockValue == m.stockValue.roundToDouble())
          ? m.stockValue.toStringAsFixed(0)
          : m.stockValue.toStringAsFixed(2);
      _lowStockAlert = m.lowStockEnabled;
      _lowStockThresholdCtrl.text = m.lowStockThreshold?.toString() ?? '';
      _expiryDate = m.expiry;
      _batchNumberCtrl.text = m.batchNumber ?? '';
      _storageLocationCtrl.text = m.storageLocation ?? '';
      _keepRefrigerated = m.requiresRefrigeration;
      _lightSensitive =
          (m.storageInstructions?.toLowerCase().contains('light') ?? false);
      _storageInstructionsCtrl.text = m.storageInstructions ?? '';
    }
    // Defaults for integer fields when adding new entries
    if (_strengthValueCtrl.text.isEmpty) _strengthValueCtrl.text = '0';
    if (_stockCtrl.text.isEmpty) _stockCtrl.text = '0';
    if (_lowStockThresholdCtrl.text.isEmpty) _lowStockThresholdCtrl.text = '0';
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _nameCtrl.dispose();
    _manufacturerCtrl.dispose();
    _descriptionCtrl.dispose();
    _notesCtrl.dispose();
    _strengthValueCtrl.dispose();
    _stockCtrl.dispose();
    _lowStockThresholdCtrl.dispose();
    _storageLocationCtrl.dispose();
    _batchNumberCtrl.dispose();
    _storageInstructionsCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec({required String label, String? hint, String? helper}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InputDecoration(
      // No floating label; we render labels in the left column
      floatingLabelBehavior: FloatingLabelBehavior.never,
      isDense: false,
      isCollapsed: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(minHeight: kFieldHeight),
      hintText: hint,
      helperText: helper,
      // Render errors in helper area; suppress default error line to avoid squashing Field36
      errorStyle: const TextStyle(fontSize: 0, height: 0),
      // hintStyle and helperStyle come from ThemeData.inputDecorationTheme
      filled: true,
      fillColor: cs.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
          width: kOutlineWidth,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: kFocusedOutlineWidth),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error, width: kOutlineWidth),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error, width: kOutlineWidth),
      ),
    );
  }

  double _labelWidth() {
    final width = MediaQuery.of(context).size.width;
    return width >= 400 ? 120.0 : 110.0;
  }

  Widget _helperBelowLeft(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(left: _labelWidth() + 8, top: 4, bottom: 12),
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.75),
        ),
      ),
    );
  }

  // Error under left label (keeps helper/support under field)
  Widget _errorUnderLabel(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 2, top: 2, bottom: 4),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }

  Widget _helperBelowLeftCompact(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(left: _labelWidth() + 8, top: 1, bottom: 4),
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 11,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.75),
        ),
      ),
    );
  }

  Widget _helperBelowCenter(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.75),
          ),
        ),
      ),
    );
  }

  // Unified support line (error/help) under a field with fixed height and alignment
  Widget _supportBelowLeftFixed({String? error, String? help, bool compact = false, Color? color}) {
    final theme = Theme.of(context);
    final left = _labelWidth() + 8;
    final text = error ?? help ?? '';
    final style = theme.textTheme.bodySmall?.copyWith(
      color: error != null
          ? theme.colorScheme.error
          : (color ?? theme.colorScheme.onSurfaceVariant.withOpacity(0.75)),
      fontSize: compact ? 11 : null,
    );
    return Padding(
      padding: EdgeInsets.only(left: left, top: 2, bottom: 8),
      child: SizedBox(
        height: 18,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }

  // Local helpers
  String _unitLabel(Unit u) {
    switch (u) {
      case Unit.mcg:
        return 'mcg';
      case Unit.mg:
        return 'mg';
      case Unit.g:
        return 'g';
      default:
        return u.name;
    }
  }

  String fmt2(double? v) {
    if (v == null) return '-';
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  }

  Widget _section(String title, List<Widget> children, {Widget? trailing}) {
    // Use unified soft white card style for visual consistency with injection and selection screens
    return SectionFormCard(
      title: title,
      neutral: true,
      trailing: trailing,
      children: children,
    );
  }

  InputDecoration _decDrop({
    required String label,
    String? hint,
    String? helper,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InputDecoration(
      floatingLabelBehavior: FloatingLabelBehavior.never,
      isDense: false,
      isCollapsed: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(minHeight: kFieldHeight),
      hintText: hint,
      helperText: helper,
      // Keep height stable when error by suppressing the default error line
      errorStyle: const TextStyle(fontSize: 0, height: 0),
      hintStyle: theme.textTheme.bodySmall?.copyWith(
        fontSize: 12,
        color: cs.onSurfaceVariant,
      ),
      helperStyle: theme.textTheme.bodySmall?.copyWith(
        fontSize: 11,
        color: cs.onSurfaceVariant.withOpacity(0.60),
      ),
      filled: true,
      fillColor: cs.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
          width: kOutlineWidth,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: kFocusedOutlineWidth),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error, width: kOutlineWidth),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error, width: kOutlineWidth),
      ),
      labelText: label,
    );
  }

  Widget _rowLabelField({required String label, required Widget field}) {
    final width = MediaQuery.of(context).size.width;
    final labelWidth = width >= 400 ? 120.0 : 110.0;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            height: 36,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                textAlign: TextAlign.left,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.75),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: field),
        ],
      ),
    );
  }

  Widget _intStepper({
    required TextEditingController controller,
    int step = 1,
    int min = 0,
    int max = 1000000,
    int width = 80,
    String? label,
    String? hint,
    String? helper,
    bool error = false,
  }) {
    return SizedBox(
      height: 36,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _incBtn('−', () {
              final v = int.tryParse(controller.text.trim()) ?? 0;
              final nv = (v - step).clamp(min, max);
              setState(() {
                controller.text = nv.toString();
                if (identical(controller, _lowStockThresholdCtrl)) {
                  _lowStockClampHint = false;
                }
              });
            }),
            const SizedBox(width: 6),
            SizedBox(
              width: width.toDouble(),
              child: SizedBox(
                height: kFieldHeight,
                child: TextFormField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: kInputFontSize),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: false,
                    decimal: false,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: (() {
                    final base = _dec(
                      label: label ?? '',
                      hint: hint,
                      helper: helper,
                    );
                    if (!error) return base;
                    final cs = Theme.of(context).colorScheme;
                    return base.copyWith(
                      // Do not set errorText so InputDecorator doesn't alter layout
                      errorText: null,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cs.error, width: kOutlineWidth),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cs.error, width: kOutlineWidth),
                      ),
                    );
                  })(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _incBtn('+', () {
              final v = int.tryParse(controller.text.trim()) ?? 0;
              final nv = (v + step).clamp(min, max);
              setState(() {
                controller.text = nv.toString();
                if (identical(controller, _lowStockThresholdCtrl)) {
                  _lowStockClampHint = nv == v;
                }
              });
            }),
          ],
        ),
      ),
    );
  }

  void _updateSummaryHeight() {
    // Measure the summary card height and update spacer
    final ctx = _summaryKey.currentContext;
    if (ctx != null) {
      final rb = ctx.findRenderObject();
      if (rb is RenderBox) {
        final h = rb.size.height;
        if (h != _summaryHeight && h > 0) {
          setState(() => _summaryHeight = h);
        }
      }
    }
  }

  Widget _floatingSummary(BuildContext context) {
    final name = _nameCtrl.text.trim();
    final manufacturer = _manufacturerCtrl.text.trim();
    final double? strengthVal = double.tryParse(_strengthValueCtrl.text.trim());
    final double? stockVal = double.tryParse(_stockCtrl.text.trim());
    final initialStock = widget.initial?.initialStockValue ?? stockVal ?? 0;
    final unit = _unitLabel(_strengthUnit);
    final headerTitle = name.isEmpty ? 'Tablets' : name;
    final double? threshold = double.tryParse(_lowStockThresholdCtrl.text.trim());

    final card = SummaryHeaderCard(
      key: _summaryKey,
      title: headerTitle,
      manufacturer: manufacturer.isEmpty ? null : manufacturer,
      strengthValue: strengthVal,
      strengthUnitLabel: unit,
      stockCurrent: stockVal ?? 0,
      stockInitial: initialStock,
      stockUnitLabel: 'tablets',
      expiryDate: _expiryDate,
      showRefrigerate: _keepRefrigerated,
      showFrozen: _keepFrozen,
      showDark: _lightSensitive,
      lowStockEnabled: _lowStockAlert,
      lowStockThreshold: threshold,
      includeNameInStrengthLine: false,
      perTabletLabel: name.isNotEmpty,
      formLabelPlural: 'tablets',
    );

    // Schedule measurement after the frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateSummaryHeight());

    return card;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[GENERAL] build() called');
    debugPrint('[GENERAL] step=hybrid-dec-no-bottom');
    final mq = MediaQuery.of(context);

    // Derive validation messages for helper rows
    final theme = Theme.of(context);
    String? nameError = _nameCtrl.text.trim().isEmpty ? 'Required' : null;
    String? strengthAmtError;
    final sTxt = _strengthValueCtrl.text.trim();
    if (sTxt.isEmpty) {
      strengthAmtError = 'Required';
    } else {
      final d = double.tryParse(sTxt);
      if (d == null)
        strengthAmtError = 'Invalid number';
      else if (d <= 0)
        strengthAmtError = 'Must be > 0';
    }
    // Stock rules: required, valid number, >= 0 and allow any .00/.25/.50/.75
    String? stockError;
    final stockTxt = _stockCtrl.text.trim();
    double stockVal = 0;
    if (stockTxt.isEmpty) {
      stockError = 'Required';
    } else {
      final d = double.tryParse(stockTxt);
      if (d == null) {
        stockError = 'Invalid number';
      } else if (d < 0) {
        stockError = 'Must be ≥ 0';
      } else {
        stockVal = d;
        final quarters = ((d * 100).round() % 25 == 0);
        if (!quarters) stockError = 'Use .00, .25, .50, or .75';
      }
    }
    // Threshold should not exceed stock
    String? thresholdError;
    if (_lowStockAlert && _lowStockThresholdCtrl.text.trim().isNotEmpty) {
      final t = int.tryParse(_lowStockThresholdCtrl.text.trim());
      if (t == null || t < 0) {
        thresholdError = 'Invalid number';
      } else if (t > stockVal) {
        thresholdError = 'Threshold cannot exceed stock';
      }
    }
    // Gate errors until the field is touched or the form has been submitted
    final String? gNameError = (_submitted || _touchedName) ? nameError : null;
    final String? gStrengthAmtError = (_submitted || _touchedStrengthAmt)
        ? strengthAmtError
        : null;
    final String? gStockError = (_submitted || _touchedStock)
        ? (stockError ?? _stockError)
        : null;

    // Determine if required fields are valid (for Save button state)
    final bool requiredOk = (() {
      final nameOk = _nameCtrl.text.trim().isNotEmpty;
      final aTxt = _strengthValueCtrl.text.trim();
      final a = double.tryParse(aTxt);
      final amtOk = a != null && a > 0;
      final sTxt2 = _stockCtrl.text.trim();
      final s2 = double.tryParse(sTxt2);
      bool quartersOk = true;
      if (s2 != null) {
        quartersOk = ((s2 * 100).round() % 25 == 0) && s2 >= 0;
      }
      final stockOk = s2 != null && s2 >= 0 && quartersOk;
      return nameOk && amtOk && stockOk;
    })();

    return Scaffold(
      appBar: GradientAppBar(
        title: widget.initial == null ? 'Add Tablet' : 'Edit Tablet',
      ),
      body: Stack(
        children: [
          // Scrollable content first
          SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 96),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: _summaryHeight + 10),
                  _section('General', [
                    _rowLabelField(
                      label: 'Name *',
                      field: Field36(
                        child: TextFormField(
                          controller: _nameCtrl,
                          textAlign: TextAlign.left,
                          textAlignVertical: TextAlignVertical.center,
                          textCapitalization: TextCapitalization.sentences,
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration:
                              _dec(
                                label: 'Name *',
hint: 'eg. DosifiTab-500'
                              ).copyWith(
                                errorText: null,
                                enabledBorder: gNameError == null
                                    ? null
                                    : OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: kOutlineWidth),
                                      ),
                                focusedBorder: gNameError == null
                                    ? null
                                    : OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: kOutlineWidth),
                                      ),
                              ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                          onChanged: (_) => setState(() {
                            _touchedName = true;
                          }),
                        ),
                      ),
                    ),
                    if (gNameError != null) _errorUnderLabel(gNameError),
                    _helperBelowLeft('Enter the medication name'),
                    _rowLabelField(
                      label: 'Manufacturer',
                      field: Field36(
                        child: TextFormField(
                          controller: _manufacturerCtrl,
                          textAlign: TextAlign.left,
                          textAlignVertical: TextAlignVertical.center,
                          textCapitalization: TextCapitalization.sentences,
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: _dec(
                            label: 'Manufacturer',
hint: 'eg. Dosifi Labs'
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    _helperBelowLeft('Enter the brand or company name'),
                    _rowLabelField(
                      label: 'Description',
                      field: Field36(
                        child: TextFormField(
                          controller: _descriptionCtrl,
                          textAlign: TextAlign.left,
                          textAlignVertical: TextAlignVertical.center,
                          textCapitalization: TextCapitalization.sentences,
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: _dec(
                            label: 'Description',
hint: 'eg. Pain relief'
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    _helperBelowLeft('Optional short description'),
                    _rowLabelField(
                      label: 'Notes',
                      field: TextFormField(
                        controller: _notesCtrl,
                        textAlign: TextAlign.left,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        minLines: 2,
                        maxLines: null,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: _dec(
                          label: 'Notes',
hint: 'eg. Take with water'
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    _helperBelowLeft('Optional notes'),
                  ]),
                  const SizedBox(height: 10),
                  _section('Strength', [
                    _rowLabelField(
                      label: 'Strength *',
                      field: SizedBox(
                        height: 36,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _incBtn('−', () {
                              final d = double.tryParse(
                                _strengthValueCtrl.text.trim(),
                              );
                              final base = d?.floor() ?? 0;
                              final nv = (base - 1).clamp(0, 1000000000);
                              setState(() {
                                _strengthValueCtrl.text = nv.toString();
                                _touchedStrengthAmt = true;
                              });
                            }),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 120,
                              child: Field36(
                                child: TextFormField(
                                  controller: _strengthValueCtrl,
                                  textAlign: TextAlign.center,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^$|^\d{0,7}(?:\.\d{0,2})?$'),
                                    ),
                                  ],
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  decoration: _dec(label: 'Amount *', hint: '0')
                                      .copyWith(
                                        errorText: null,
                                        enabledBorder: gStrengthAmtError == null
                                            ? null
                                            : OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: kOutlineWidth),
                                              ),
                                        focusedBorder: gStrengthAmtError == null
                                            ? null
                                            : OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: kOutlineWidth),
                                              ),
                                      ),
                                  validator: (v) {
                                    final t = v?.trim() ?? '';
                                    if (t.isEmpty) return 'Required';
                                    final d = double.tryParse(t);
                                    if (d == null) return 'Invalid number';
                                    if (d <= 0) return 'Must be > 0';
                                    return null;
                                  },
                                  onChanged: (_) => setState(() {
                                    _touchedStrengthAmt = true;
                                  }),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _incBtn('+', () {
                              final d = double.tryParse(
                                _strengthValueCtrl.text.trim(),
                              );
                              final base = d?.floor() ?? 0;
                              final nv = (base + 1).clamp(0, 1000000000);
                              setState(() {
                                _strengthValueCtrl.text = nv.toString();
                                _touchedStrengthAmt = true;
                              });
                            }),
                          ],
                        ),
                      ),
                    ),
                    _rowLabelField(
                      label: 'Unit *',
                      field: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              height: kFieldHeight,
                              width: 120,
                              child: DropdownButtonFormField<Unit>(
                                value: _strengthUnit,
                                isExpanded: false,
                                alignment: AlignmentDirectional.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                                dropdownColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                                menuMaxHeight: 320,
                                selectedItemBuilder: (ctx) =>
                                    const [Unit.mcg, Unit.mg, Unit.g]
                                        .map(
                                          (u) => Center(
                                            child: Text(
                                              u == Unit.mcg
                                                  ? 'mcg'
                                                  : (u == Unit.mg ? 'mg' : 'g'),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                items: const [Unit.mcg, Unit.mg, Unit.g]
                                    .map(
                                      (u) => DropdownMenuItem(
                                        value: u,
                                        alignment: AlignmentDirectional.center,
                                        child: Center(
                                          child: Text(
                                            u == Unit.mcg
                                                ? 'mcg'
                                                : (u == Unit.mg ? 'mg' : 'g'),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (u) => setState(
                                  () => _strengthUnit = u ?? _strengthUnit,
                                ),
                                decoration: _decDrop(
                                  label: '',
                                  hint: null,
                                  helper: null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                      ),
                    ),
                    if (gStrengthAmtError != null)
                      _errorUnderLabel(gStrengthAmtError),
                    _helperBelowCenter(
                      'Specify the amount per tablet and its unit of measurement.',
                    ),
                  ]),

                  const SizedBox(height: 10),
                  _section('Inventory', [
                    _rowLabelField(
                      label: 'Stock quantity *',
                      field: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: kFieldHeight,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _incBtn('−', () {
                                  final d =
                                      double.tryParse(_stockCtrl.text.trim()) ??
                                      0;
                                  final nv = (d - 1)
                                      .clamp(0, 1000000000)
                                      .toStringAsFixed(0);
                                  setState(() {
                                    _stockCtrl.text = nv;
                                    _touchedStock = true;
                                  });
                                }),
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: 120,
                                  child: Field36(
                                    child: TextFormField(
                                      controller: _stockCtrl,
                                      textAlign: TextAlign.center,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^$|^\d{0,7}(?:\.\d{0,2})?$'),
                                        ),
                                      ],
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                      decoration:
                                          _dec(
                                            label: 'Stock amount *',
                                            hint: '0.00',
                                          ).copyWith(
                                            errorText: null,
                                            enabledBorder: gStockError == null
                                                ? null
                                                : OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                    borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: kOutlineWidth),
                                                  ),
                                            focusedBorder: gStockError == null
                                                ? null
                                                : OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                    borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: kOutlineWidth),
                                                  ),
                                          ),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty)
                                          return 'Required';
                                        final d = double.tryParse(v);
                                        if (d == null) return 'Invalid number';
                                        if (d < 0) return 'Must be ≥ 0';
                                        return null;
                                      },
                                      onChanged: (v) {
                                        final d = double.tryParse(v);
                                        setState(() {
                                          _touchedStock = true;
                                          if (d == null ||
                                              ((d * 100).round() % 25 == 0)) {
                                            _stockError = null;
                                          } else {
                                            _stockError =
                                                'Use .00, .25, .50, or .75';
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _incBtn('+', () {
                                  final d =
                                      double.tryParse(_stockCtrl.text.trim()) ??
                                      0;
                                  final nv = (d + 1)
                                      .clamp(0, 1000000000)
                                      .toStringAsFixed(0);
                                  setState(() {
                                    _stockCtrl.text = nv;
                                    _touchedStock = true;
                                  });
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _rowLabelField(
                      label: 'Quantity unit',
                      field: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              height: kFieldHeight,
                              width: 120,
                              child: DropdownButtonFormField<String>(
                                value: 'tablets',
                                isExpanded: false,
                                alignment: AlignmentDirectional.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                                dropdownColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                                menuMaxHeight: 320,
                                selectedItemBuilder: (ctx) => const [
                                  'tablets',
                                ].map((t) => Center(child: Text(t))).toList(),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'tablets',
                                    child: Center(child: Text('tablets')),
                                  ),
                                ],
                                onChanged: null, // locked
                                decoration: _decDrop(
                                  label: '',
                                  hint: null,
                                  helper: null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                    _supportBelowLeftFixed(
                      error: gStockError,
                      help: 'Enter the amount of tablets in stock',
                    ),

                    // Low stock alert toggle + threshold
                    _rowLabelField(
                      label: 'Low stock alert',
                      field: Row(
                        children: [
                          Checkbox(
                            value: _lowStockAlert,
                            onChanged: (v) =>
                                setState(() => _lowStockAlert = v ?? false),
                          ),
                          Expanded(
                            child: Text(
                              'Enable alert when stock is low',
                              style: kCheckboxLabelStyle(context),
                              softWrap: true,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_lowStockAlert) ...[
                      _rowLabelField(
                        label: 'Threshold',
                        field: _intStepper(
                          controller: _lowStockThresholdCtrl,
                          step: 1,
                          min: 0,
                          max: stockVal.floor(),
                          width: 120,
                          label: 'Threshold',
                          hint: '0',
                          error: thresholdError != null,
                        ),
                      ),
                      _supportBelowLeftFixed(
                        error: thresholdError,
                        help: (() {
                          if (_lowStockClampHint) {
                            return 'Max threshold cannot exceed stock count.';
                          }
                          return 'Set the stock level that triggers a low stock alert';
                        })(),
                        compact: true,
                        color: _lowStockClampHint ? Colors.orange : null,
                      ),
                    ],
                    _rowLabelField(
                      label: 'Expiry date',
                      field: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.center,
child: SizedBox(
                              height: kFieldHeight,
                              width: 120,
                              child: DateButton36(
                                label: _expiryDate == null
                                    ? 'Select date'
                                    : _fmtDateLocal(context, _expiryDate!),
                                onPressed: () async {
                                  final now = DateTime.now();
                                  final picked = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime(now.year - 1),
                                    lastDate: DateTime(now.year + 10),
                                    initialDate: _expiryDate ?? now,
                                  );
                                  if (picked != null) setState(() => _expiryDate = picked);
                                },
                                width: 120,
                                selected: _expiryDate != null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                      ),
                    ),
                    _helperBelowLeft('Enter the expiry date'),
                  ]),

                  // Storage
                  const SizedBox(height: 10),
                  _section('Storage', [
                    _rowLabelField(
                      label: 'Batch No.',
                      field: Field36(
                        child: TextFormField(
                          controller: _batchNumberCtrl,
                          textAlign: TextAlign.left,
                          textAlignVertical: TextAlignVertical.center,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _dec(
                            label: 'Batch No.',
                            hint: 'Enter batch number',
                          ),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    _helperBelowLeft('Enter the printed batch or lot number'),
                    _rowLabelField(
                      label: 'Location',
                      field: Field36(
                        child: TextFormField(
                          controller: _storageLocationCtrl,
                          textAlign: TextAlign.left,
                          textAlignVertical: TextAlignVertical.center,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _dec(
                            label: 'Location',
                            hint: 'eg. Bathroom cabinet',
                          ),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    _helperBelowLeft(
                      'Where it’s stored (e.g., Bathroom cabinet)',
                    ),
                    // Removed 'Store below (°C)' per requirements
_rowLabelField(
                      label: 'Keep refrigerated',
                      field: Opacity(
                        opacity: _keepFrozen ? 0.5 : 1.0,
                        child: Row(
                          children: [
                            Checkbox(
                              value: _keepRefrigerated,
                            onChanged: _keepFrozen
                                ? null
                                : (v) => setState(
                                    () => _keepRefrigerated = v ?? false,
                                  ),
                          ),
                          Text(
                            'Refrigerate',
                            style: _keepFrozen
                                ? kMutedLabelStyle(context)
                                : kCheckboxLabelStyle(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                    _helperBelowLeftCompact(
                      'Enable if this medication must be kept refrigerated',
                    ),
                    _rowLabelField(
                      label: 'Keep frozen',
                      field: Row(
                        children: [
                          Checkbox(
                            value: _keepFrozen,
                            onChanged: (v) => setState(() {
                              _keepFrozen = v ?? false;
                              if (_keepFrozen) _keepRefrigerated = false;
                            }),
                          ),
                          Text('Freeze', style: kCheckboxLabelStyle(context)),
                        ],
                      ),
                    ),
                    _helperBelowLeftCompact(
                      'Enable if this medication must be kept frozen',
                    ),
                    _rowLabelField(
                      label: 'Keep in dark',
                      field: Row(
                        children: [
                          Checkbox(
                            value: _lightSensitive,
                            onChanged: (v) =>
                                setState(() => _lightSensitive = v ?? false),
                          ),
                          Text(
                            'Dark storage',
                            style: kCheckboxLabelStyle(context),
                          ),
                        ],
                      ),
                    ),
                    _helperBelowLeftCompact(
                      'Enable if this medication must be protected from light',
                    ),
                    _rowLabelField(
                      label: 'Storage instructions',
                      field: Field36(
                        child: TextFormField(
                          controller: _storageInstructionsCtrl,
                          textAlign: TextAlign.left,
                          textCapitalization: TextCapitalization.sentences,
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: _dec(
                            label: 'Storage instructions',
                            hint: 'Enter storage instructions',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    _helperBelowLeft(
                      'Special handling notes (e.g., Keep upright)',
                    ),
                  ]),
                ],
              ),
            ),
          ),
          // Floating summary card pinned below app bar; overlays content without shifting it
          Positioned(
            left: 10,
            right: 10,
            top: 8,
            child: IgnorePointer(child: _floatingSummary(context)),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 120,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: requiredOk
                ? null
                : Theme.of(context).colorScheme.surfaceVariant,
            foregroundColor: requiredOk
                ? null
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          onPressed: () async {
            setState(() => _submitted = true);
            if (!requiredOk) return; // show gated errors only
            if (!(_formKey.currentState?.validate() ?? false)) return;
            await _showConfirmDialog();
          },
          child: const Text('Save'),
        ),
      ),
    );
  }

  Widget _incBtn(String symbol, VoidCallback onTap) {
    return SizedBox(
      height: 30,
      width: 30,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          minimumSize: const Size(30, 30),
        ),
        onPressed: onTap,
        child: Text(symbol),
      ),
    );
  }

  Widget _generalSummary() {
    final name = _nameCtrl.text.trim();
    final mfr = _manufacturerCtrl.text.trim();
    if (name.isEmpty && mfr.isEmpty) return const SizedBox.shrink();
    final s = name.isEmpty ? mfr : (mfr.isEmpty ? name : '$name – $mfr');
    return Text(s, overflow: TextOverflow.ellipsis);
  }

  Widget _strengthSummary() {
    // Hide until user changes the default (0) value
    if (!_touchedStrengthAmt) return const SizedBox.shrink();
    final txt = _strengthValueCtrl.text.trim();
    final d = double.tryParse(txt) ?? 0;
    if (d <= 0) return const SizedBox.shrink();
    final name = _nameCtrl.text.trim();
    final unit = _strengthUnit == Unit.mcg
        ? 'mcg'
        : _strengthUnit == Unit.mg
        ? 'mg'
        : 'g';
    final med = name.isEmpty ? '' : ' per $name tablet';
    return Text(
      '${d.toStringAsFixed(d == d.roundToDouble() ? 0 : 2)}$unit$med',
    );
  }

  Widget _inventorySummary() {
    // Hide until user changes the default (0) value
    if (!_touchedStock) return const SizedBox.shrink();
    final v = _stockCtrl.text.trim();
    if (v.isEmpty) return const SizedBox.shrink();
    final name = _nameCtrl.text.trim();
    final tail = name.isEmpty ? ' tablets' : ' $name tablets';
    return Text('$v$tail');
  }

  Widget _storageSummary() {
    final parts = <String>[];
    if (_keepRefrigerated) parts.add('Fridge');
    if (_storageLocationCtrl.text.trim().isNotEmpty)
      parts.add(_storageLocationCtrl.text.trim());
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(parts.join(' · '));
  }

  Widget _expirySummary() {
    if (_expiryDate == null) return const SizedBox.shrink();
    return Text(_fmtDateLocal(context, _expiryDate!));
  }

  String _fmtDateLocal(BuildContext ctx, DateTime d) {
    // Use platform/material localization for date formatting (locale-aware)
    final loc = MaterialLocalizations.of(ctx);
    return loc.formatCompactDate(d);
  }

  Future<void> _showConfirmDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Center(
          child: Text(
            'Confirm medication',
            textAlign: TextAlign.center,
            style: Theme.of(
              ctx,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        content: SingleChildScrollView(child: _buildConfirmContent(ctx)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _persistMedication();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _persistMedication() async {
    try {
      final box = Hive.box<Medication>('medications');
      final repo = MedicationRepository(box);
      final id = widget.initial?.id ?? _newId();
      final strength = double.tryParse(_strengthValueCtrl.text.trim()) ?? 0;
      final stock = double.tryParse(_stockCtrl.text.trim()) ?? 0;
      final lowThresh = double.tryParse(_lowStockThresholdCtrl.text.trim());
      final previous = widget.initial;
      final initialStock = previous == null
          ? stock
          : (stock > previous.stockValue
                ? stock
                : (previous.initialStockValue ?? previous.stockValue));
      final med = Medication(
        id: id,
        form: MedicationForm.tablet,
        name: _nameCtrl.text.trim(),
        manufacturer: _manufacturerCtrl.text.trim().isEmpty
            ? null
            : _manufacturerCtrl.text.trim(),
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        strengthValue: strength,
        strengthUnit: _strengthUnit,
        stockValue: stock,
        stockUnit: StockUnit.tablets,
        lowStockEnabled: _lowStockAlert,
        lowStockThreshold: _lowStockAlert ? lowThresh : null,
        expiry: _expiryDate,
        batchNumber: _batchNumberCtrl.text.trim().isEmpty
            ? null
            : _batchNumberCtrl.text.trim(),
        storageLocation: _storageLocationCtrl.text.trim().isEmpty
            ? null
            : _storageLocationCtrl.text.trim(),
        requiresRefrigeration: _keepRefrigerated,
        storageInstructions: (() {
          final parts = <String>[];
          final s = _storageInstructionsCtrl.text.trim();
          if (s.isNotEmpty) parts.add(s);
          if (_keepFrozen && !parts.any((p) => p.toLowerCase().contains('frozen')))
            parts.add('Keep frozen');
          if (_lightSensitive && !parts.any((p) => p.toLowerCase().contains('light')))
            parts.add('Protect from light');
          return parts.isEmpty ? null : parts.join('. ');
        })(),
        initialStockValue: initialStock,
      );
      await repo.upsert(med);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Medication saved')));
        context.go('/medications');
      }
    } catch (e, st) {
      debugPrint('Save failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  String _newId() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    return 'med_$ms';
  }

  Widget _buildConfirmContent(BuildContext ctx) {
    final theme = Theme.of(ctx);
    // Swap styles: labels bold blue (primary), values standard onSurface
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w800,
    );
    final valueStyle = theme.textTheme.bodyMedium;
    Widget row(String l, String v) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(l, style: labelStyle)),
          const SizedBox(width: 8),
          Expanded(child: Text(v.isEmpty ? '-' : v, style: valueStyle)),
        ],
      ),
    );
    String _trimZero(String s) {
      if (!s.contains('.')) return s;
      s = s.replaceFirst(RegExp(r'\.0+$'), '');
      s = s.replaceFirst(RegExp(r'(\.\d*?)0+$'), r'$1');
      if (s.endsWith('.')) s = s.substring(0, s.length - 1);
      return s;
    }

    final strengthRaw = _strengthValueCtrl.text.trim();
    final strengthText = strengthRaw.isEmpty
        ? ''
        : '${_trimZero(strengthRaw)} ${_strengthUnit == Unit.mcg
              ? 'mcg'
              : _strengthUnit == Unit.mg
              ? 'mg'
              : 'g'}';
    final stockRaw = _stockCtrl.text.trim();
    final inventoryText = stockRaw.isEmpty
        ? ''
        : _trimZero(stockRaw) + ' tablets';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('Name', _nameCtrl.text.trim()),
        row('Manufacturer', _manufacturerCtrl.text.trim()),
        row('Description', _descriptionCtrl.text.trim()),
        row('Notes', _notesCtrl.text.trim()),
        row('Strength', strengthText),
        row(
          'Stock',
          inventoryText.isEmpty
              ? (_stockCtrl.text.trim().isEmpty
                    ? ''
                    : _stockCtrl.text.trim() + ' tablets')
              : inventoryText,
        ),
        row('Quantity unit', 'tablets'),
        row(
          'Low stock alerts',
          _lowStockAlert
              ? 'On at ${_lowStockThresholdCtrl.text.trim()}'
              : 'Off',
        ),
        row('Expiry', _expiryDate == null ? '' : MaterialLocalizations.of(ctx).formatCompactDate(_expiryDate!)),
        row('Batch', _batchNumberCtrl.text.trim()),
        row('Storage location', _storageLocationCtrl.text.trim()),
        row('Requires refrigeration', _keepRefrigerated ? 'Yes' : 'No'),
        row('Keep frozen', _keepFrozen ? 'Yes' : 'No'),
        row('Dark storage', _lightSensitive ? 'Yes' : 'No'),
        row('Storage instructions', _storageInstructionsCtrl.text.trim()),
      ],
    );
  }

  String _buildSummary() {
    return [
      'Name: ' +
          (_nameCtrl.text.trim().isEmpty ? '(empty)' : _nameCtrl.text.trim()),
      'Manufacturer: ' +
          (_manufacturerCtrl.text.trim().isEmpty
              ? '(empty)'
              : _manufacturerCtrl.text.trim()),
      'Description: ' +
          (_descriptionCtrl.text.trim().isEmpty
              ? '(empty)'
              : _descriptionCtrl.text.trim()),
      'Notes: ' +
          (_notesCtrl.text.trim().isEmpty ? '(empty)' : _notesCtrl.text.trim()),
      'Strength: ' +
          (_strengthValueCtrl.text.trim().isEmpty
              ? '(empty)'
              : _strengthValueCtrl.text.trim()) +
          ' ' +
          (_strengthUnit == Unit.mcg
              ? 'mcg'
              : _strengthUnit == Unit.mg
              ? 'mg'
              : 'g'),
      'Stock: ' +
          (_stockCtrl.text.trim().isEmpty
              ? '(empty)'
              : _stockCtrl.text.trim()) +
          ' tablets',
      'Low stock alert: ' + (_lowStockAlert ? 'ON' : 'OFF'),
      if (_lowStockAlert)
        'Threshold: ' +
            (_lowStockThresholdCtrl.text.trim().isEmpty
                ? '(empty)'
                : _lowStockThresholdCtrl.text.trim()),
      'Batch: ' +
          (_batchNumberCtrl.text.trim().isEmpty
              ? '(empty)'
              : _batchNumberCtrl.text.trim()),
      'Storage location: ' +
          (_storageLocationCtrl.text.trim().isEmpty
              ? '(empty)'
              : _storageLocationCtrl.text.trim()),
      'Cold storage: ' + (_keepRefrigerated ? 'Yes' : 'No'),
      'Light sensitive: ' + (_lightSensitive ? 'Yes' : 'No'),
      'Storage instructions: ' +
          (_storageInstructionsCtrl.text.trim().isEmpty
              ? '(empty)'
              : _storageInstructionsCtrl.text.trim()),
'Expiry: ' + (_expiryDate == null ? '(none)' : _fmtDateLocal(context, _expiryDate!)),
    ].join('\n');
  }
}
