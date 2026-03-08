// lib/pages/client_list.dart

import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/client_list_response.dart';
import '../services/client_service.dart';
import '../templates/appbar.dart';
import '../config/app_config.dart';
import '../theme/theme_extensions.dart';
import '../tools/formatters.dart';
import '../tools/api_error.dart';
import 'client_edit_page.dart';
import 'client_page.dart';
import 'new_client_page.dart';

class ClientListPage extends StatefulWidget {
  const ClientListPage({super.key});

  @override
  State<ClientListPage> createState() => _ClientListPageState();
}

class _ClientListPageState extends State<ClientListPage> {
  void _goToStartup() {
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

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

  Future<void> _goToNewClient() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewClientPage()),
    );
    if (created == true) _reload();
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

          Expanded(
            child: FutureBuilder<ClientListResponse>(
              future: _listFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  final message = apiErrorMessage(snapshot.error!);
                  if (message.contains('conectar') ||
                      message.contains('timeout') ||
                      message.contains('servidor')) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _goToStartup();
                    });

                    return const Center(child: CircularProgressIndicator());
                  }

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            apiErrorMessage(snapshot.error!),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar novamente'),
                            onPressed: _reload,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final balance = snapshot.data!.balance;
                final allClients = snapshot.data!.clients;
                final clients = _filterClients(allClients);

                return Column(
                  children: [
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

                    Expanded(
                      child: clients.isEmpty
                          ? _buildEmptyState(context, allClients.isEmpty)
                          : ListView.builder(
                              itemCount: clients.length,
                              itemBuilder: (context, index) {
                                final client = clients[index];
                                return ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.person),
                                  ),
                                  contentPadding: const EdgeInsets.only(
                                    left: 40,
                                  ),
                                  title: Text(client.name),
                                  subtitle: Text('CPF: ${client.formattedCpf}'),
                                  onTap: () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
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
                  onPressed: _goToNewClient,
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

  Widget _buildEmptyState(BuildContext context, bool noClientsAtAll) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              noClientsAtAll ? Icons.people_outline : Icons.search_off,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              noClientsAtAll
                  ? 'Nenhum cliente cadastrado ainda'
                  : 'Nenhum cliente encontrado para "$_search"',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            if (noClientsAtAll) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Cadastrar primeiro cliente'),
                onPressed: _goToNewClient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
