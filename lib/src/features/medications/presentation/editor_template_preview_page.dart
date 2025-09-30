import 'package:flutter/material.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/summary_header_card.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/widgets/med_editor_template.dart';

class EditorTemplatePreviewPage extends StatefulWidget {
  const EditorTemplatePreviewPage({super.key});

  @override
  State<EditorTemplatePreviewPage> createState() => _EditorTemplatePreviewPageState();
}

class _EditorTemplatePreviewPageState extends State<EditorTemplatePreviewPage> {
  // Inventory alert state
  bool _lowStockAlert = false;
  final _lowStockThreshold = TextEditingController(text: '0');
  final _name = TextEditingController();
  final _manufacturer = TextEditingController();
  final _description = TextEditingController();
  final _notes = TextEditingController();

  final _strength = TextEditingController(text: '0');
  Unit _strengthUnit = Unit.mg;
  final _perMl = TextEditingController();
  bool get _isPerMl =>
      _strengthUnit == Unit.mcgPerMl || _strengthUnit == Unit.mgPerMl || _strengthUnit == Unit.gPerMl || _strengthUnit == Unit.unitsPerMl;

  final _stock = TextEditingController(text: '0');
  StockUnit _stockUnit = StockUnit.preFilledSyringes;
  DateTime? _expiry;

  final _batch = TextEditingController();
  final _location = TextEditingController();
  final _storageNotes = TextEditingController();
  bool _refrigerate = false;
  bool _keepFrozen = false;
  bool _lightSensitive = false;

