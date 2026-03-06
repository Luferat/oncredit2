// lib/widgets/edit_event_sheet.dart

import 'package:flutter/material.dart';
import '../models/financial_event.dart';
import '../services/client_service.dart';
import '../tools/formatters.dart';

class EditEventSheet extends StatefulWidget {
  final FinancialEvent event;
  final int clientId;

  const EditEventSheet({
    super.key,
    required this.event,
    required this.clientId,
  });

  @override
  State<EditEventSheet> createState() => _EditEventSheetState();
}

class _EditEventSheetState extends State<EditEventSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // Campos de compra
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _unitValueController;

  // Campos de pagamento
  late TextEditingController _valueController;
  late String _method;

  late DateTime _date;

  bool get _isPurchase => widget.event.type == FinancialEventType.purchase;

  @override
  void initState() {
    super.initState();
    _date = widget.event.date;

    if (_isPurchase) {
      // Desmonta "2 x Calça jeans" → quantity=2, description="Calça jeans"
      final match = RegExp(
        r'^(\d+) x (.+)$',
      ).firstMatch(widget.event.description);
      final quantity = match?.group(1) ?? '1';
      final description = match?.group(2) ?? widget.event.description;
      final unitValue = match != null
          ? widget.event.value / (int.tryParse(quantity) ?? 1)
          : widget.event.value;

      _descriptionController = TextEditingController(text: description);
      _quantityController = TextEditingController(text: quantity);
      _unitValueController = TextEditingController(
        text: Formatters.currencyFormat.format(unitValue),
      );
      _valueController = TextEditingController();
      _method = 'Dinheiro';
    } else {
      _descriptionController = TextEditingController();
      _quantityController = TextEditingController();
      _unitValueController = TextEditingController();
      _valueController = TextEditingController(
        text: Formatters.currencyFormat.format(widget.event.value),
      );
      _method = widget.event.method ?? 'Dinheiro';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitValueController.dispose();
    _valueController.dispose();
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

    final service = ClientService();

    if (_isPurchase) {
      final quantity = int.parse(_quantityController.text);
      final unitValue = Formatters.parseCurrency(_unitValueController.text);
      await service.updatePurchase(widget.clientId, widget.event.id, {
        'description': _descriptionController.text.trim(),
        'quantity': quantity,
        'unit_value': unitValue,
        'date': _date.toIso8601String().substring(0, 19),
      });
    } else {
      await service.updatePayment(widget.clientId, widget.event.id, {
        'value': Formatters.parseCurrency(_valueController.text),
        'method': _method,
        'date': _date.toIso8601String().substring(0, 19),
      });
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apagar registro'),
        content: Text(
          'Deseja apagar "${widget.event.description}"?\n\nEssa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);

    final service = ClientService();
    if (_isPurchase) {
      await service.deletePurchase(widget.clientId, widget.event.id);
    } else {
      await service.deletePayment(widget.clientId, widget.event.id);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final title = _isPurchase ? 'Editar compra' : 'Editar pagamento';
    final color = _isPurchase ? Colors.red : Colors.green;

    return Padding(
      // Sobe o sheet quando o teclado aparece
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Alça
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              Row(
                children: [
                  Icon(
                    _isPurchase ? Icons.shopping_cart : Icons.payments,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _saving ? null : _delete,
                    tooltip: 'Apagar',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (_isPurchase) ..._buildPurchaseFields(),
              if (!_isPurchase) ..._buildPaymentFields(),

              // Data (comum aos dois)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(Formatters.dateFormat.format(_date)),
                onTap: _saving ? null : _pickDate,
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar', style: TextStyle(fontSize: 18)),
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPurchaseFields() {
    return [
      TextFormField(
        controller: _descriptionController,
        decoration: const InputDecoration(labelText: 'Descrição'),
        validator: (v) => v == null || v.isEmpty ? 'Informe a descrição' : null,
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantidade'),
              validator: (v) {
                final q = int.tryParse(v ?? '');
                return q == null || q <= 0 ? 'Inválido' : null;
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _unitValueController,
              keyboardType: TextInputType.number,
              inputFormatters: [Formatters.currencyInput],
              decoration: const InputDecoration(labelText: 'Valor unitário'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Informe o valor' : null,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildPaymentFields() {
    return [
      TextFormField(
        controller: _valueController,
        keyboardType: TextInputType.number,
        inputFormatters: [Formatters.currencyInput],
        decoration: const InputDecoration(labelText: 'Valor'),
        validator: (v) => v == null || v.isEmpty ? 'Informe o valor' : null,
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: _method,
        decoration: const InputDecoration(labelText: 'Forma de pagamento'),
        items: const [
          DropdownMenuItem(value: 'Dinheiro', child: Text('Dinheiro')),
          DropdownMenuItem(value: 'PIX', child: Text('PIX')),
          DropdownMenuItem(value: 'Débito', child: Text('Débito')),
          DropdownMenuItem(value: 'Crédito', child: Text('Crédito')),
          DropdownMenuItem(
            value: 'Transferência',
            child: Text('Transferência'),
          ),
        ],
        onChanged: (v) => setState(() => _method = v!),
      ),
      const SizedBox(height: 12),
    ];
  }
}
