import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PaymentPage extends StatefulWidget {
  final Map<String, dynamic> paymentData;

  const PaymentPage({
    Key? key,
    required this.paymentData,
  }) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedPaymentMethod = 'upi';
  bool _isProcessing = false;
  final TextEditingController _upiController = TextEditingController();

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'upi',
      'name': 'UPI',
      'icon': Icons.account_balance,
      'description': 'Pay using any UPI app',
    },
    {
      'id': 'card',
      'name': 'Card',
      'icon': Icons.credit_card,
      'description': 'Credit or Debit card',
    },
    {
      'id': 'cash',
      'name': 'Cash',
      'icon': Icons.money,
      'description': 'Pay with cash after ride',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final price = widget.paymentData['price'] as String;
    final source = widget.paymentData['source'] as String;
    final destination = widget.paymentData['destination'] as String;
    final distance = widget.paymentData['distance'] as String;
    final duration = widget.paymentData['duration'] as String;
    final driver = widget.paymentData['driver'] as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ride Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('From', source),
                    _buildDetailRow('To', destination),
                    _buildDetailRow('Distance', distance),
                    _buildDetailRow('Duration', duration),
                    _buildDetailRow('Price', price),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Payment Method',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ..._paymentMethods.map((method) => _buildPaymentMethodCard(method)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isProcessing ? null : () => _processPayment(context),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_isProcessing ? 'Processing...' : 'Pay $price'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    final isSelected = _selectedPaymentMethod == method['id'];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(method['icon'] as IconData),
        title: Text(method['name'] as String),
        subtitle: Text(method['description'] as String),
        trailing: isSelected ? const Icon(Icons.check_circle) : null,
        selected: isSelected,
        onTap: () => setState(() => _selectedPaymentMethod = method['id']),
      ),
    );
  }

  void _processPayment(BuildContext context) {
    setState(() => _isProcessing = true);

    // Simulate payment processing
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isProcessing = false);
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }
}
