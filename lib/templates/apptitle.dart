// lib/templates/apptitle.dart

import 'package:flutter/material.dart';

class AppTitle extends StatelessWidget {
  final bool large;

  const AppTitle({super.key, this.large = false});

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isHome = currentRoute == '/clients';

    final double onSize = large ? 42 : 25;
    final double iconSize = large ? 52 : 30;
    final double creditSize = large ? 36 : 20;

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
        children: [
          Text(
            'ON',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
              fontSize: onSize,
            ),
          ),
          const SizedBox(width: 2),
          Icon(Icons.credit_score, color: Colors.white, size: iconSize),
          const SizedBox(width: 2),
          Text(
            'Credit',
            style: TextStyle(color: Colors.white, fontSize: creditSize),
          ),
        ],
      ),
    );
  }
}