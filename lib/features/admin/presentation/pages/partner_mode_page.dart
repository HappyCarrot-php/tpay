import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PartnerModePage extends StatefulWidget {
  const PartnerModePage({super.key});

  @override
  State<PartnerModePage> createState() => _PartnerModePageState();
}

class _PartnerModePageState extends State<PartnerModePage> {
  final TextEditingController _netProfitController = TextEditingController();
  final TextEditingController _partnerPercentController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  double? _netProfit;
  double? _partnerPercent;

  @override
  void initState() {
    super.initState();
    _netProfitController.addListener(_recalculateShare);
    _partnerPercentController.addListener(_recalculateShare);
  }

  @override
  void dispose() {
    _netProfitController
      ..removeListener(_recalculateShare)
      ..dispose();
    _partnerPercentController
      ..removeListener(_recalculateShare)
      ..dispose();
    super.dispose();
  }

  void _recalculateShare() {
    final netProfit = _parseInput(_netProfitController.text);
    final partnerPercent = _parseInput(_partnerPercentController.text);

    setState(() {
      _netProfit = netProfit;
      _partnerPercent = partnerPercent;
    });
  }

  double? _parseInput(String raw) {
    final normalized = raw.replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  void _clearFields() {
    _netProfitController.clear();
    _partnerPercentController.clear();
  }

  double _calculateShare() {
    if (_netProfit == null || _partnerPercent == null) {
      return 0;
    }
    return _netProfit!.clamp(0, double.infinity) * (_partnerPercent!.clamp(0, 100) / 100);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final partnerShare = _calculateShare();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Socio'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Calcula cuánto corresponde a tu socio a partir de la utilidad neta.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _netProfitController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Utilidad neta',
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixText: _netProfit != null ? _currencyFormat.format(_netProfit!) : null,
                  helperText: 'Monto final después de gastos e impuestos',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _partnerPercentController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Porcentaje del socio',
                  prefixIcon: Icon(Icons.percent),
                  helperText: 'Ingresa el porcentaje acordado (el monto se autocalcula)',
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in const [10, 20, 25, 30, 40, 50])
                    ActionChip(
                      label: Text('$preset%'),
                      onPressed: () {
                        _partnerPercentController.text = preset.toString();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 28),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resultado',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.handshake,
                              color: colorScheme.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currencyFormat.format(partnerShare),
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Equivale al ${(_partnerPercent ?? 0).clamp(0, 100).toStringAsFixed(2)}% de la utilidad neta.',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: theme.dividerColor),
                      const SizedBox(height: 16),
                      _buildSummaryRow(
                        context,
                        label: 'Utilidad neta ingresada',
                        value: _netProfit == null
                            ? '--'
                            : _currencyFormat.format(_netProfit!.clamp(0, double.infinity)),
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        context,
                        label: 'Porcentaje del socio',
                        value: '${(_partnerPercent ?? 0).clamp(0, 100).toStringAsFixed(2)}%',
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        context,
                        label: 'Utilidad restante',
                        value: _netProfit == null
                            ? '--'
                            : _currencyFormat.format(
                                (_netProfit!.clamp(0, double.infinity) - partnerShare).clamp(0, double.infinity),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _clearFields,
                icon: const Icon(Icons.refresh),
                label: const Text('Limpiar campos'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, {required String label, required String value}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
