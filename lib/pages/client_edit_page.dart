// lib/pages/client_edit_page.dart

import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:oncredit/templates/appbar.dart';
import '../models/client.dart';
import '../services/client_service.dart';
import '../widgets/client_form.dart';

enum ClientEditResult { updated, deleted }

String formatPhone(String value) {
  final formatter = MaskTextInputFormatter(
    mask: '(##) #########',
    filter: {'#': RegExp(r'[0-9]')},
  );
  formatter.formatEditUpdate(
    const TextEditingValue(),
    TextEditingValue(text: value),
  );
  return formatter.getMaskedText();
}

class ClientEditPage extends StatefulWidget {
  final Client client;

  const ClientEditPage({super.key, required this.client});

  @override
  State<ClientEditPage> createState() => _ClientEditPageState();
}

class _ClientEditPageState extends State<ClientEditPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _cpfController;
  late List<TextEditingController> _phones;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client.name);
    _cpfController = TextEditingController(text: widget.client.formattedCpf);
    _phones = widget.client.phones
        .map((p) => TextEditingController(text: formatPhone(p)))
        .toList();
  }

  void _addPhone() => setState(() => _phones.add(TextEditingController()));

  void _removePhone(int index) => setState(() => _phones.removeAt(index));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final phones = _phones
        .map((c) => c.text.trim())
        .where((p) => p.isNotEmpty)
        .map((p) => p.replaceAll(RegExp(r'[^0-9]'), ''))
        .toList();

    // Monta contacts com tipo Celular para todos os telefones
    final contacts = phones
        .map((p) => {'type': 'Celular', 'value': p})
        .toList();

    await ClientService().updateClient(widget.client.id, {
      'name': _nameController.text.trim(),
      'contacts': contacts,
    });

    if (!mounted) return;
    Navigator.pop(context, ClientEditResult.updated);
  }

  Future<bool> _confirmDelete() async {
    final controller = TextEditingController();
    bool confirmed = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Apagar cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tem certeza que deseja apagar ${widget.client.name}?\n\n'
              'Essa ação apagará todo o histórico financeiro.\n\n'
              'Digite APAGAR para confirmar.',
            ),
            const SizedBox(height: 12),
            TextField(controller: controller),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().toUpperCase() == 'APAGAR') {
                confirmed = true;
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    return confirmed;
  }

  Future<void> _deleteClient() async {
    final ok = await _confirmDelete();
    if (!ok || !mounted) return;

    // A API faz soft delete — não precisa apagar histórico separadamente
    await ClientService().deleteClient(widget.client.id);

    if (!mounted) return;
    Navigator.pop(context, ClientEditResult.deleted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Editar Cliente',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ClientForm(
              formKey: _formKey,
              nameController: _nameController,
              cpfController: _cpfController,
              phoneControllers: _phones,
              onAddPhone: _addPhone,
              onRemovePhone: _removePhone,
              onSave: _save,
              cpfEnabled: false,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text('Apagar Cliente'),
            onPressed: _deleteClient,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}
