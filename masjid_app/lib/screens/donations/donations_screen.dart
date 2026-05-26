import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class DonationsScreen extends StatefulWidget {
  const DonationsScreen({super.key});

  @override
  State<DonationsScreen> createState() => _DonationsScreenState();
}

class _DonationsScreenState extends State<DonationsScreen> {
  int? _selectedAmount;
  int _customAmount = 0;
  int _selectedMethod = 0;
  final _customController = TextEditingController();

  final List<int> _amounts = [10, 25, 50, 100, 250, 500];
  final List<String> _methods = ['Cash at Masjid', 'Bank Transfer', 'Online'];
  final List<IconData> _methodIcons = [
    Icons.payments_rounded,
    Icons.account_balance_rounded,
    Icons.credit_card_rounded,
  ];

  int get _finalAmount => _selectedAmount ?? _customAmount;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donations')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildAmountSection(),
            const SizedBox(height: 24),
            _buildMethodSection(),
            const SizedBox(height: 32),
            _buildDonateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D3B1F), Color(0xFF0A2040)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.volunteer_activism_rounded,
              color: AppTheme.gold, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Support Your Masjid',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '"The best charity is that given in Ramadan."\n— Prophet Muhammad ﷺ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Amount (USD)',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _amounts.asMap().entries.map((e) {
            final selected = _selectedAmount == e.value;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedAmount = e.value;
                _customController.clear();
                _customAmount = 0;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: (MediaQuery.of(context).size.width - 60) / 3,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [AppTheme.primaryGreen, Color(0xFF2E7D32)])
                      : null,
                  color: selected ? null : AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? AppTheme.gold.withOpacity(0.5)
                        : Colors.white12,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '\$${e.value}',
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _customController,
          keyboardType: TextInputType.number,
          onChanged: (v) => setState(() {
            _customAmount = int.tryParse(v) ?? 0;
            if (_customAmount > 0) _selectedAmount = null;
          }),
          decoration: const InputDecoration(
            hintText: 'Custom amount...',
            prefixText: '\$ ',
            prefixStyle: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold),
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Method',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...List.generate(_methods.length, (i) {
          final selected = _selectedMethod == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedMethod = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primaryGreen.withOpacity(0.15)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppTheme.gold.withOpacity(0.4) : Colors.white12,
                ),
              ),
              child: Row(
                children: [
                  Icon(_methodIcons[i],
                      color: selected ? AppTheme.gold : Colors.white38, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    _methods[i],
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  if (selected)
                    const Icon(Icons.check_circle_rounded,
                        color: AppTheme.gold, size: 18),
                ],
              ),
            ),
          );
        }),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildDonateButton() {
    final canDonate = _finalAmount > 0;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canDonate ? _onDonate : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          disabledBackgroundColor: AppTheme.surface,
        ),
        child: Text(
          canDonate ? 'Donate \$$_finalAmount' : 'Select an amount',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms)
        .scale(begin: const Offset(0.95, 0.95), duration: 300.ms);
  }

  void _onDonate() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('JazakAllahu Khayran!',
            style: TextStyle(color: AppTheme.gold), textAlign: TextAlign.center),
        content: Text(
          'Your donation of \$$_finalAmount via ${_methods[_selectedMethod]} has been registered.\n\nMay Allah accept it from you.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, height: 1.6),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ameen'),
          ),
        ],
      ),
    );
  }
}
