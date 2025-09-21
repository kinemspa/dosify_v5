import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';

/// Minimal Tablet editor that renders ONLY the General section.
/// This is used to isolate rendering issues step-by-step.
class AddEditTabletGeneralPage extends StatefulWidget {
  const AddEditTabletGeneralPage({super.key});

  @override
  State<AddEditTabletGeneralPage> createState() => _AddEditTabletGeneralPageState();
}

class _AddEditTabletGeneralPageState extends State<AddEditTabletGeneralPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _manufacturerCtrl.dispose();
    _descriptionCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec({required String label, String? hint, String? helper}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      constraints: const BoxConstraints(minHeight: 40),
      hintStyle: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: cs.onSurfaceVariant),
      helperStyle: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.60)),
      filled: true,
      fillColor: cs.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return Card(
      elevation: 0,
      color: isLight ? theme.colorScheme.primary.withValues(alpha: 0.05) : theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 4),
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[GENERAL] build() called');
    return Scaffold(
      appBar: const GradientAppBar(title: 'Add Tablet – General', forceBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // High-contrast debug banner to confirm body renders
              Container(
                width: double.infinity,
                alignment: Alignment.center,
                height: 36,
                margin: const EdgeInsets.only(bottom: 8),
                color: Colors.teal,
                child: const Text(
                  'DEBUG: GENERAL CARD ONLY',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
              _section('General', [
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r"\s{2,}"))],
                  decoration: _dec(label: 'Name *', hint: 'e.g., Panadol', helper: 'Enter the medication name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _manufacturerCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _dec(label: 'Manufacturer', hint: 'e.g., GlaxoSmithKline', helper: 'Enter the brand or company name'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _dec(label: 'Description', hint: 'e.g., Pain relief', helper: 'What is this medication used for?'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _dec(label: 'Notes', hint: 'e.g., Take with food', helper: 'Additional notes or instructions'),
                ),
              ]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Center(
            child: SizedBox(
              height: 40,
              child: FilledButton.icon(
                onPressed: _nameCtrl.text.trim().isNotEmpty
                    ? () async {
                        if (!_formKey.currentState!.validate()) return;
                        await showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Debug Save'),
                            content: const Text('General card rendered successfully.'),
                            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}