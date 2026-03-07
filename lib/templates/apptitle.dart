// lib/templates/apptitle.dart

import 'package:flutter/material.dart';

class AppTitle extends StatelessWidget {
  const AppTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isHome = currentRoute == '/clients';
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      splashColor: isHome ? Colors.transparent : Colors.white24,
      highlightColor: isHome ? Colors.transparent : Colors.white10,
      onTap: isHome
          ? null
          : () {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/clients', (route) => false);
            },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'ON',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
              fontSize: 25,
            ),
          ),
          SizedBox(width: 2),
          Icon(Icons.credit_score, color: Colors.white, size: 30),
          SizedBox(width: 2),
          Text('Credit', style: TextStyle(color: Colors.white, fontSize: 20)),
        ],
      ),
    );
  }
}