  String _unitLabel(Unit u) {
    if (u == Unit.mcg || u == Unit.mcgPerMl) return 'mcg';
    if (u == Unit.mg || u == Unit.mgPerMl) return 'mg';
    if (u == Unit.g || u == Unit.gPerMl) return 'g';
    return 'units';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Editor Template (Preview)', forceBackButton: true),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(width: 140, child: FilledButton.icon(onPressed: null, icon: const Icon(Icons.save), label: const Text('Save'))),
      body: MedEditorTemplate(
        appBarTitle: 'Editor Template (Preview)',
        summaryBuilder: (key) {
          final name = _name.text.trim();
          final manufacturer = _manufacturer.text.trim();
          final strengthVal = double.tryParse(_strength.text.trim());
          final stockVal = double.tryParse(_stock.text.trim());
          final unitLabel = _unitLabel(_strengthUnit);
          return SummaryHeaderCard(
            key: key,
            title: name.isEmpty ? 'Pre‑Filled Syringes' : name,
            manufacturer: manufacturer.isEmpty ? null : manufacturer,
            strengthValue: strengthVal,
            strengthUnitLabel: _isPerMl ? '$unitLabel/mL' : unitLabel,
            stockCurrent: stockVal ?? 0,
            stockInitial: stockVal ?? 0,
            stockUnitLabel: 'pre filled syringes',
            expiryDate: _expiry,
            showRefrigerate: _refrigerate,
            showFrozen: _keepFrozen,
            showDark: _lightSensitive,
            lowStockEnabled: _lowStockAlert,
            lowStockThreshold: double.tryParse(_lowStockThreshold.text.trim()),
            includeNameInStrengthLine: false,
            perTabletLabel: name.isNotEmpty,
            formLabelPlural: 'pre filled syringes',
          );
        },

        // General
        nameField: Field36(
          child: TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'eg. AcmeTab-500'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        manufacturerField: Field36(
          child: TextFormField(
            controller: _manufacturer,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'eg. Contoso Pharma'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        descriptionField: Field36(
          child: TextFormField(
            controller: _description,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'eg. Pain relief'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        notesField: Field36(
          child: TextFormField(
            controller: _notes,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'eg. Take with food'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        nameHelp: 'Enter the medication name',
        manufacturerHelp: 'Enter the brand or company name',
        descriptionHelp: 'Optional short description',
        notesHelp: 'Optional notes',

        // Strength
        strengthStepper: StepperRow36(
          controller: _strength,
          onDec: () {
            final v = int.tryParse(_strength.text.trim()) ?? 0;
            setState(() => _strength.text = (v - 1).clamp(0, 1000000).toString());
          },
          onInc: () {
            final v = int.tryParse(_strength.text.trim()) ?? 0;
            setState(() => _strength.text = (v + 1).clamp(0, 1000000).toString());
          },
          decoration: const InputDecoration(
            hintText: '0',
            isDense: false,
            isCollapsed: false,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: BoxConstraints(minHeight: kFieldHeight),
          ),
        ),
        unitDropdown: SmallDropdown36<Unit>(
          value: _strengthUnit,
          width: kSmallControlWidth,
          items: const [
            DropdownMenuItem(value: Unit.mcg, child: Center(child: Text('mcg'))),
            DropdownMenuItem(value: Unit.mg, child: Center(child: Text('mg'))),
            DropdownMenuItem(value: Unit.g, child: Center(child: Text('g'))),
            DropdownMenuItem(value: Unit.units, child: Center(child: Text('units'))),
            DropdownMenuItem(value: Unit.mcgPerMl, child: Center(child: Text('mcg/mL'))),
            DropdownMenuItem(value: Unit.mgPerMl, child: Center(child: Text('mg/mL'))),
            DropdownMenuItem(value: Unit.gPerMl, child: Center(child: Text('g/mL'))),
            DropdownMenuItem(value: Unit.unitsPerMl, child: Center(child: Text('units/mL'))),
          ],
          onChanged: (v) => setState(() => _strengthUnit = v ?? _strengthUnit),
        ),
        perMlStepper: _isPerMl
            ? StepperRow36(
                controller: _perMl,
                onDec: () {
                  final v = double.tryParse(_perMl.text.trim()) ?? 0;
                  setState(() => _perMl.text = (v - 1).clamp(0, 1000000).toStringAsFixed(0));
                },
                onInc: () {
                  final v = double.tryParse(_perMl.text.trim()) ?? 0;
                  setState(() => _perMl.text = (v + 1).clamp(0, 1000000).toStringAsFixed(0));
                },
                decoration: const InputDecoration(
                  hintText: '0',
                  isDense: false,
                  isCollapsed: false,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: BoxConstraints(minHeight: kFieldHeight),
                ),
              )
            : null,
        strengthHelp: 'Specify the amount per dose and its unit of measurement.',
        perMlHelp: _isPerMl ? 'Enter the volume per mL' : null,

        // Inventory
        stockStepper: StepperRow36(
          controller: _stock,
          onDec: () {
            final v = int.tryParse(_stock.text.trim()) ?? 0;
            setState(() => _stock.text = (v - 1).clamp(0, 1000000).toString());
          },
          onInc: () {
            final v = int.tryParse(_stock.text.trim()) ?? 0;
            setState(() => _stock.text = (v + 1).clamp(0, 1000000).toString());
          },
          decoration: const InputDecoration(
            hintText: '0',
            isDense: false,
            isCollapsed: false,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: BoxConstraints(minHeight: kFieldHeight),
          ),
        ),
        stockHelp: 'Enter the amount currently in stock',
        lowStockRow: Row(
          children: [
            Checkbox(value: _lowStockAlert, onChanged: (v) => setState(() => _lowStockAlert = v ?? false)),
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
        lowStockThresholdField: _lowStockAlert
            ? StepperRow36(
                controller: _lowStockThreshold,
                onDec: () {
                  final v = int.tryParse(_lowStockThreshold.text.trim()) ?? 0;
                  setState(() => _lowStockThreshold.text = (v - 1).clamp(0, 1000000).toString());
                },
                onInc: () {
                  final v = int.tryParse(_lowStockThreshold.text.trim()) ?? 0;
                  final maxStock = int.tryParse(_stock.text.trim()) ?? 0;
                  setState(() => _lowStockThreshold.text = (v + 1).clamp(0, maxStock).toString());
                },
                decoration: const InputDecoration(
                  hintText: '0',
                  isDense: false,
                  isCollapsed: false,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: BoxConstraints(minHeight: kFieldHeight),
                ),
              )
            : null,
        lowStockHelp: _lowStockAlert
            ? (() {
                final stock = int.tryParse(_stock.text.trim()) ?? 0;
                final thr = int.tryParse(_lowStockThreshold.text.trim()) ?? 0;
                if (stock > 0 && thr >= stock) {
                  return 'Max threshold is the current stock ($stock ${_stockUnit.name.replaceAll('_', ' ')}).';
                }
                return 'Set the stock level that triggers a low stock alert';
              })()
            : null,
        quantityDropdown: SmallDropdown36<StockUnit>(
          value: _stockUnit,
          width: kSmallControlWidth,
          items: const [
            DropdownMenuItem(value: StockUnit.preFilledSyringes, child: Center(child: Text('syringes'))),
          ],
          onChanged: (v) => setState(() => _stockUnit = v ?? _stockUnit),
        ),
        expiryDateButton: DateButton36(
          label: _expiry == null ? 'Select date' : MaterialLocalizations.of(context).formatCompactDate(_expiry!),
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime(now.year - 1),
              lastDate: DateTime(now.year + 10),
              initialDate: _expiry ?? now,
            );
            if (picked != null) setState(() => _expiry = picked);
          },
          width: kSmallControlWidth,
          selected: _expiry != null,
        ),
        expiryHelp: 'Enter the expiry date',

        // Storage
        batchField: Field36(child: TextFormField(controller: _batch, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Enter batch number'))),
        batchHelp: 'Enter the printed batch or lot number',
        locationField: Field36(child: TextFormField(controller: _location, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'eg. Bathroom cabinet'))),
        locationHelp: 'Where it’s stored (e.g., Bathroom cabinet)',
        refrigerateRow: Opacity(
          opacity: _keepFrozen ? 0.5 : 1.0,
          child: Row(children: [
            Checkbox(value: _refrigerate, onChanged: _keepFrozen ? null : (v) => setState(() => _refrigerate = v ?? false)),
            Text('Refrigerate', style: _keepFrozen ? kMutedLabelStyle(context) : Theme.of(context).textTheme.bodyMedium),
          ]),
        ),
        refrigerateHelp: 'Enable if this medication must be kept refrigerated',
        freezeRow: Row(children: [
          Checkbox(value: _keepFrozen, onChanged: (v) => setState(() { _keepFrozen = v ?? false; if (_keepFrozen) _refrigerate = false; })),
          Text('Freeze', style: Theme.of(context).textTheme.bodyMedium),
        ]),
        freezeHelp: 'Enable if this medication must be kept frozen',
        darkRow: Row(children: [
          Checkbox(value: _lightSensitive, onChanged: (v) => setState(() => _lightSensitive = v ?? false)),
          Text('Dark storage', style: Theme.of(context).textTheme.bodyMedium),
        ]),
        darkHelp: 'Enable if this medication must be protected from light',
        storageInstructionsField: Field36(child: TextFormField(controller: _storageNotes, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Enter storage instructions'))),
        storageInstructionsHelp: 'Special handling notes (e.g., Keep upright)',
      ),
    );
  }
}
