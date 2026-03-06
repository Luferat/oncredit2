// lib/pages/client_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/client.dart';
import '../services/client_service.dart';
import '../templates/appbar.dart';
import '../theme/theme_extensions.dart';
import '../tools/formatters.dart';
import 'client_edit_page.dart';
import 'client_history_page.dart';
import 'new_payment_page.dart';
import 'new_purchase_page.dart';

String onlyNumbers(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

class ClientPage extends StatefulWidget {
  final Client client;

  const ClientPage({super.key, required this.client});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  late Future<Client> _clientFuture;

  @override
  void initState() {
    super.initState();
    _clientFuture = ClientService().getClient(widget.client.id);
  }

  void _reload() {
    setState(() {
      _clientFuture = ClientService().getClient(widget.client.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(),
      body: FutureBuilder<Client>(
        future: _clientFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final client = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('CPF: ${client.formattedCpf}'),
                const SizedBox(height: 16),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.shopping_cart),
                  title: const Text('Registrar compra'),
                  onTap: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewPurchasePage(clientId: client.id),
                      ),
                    );
                    if (result == true) _reload();
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.payments),
                  title: const Text('Registrar pagamento'),
                  onTap: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewPaymentPage(clientId: client.id),
                      ),
                    );
                    if (result == true) _reload();
                  },
                ),

                const SizedBox(height: 16),
                const Divider(),

                // Resumo financeiro — dados já vêm no GET /clients/<id>
                Card(
                  margin: const EdgeInsets.only(top: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resumo financeiro',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _line('Total em compras', client.totalPurchases ?? 0),
                        _line('Total pago', client.totalPayments ?? 0),
                        const Divider(),
                        _line('Débito atual', client.balance ?? 0, bold: true),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.history, size: 22),
                    label: const Text(
                      'Ver histórico completo',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.onPrimary,
                      foregroundColor: context.colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClientHistoryPage(client: client),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<Client>(
        future: _clientFuture,
        builder: (context, snapshot) {
          final client = snapshot.data ?? widget.client;
          return SafeArea(child: _buildBottomActions(context, client));
        },
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, Client client) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.call),
              label: const Text('Contatos'),
              onPressed: client.phones.isEmpty
                  ? null
                  : () => _showContactsBottomSheet(client),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.onPrimary,
                foregroundColor: context.colors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Editar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Editar cliente'),
                    content: const Text(
                      'As alterações feitas não poderão ser desfeitas.\n\nDeseja continuar?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Continuar'),
                      ),
                    ],
                  ),
                );

                if (confirmed != true) return;

                final result = await navigator.push<ClientEditResult>(
                  MaterialPageRoute(
                    builder: (_) => ClientEditPage(client: client),
                  ),
                );

                if (!mounted || result == null) return;

                if (result == ClientEditResult.updated) {
                  _reload();
                  messenger.showSnackBar(const SnackBar(
                    content: Text('Cliente atualizado com sucesso'),
                  ));
                } else if (result == ClientEditResult.deleted) {
                  navigator.pop(ClientEditResult.deleted);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showContactsBottomSheet(Client client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Text(
                  'Contatos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...client.phones.map((phone) => ListTile(
                      leading: const Icon(Icons.phone_android),
                      title: Text(Formatters.formatPhone(phone)),
                      subtitle: const Text('Toque no menu para ações'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) => _handlePhoneAction(v, phone),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'copy', child: Text('Copiar número')),
                          PopupMenuItem(value: 'call', child: Text('Ligar')),
                          PopupMenuItem(
                              value: 'whatsapp', child: Text('WhatsApp')),
                        ],
                      ),
                    )),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePhoneAction(String action, String phone) async {
    final number = onlyNumbers(phone);
    try {
      switch (action) {
        case 'copy':
          await Clipboard.setData(ClipboardData(text: number));
          break;
        case 'call':
          await launchUrl(Uri(scheme: 'tel', path: number),
              mode: LaunchMode.externalApplication);
          break;
        case 'whatsapp':
          await launchUrl(Uri.parse('https://wa.me/55$number'),
              mode: LaunchMode.externalApplication);
          break;
      }
    } catch (e) {
      debugPrint('Launch error: $e');
    }
  }

  Widget _line(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            Formatters.currencyFormat.format(value),
            style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }
}