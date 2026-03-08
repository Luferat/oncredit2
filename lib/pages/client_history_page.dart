// lib/pages/client_history_page.dart

import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/financial_event.dart';
import '../services/client_service.dart';
import '../templates/appbar.dart';
import '../theme/theme_extensions.dart';
import '../tools/formatters.dart';
import '../widgets/edit_event_sheet.dart';

class ClientHistoryPage extends StatefulWidget {
  final Client client;
  final VoidCallback? onChanged;

  const ClientHistoryPage({super.key, required this.client, this.onChanged});

  @override
  State<ClientHistoryPage> createState() => _ClientHistoryPageState();
}

class _ClientHistoryPageState extends State<ClientHistoryPage> {
  late Future<(List<FinancialEvent>, Client)> _dataFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _dataFuture =
          Future.wait([
            ClientService().getClientHistory(widget.client.id),
            ClientService().getClient(widget.client.id),
          ]).then(
            (results) =>
                (results[0] as List<FinancialEvent>, results[1] as Client),
          );
    });
  }

  Future<void> _onTapEvent(FinancialEvent item) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditEventSheet(event: item, clientId: widget.client.id),
    );
    if (changed == true) {
      _reload();
      widget.onChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Histórico de Relacionamento',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                widget.client.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text('CPF: ${widget.client.formattedCpf}'),
              const SizedBox(height: 16),
              const Divider(),
              Expanded(
                child: FutureBuilder<(List<FinancialEvent>, Client)>(
                  future: _dataFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final (history, client) = snapshot.data!;

                    if (history.isEmpty) {
                      return Column(
                        children: [
                          const Expanded(
                            child: Center(
                              child: Text('Nenhum registro encontrado'),
                            ),
                          ),
                          _summaryCard(context, client),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            itemCount: history.length,
                            separatorBuilder: (_, _) => const Divider(),
                            itemBuilder: (context, index) {
                              final item = history[index];
                              final isPurchase =
                                  item.type == FinancialEventType.purchase;

                              return ListTile(
                                leading: Icon(
                                  isPurchase
                                      ? Icons.shopping_cart
                                      : Icons.payments,
                                  color: isPurchase ? Colors.red : Colors.green,
                                ),
                                title: Text(item.description),
                                subtitle: Text(
                                  isPurchase
                                      ? Formatters.formatDate(item.date)
                                      : '${Formatters.formatDate(item.date)} · ${item.method}',
                                ),
                                trailing: Text(
                                  '${isPurchase ? '- ' : '+ '}${Formatters.currencyFormat.format(item.value)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isPurchase
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                                onTap: () => _onTapEvent(item),
                              );
                            },
                          ),
                        ),
                        _summaryCard(context, client),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(BuildContext context, Client client) {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      color: context.colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo do período',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            _summaryLine('Total em compras', client.totalPurchases ?? 0),
            _summaryLine('Total pago', client.totalPayments ?? 0),
            const Divider(color: Colors.grey),
            _summaryLine('Débito atual', client.balance ?? 0, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _summaryLine(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            Formatters.currencyFormat.format(value),
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
} // fim de _ClientHistoryPageState
