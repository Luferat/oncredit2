import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/client_list_response.dart';
import '../services/client_service.dart';
import '../templates/appbar.dart';
import '../config/app_config.dart';
import '../theme/theme_extensions.dart';
import '../tools/formatters.dart';
import 'client_edit_page.dart';
import 'client_page.dart';
import 'new_client_page.dart';

class ClientListPage extends StatefulWidget {
  const ClientListPage({super.key});

  @override
  State<ClientListPage> createState() => _ClientListPageState();
}

class _ClientListPageState extends State<ClientListPage> {
  final ClientService _clientService = ClientService();
  final TextEditingController _searchController = TextEditingController();

  late Future<ClientListResponse> _listFuture;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _listFuture = _clientService.getClientList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _listFuture = _clientService.getClientList();
    });
  }

  List<Client> _filterClients(List<Client> all) {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return all;
    final numeric = query.replaceAll(RegExp(r'\D'), '');
    return all.where((c) {
      final nameMatch = c.name.toLowerCase().contains(query);
      final cpfMatch = numeric.isNotEmpty && c.cpf.contains(numeric);
      return nameMatch || cpfMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(),
      body: Column(
        children: [
          // UID ativo
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Text(
                'UID ativo: ${AppConfig.androidId}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),

          // Card de saldo + lista: único FutureBuilder
          Expanded(
            child: FutureBuilder<ClientListResponse>(
              future: _listFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro ao carregar: ${snapshot.error}'),
                  );
                }

                final balance = snapshot.data!.balance;
                final clients = _filterClients(snapshot.data!.clients);

                return Column(
                  children: [
                    // Saldo
                    Card(
                      margin: const EdgeInsets.all(16),
                      color: context.colors.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Saldo total a receber',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.currencyFormat.format(balance),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: context.colors.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    _buildSearchField(),
                    const SizedBox(height: 8),

                    // Lista de clientes
                    Expanded(
                      child: clients.isEmpty
                          ? const Center(
                              child: Text('Nenhum cliente encontrado'),
                            )
                          : ListView.builder(
                              itemCount: clients.length,
                              itemBuilder: (context, index) {
                                final client = clients[index];
                                return ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.person),
                                  ),
                                  contentPadding:
                                      const EdgeInsets.only(left: 40),
                                  title: Text(client.name),
                                  subtitle:
                                      Text('CPF: ${client.formattedCpf}'),
                                  onTap: () async {
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    final result =
                                        await Navigator.push<ClientEditResult>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ClientPage(client: client),
                                      ),
                                    );
                                    if (result == ClientEditResult.deleted) {
                                      _reload();
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Cliente apagado com sucesso',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Botão Novo cliente
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person_add, size: 22),
                  label: const Text(
                    'Novo cliente',
                    style: TextStyle(fontSize: 18),
                  ),
                  onPressed: () async {
                    final created = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NewClientPage(),
                      ),
                    );
                    if (created == true) _reload();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.onPrimary,
                    foregroundColor: context.colors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: 'Pesquisar cliente...',
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                )
              : null,
        ),
        onChanged: (value) => setState(() => _search = value),
      ),
    );
  }
}