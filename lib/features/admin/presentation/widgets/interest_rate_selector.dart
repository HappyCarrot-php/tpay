import 'package:flutter/material.dart';

class InterestRateSelector extends StatelessWidget {
  final String selectedRate;
  final Function(String) onRateChanged;
  final TextEditingController? manualController;
  final bool showManualField;

  const InterestRateSelector({
    super.key,
    required this.selectedRate,
    required this.onRateChanged,
    this.manualController,
    this.showManualField = true,
  });

  static const List<InterestOption> interestOptions = [
    InterestOption(label: '3% Mensual', value: '3'),
    InterestOption(label: '5% Mensual', value: '5'),
    InterestOption(label: '10% Mensual', value: '10'),
    InterestOption(label: 'Manual', value: 'manual'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tasa de Interés',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: interestOptions.map((option) {
            final isSelected = selectedRate == option.value;
            return ChoiceChip(
              label: Text(option.label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onRateChanged(option.value);
                }
              },
              selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              backgroundColor: Colors.grey[100],
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            );
          }).toList(),
        ),
        if (showManualField && selectedRate == 'manual' && manualController != null) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: manualController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Interés Personalizado',
              hintText: 'Ingrese el porcentaje',
              prefixIcon: const Icon(Icons.percent),
              suffixText: '%',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (selectedRate == 'manual') {
                if (value == null || value.isEmpty) {
                  return 'Ingrese el porcentaje de interés';
                }
                final interes = double.tryParse(value);
                if (interes == null || interes < 0) {
                  return 'Ingrese un porcentaje válido';
                }
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}

class InterestOption {
  final String label;
  final String value;

  const InterestOption({
    required this.label,
    required this.value,
  });
}
