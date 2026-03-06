// lib/widgets/client_form.dart

import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class ClientForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController cpfController;
  final List<TextEditingController> phoneControllers;
  final VoidCallback onAddPhone;
  final void Function(int index) onRemovePhone;
  final VoidCallback onSave;
  final bool cpfEnabled;

  const ClientForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.cpfController,
    required this.phoneControllers,
    required this.onAddPhone,
    required this.onRemovePhone,
    required this.onSave,
    this.cpfEnabled = true,
  });

  @override
  State<ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends State<ClientForm> {
  final _nameFocus = FocusNode();
  final List<FocusNode> _phoneFocusNodes = [];

  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #########',
    filter: {'#': RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();

    for (var i = 0; i < widget.phoneControllers.length; i++) {
      _phoneFocusNodes.add(FocusNode());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    for (final node in _phoneFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ClientForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.phoneControllers.length > _phoneFocusNodes.length) {
      final newNode = FocusNode();
      _phoneFocusNodes.add(newNode);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        newNode.requestFocus();
      });
    }

    while (_phoneFocusNodes.length > widget.phoneControllers.length) {
      _phoneFocusNodes.removeLast().dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: widget.nameController,
            focusNode: _nameFocus,
            decoration: const InputDecoration(labelText: 'Nome'),
            validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: widget.cpfController,
            enabled: widget.cpfEnabled,
            decoration: InputDecoration(
              labelText: 'CPF',
              helperText: widget.cpfEnabled
                  ? null
                  : 'CPF não pode ser alterado',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [_cpfMask],
            validator: (v) {
              if (!widget.cpfEnabled) return null;
              return v == null || v.isEmpty ? 'Informe o CPF' : null;
            },
          ),

          const SizedBox(height: 16),

          const Text(
            'Telefones',
            style: TextStyle(fontSize: 18, color: Colors.black54),
          ),
          const SizedBox(height: 8),

          ..._buildPhones(),

          TextButton.icon(
            onPressed: widget.onAddPhone,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar telefone'),
          ),

          const SizedBox(height: 18),

          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            onPressed: widget.onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
            label: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPhones() {
    return List.generate(widget.phoneControllers.length, (index) {
      final isLast = index == widget.phoneControllers.length - 1;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.phoneControllers[index],
                autofocus: isLast,
                focusNode: _phoneFocusNodes[index],
                decoration: const InputDecoration(
                  labelText: 'Telefone com DDD',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [_phoneMask],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => widget.onRemovePhone(index),
            ),
          ],
        ),
      );
    });
  }
}
