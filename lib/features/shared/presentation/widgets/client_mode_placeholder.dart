import 'package:flutter/material.dart';

class ClientModePlaceholder extends StatelessWidget {
  const ClientModePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).colorScheme.surface;
    return Scaffold(
      backgroundColor: background,
      body: const SizedBox.expand(),
    );
  }
}
