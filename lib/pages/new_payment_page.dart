// lib/pages/new_payment_page.dart

import 'package:flutter/material.dart';
import 'package:oncredit/templates/appbar.dart';
import '../services/client_service.dart';
import '../theme/theme_extensions.dart';
import '../tools/formatters.dart';

class NewPaymentPage extends StatefulWidget {
  final int clientId; // ← era String

  const NewPaymentPage({super.key, required this.clientId});

  @override
  State<NewPaymentPage> createState() => _NewPaymentPageState();
}

class _NewPaymentPageState extends State<NewPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _valueFocus = FocusNode();
  String _method = 'Dinheiro';
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_valueFocus);
    });
  }

  @override
  void dispose() {
    _valueController.dispose();
    _valueFocus.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (result != null) setState(() => _date = result);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    await ClientService().createPayment(widget.clientId, {
      'value': Formatters.parseCurrency(_valueController.text),
      'method': _method,
      'date': _date.toIso8601String().substring(0, 19),
    });

    if (!mounted) return;
    Navigator.pop(context, true);
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
              'Registrar pagamento',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _valueController,
                    focusNode: _valueFocus,
                    keyboardType: TextInputType.number,
                    inputFormatters: [Formatters.currencyInput],
                    decoration: const InputDecoration(
                      labelText: 'Valor do pagamento',
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Informe o valor' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _method,
                    decoration: const InputDecoration(
                      labelText: 'Forma de pagamento',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Dinheiro',
                        child: Text('Dinheiro'),
                      ),
                      DropdownMenuItem(value: 'PIX', child: Text('PIX')),
                      DropdownMenuItem(value: 'Débito', child: Text('Débito')),
                      DropdownMenuItem(
                        value: 'Crédito',
                        child: Text('Crédito'),
                      ),
                      DropdownMenuItem(
                        value: 'Transferência',
                        child: Text('Transferência'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _method = v!),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(Formatters.dateFormat.format(_date)),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text(
                        'Salvar pagamento',
                        style: TextStyle(fontSize: 18),
                      ),
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.onPrimary,
                        foregroundColor: context.colors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
