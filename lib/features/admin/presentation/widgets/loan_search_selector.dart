import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';

enum LoanSearchType { loanNumber, clientId, clientName }

class LoanSearchSelector extends StatefulWidget {
  final Function(LoanSearchType type, String? value) onSearch;
  final List<Map<String, dynamic>> loans;
  final List<Map<String, dynamic>> clients;

  const LoanSearchSelector({
    super.key,
    required this.onSearch,
    required this.loans,
    required this.clients,
  });

  @override
  State<LoanSearchSelector> createState() => _LoanSearchSelectorState();
}

class _LoanSearchSelectorState extends State<LoanSearchSelector> {
  LoanSearchType _searchType = LoanSearchType.loanNumber;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buscar préstamo por:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Selector de tipo de búsqueda
            Wrap(
              spacing: 8,
              children: [
                _buildSearchTypeChip(
                  label: 'Número de Préstamo',
                  icon: Icons.receipt_long,
                  type: LoanSearchType.loanNumber,
                ),
                _buildSearchTypeChip(
                  label: 'ID Cliente',
                  icon: Icons.badge,
                  type: LoanSearchType.clientId,
                ),
                _buildSearchTypeChip(
                  label: 'Nombre Cliente',
                  icon: Icons.person_search,
                  type: LoanSearchType.clientName,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Campo de búsqueda según el tipo seleccionado
            _buildSearchField(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTypeChip({
    required String label,
    required IconData icon,
    required LoanSearchType type,
  }) {
    final isSelected = _searchType == type;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _searchType = type;
          });
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
  }

  Widget _buildSearchField() {
    switch (_searchType) {
      case LoanSearchType.loanNumber:
        return DropdownSearch<String>(
          popupProps: const PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Buscar número...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          items: widget.loans.map((loan) => loan['numero'] as String).toList(),
          dropdownDecoratorProps: const DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              labelText: 'Número de Préstamo',
              hintText: 'Seleccione un número de préstamo',
              prefixIcon: Icon(Icons.receipt_long),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          onChanged: (value) => widget.onSearch(_searchType, value),
        );

      case LoanSearchType.clientId:
        return DropdownSearch<String>(
          popupProps: const PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Buscar ID...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          items: widget.clients.map((client) => client['id'] as String).toList(),
          dropdownDecoratorProps: const DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              labelText: 'ID del Cliente',
              hintText: 'Seleccione un ID',
              prefixIcon: Icon(Icons.badge),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          onChanged: (value) => widget.onSearch(_searchType, value),
        );

      case LoanSearchType.clientName:
        return DropdownSearch<String>(
          popupProps: const PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Buscar nombre...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          items: widget.clients
              .map((client) =>
                  '${client['nombre']} ${client['apellido_paterno'] ?? ''}'.trim())
              .toList(),
          dropdownDecoratorProps: const DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              labelText: 'Nombre del Cliente',
              hintText: 'Seleccione un cliente',
              prefixIcon: Icon(Icons.person_search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          onChanged: (value) => widget.onSearch(_searchType, value),
        );
    }
  }
}

// Widget para mostrar resultado de búsqueda con deuda total
class LoanSearchResultCard extends StatelessWidget {
  final String clientName;
  final double totalDebt;
  final int activeLoansCount;
  final VoidCallback? onTap;

  const LoanSearchResultCard({
    super.key,
    required this.clientName,
    required this.totalDebt,
    required this.activeLoansCount,
    this.onTap,
  });

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clientName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$activeLoansCount préstamo(s) activo(s)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: totalDebt > 0
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: totalDebt > 0
                        ? Colors.red.withOpacity(0.3)
                        : Colors.green.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deuda Total Actual',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(totalDebt),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: totalDebt > 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      totalDebt > 0 ? Icons.trending_up : Icons.check_circle,
                      color: totalDebt > 0 ? Colors.red : Colors.green,
                      size: 40,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
