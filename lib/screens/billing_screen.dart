import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/menu_item.dart';
import '../models/order_line.dart';
import '../models/order.dart';
import '../services/storage_service.dart';
import '../services/printer_service.dart';
import 'settings_screen.dart';
import 'package:intl/intl.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final StorageService _storage = StorageService();
  final PrinterService _printer = PrinterService();

  List<MenuItem> _menuItems = [];
  List<String> _categories = [];
  String _selectedCategory = '';
  List<OrderLine> _orderLines = [];

  double _subtotal = 0.0;
  double _taxPercent = 5.0;
  double _taxAmount = 0.0;
  double _discount = 0.0;
  double _grandTotal = 0.0;

  bool _isPrinterConnected = false;
  String? _printerName;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final items = await _storage.getMenuItems();
    final categories = await _storage.getCategories();
    final config = _storage.getAppConfig();
    final savedOrder = _storage.getCurrentOrder();

    setState(() {
      _menuItems = items;
      _categories = categories;
      _selectedCategory = categories.isNotEmpty ? categories.first : '';
      _taxPercent = config.taxPercent;
      _isLoading = false;
      if (savedOrder != null) {
        _orderLines = savedOrder;
      }
    });

    _calculateTotals();
    _checkPrinterStatus();
  }

  Future<void> _checkPrinterStatus() async {
    final isConnected = await _printer.isConnected();
    final device = _printer.getConnectedDevice();
    setState(() {
      _isPrinterConnected = isConnected;
      _printerName = device?['name'];
    });
  }

  void _calculateTotals() {
    _subtotal = _orderLines.fold(0.0, (sum, line) => sum + line.total);
    _taxAmount = _subtotal * (_taxPercent / 100);
    _grandTotal = _subtotal + _taxAmount - _discount;
    if (_grandTotal < 0) _grandTotal = 0;

    // Auto-save order
    _storage.saveCurrentOrder(_orderLines);

    setState(() {});
  }

  void _addItemToOrder(MenuItem item) {
    setState(() {
      final existingIndex = _orderLines.indexWhere(
        (line) => line.itemId == item.id,
      );

      if (existingIndex >= 0) {
        final existing = _orderLines[existingIndex];
        final newQuantity = existing.quantity + 1;
        _orderLines[existingIndex] = OrderLine(
          itemId: existing.itemId,
          name: existing.name,
          price: existing.price,
          quantity: newQuantity,
          total: existing.price * newQuantity,
        );
      } else {
        _orderLines.add(
          OrderLine(
            itemId: item.id,
            name: item.name,
            price: item.price,
            quantity: 1,
            total: item.price,
          ),
        );
      }
    });
    _calculateTotals();
  }

  void _incrementQuantity(int index) {
    setState(() {
      final line = _orderLines[index];
      final newQuantity = line.quantity + 1;
      _orderLines[index] = line.copyWith(
        quantity: newQuantity,
        total: line.price * newQuantity,
      );
    });
    _calculateTotals();
  }

  void _decrementQuantity(int index) {
    setState(() {
      final line = _orderLines[index];
      if (line.quantity > 1) {
        final newQuantity = line.quantity - 1;
        _orderLines[index] = line.copyWith(
          quantity: newQuantity,
          total: line.price * newQuantity,
        );
      } else {
        _orderLines.removeAt(index);
      }
    });
    _calculateTotals();
  }

  void _showClearConfirmation() {
    if (_orderLines.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Order?'),
        content: const Text(
          'Are you sure you want to clear all items from the current order?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearOrder();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _clearOrder() {
    setState(() {
      _orderLines.clear();
      _discount = 0.0;
    });
    _calculateTotals();
  }

  void _showDiscountDialog() {
    final controller = TextEditingController(
      text: _discount.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Discount'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Discount Amount (₹)',
            prefixText: '₹',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _discount = 0.0);
              _calculateTotals();
              Navigator.of(context).pop();
            },
            child: const Text('Remove'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text) ?? 0.0;
              setState(() => _discount = value);
              _calculateTotals();
              Navigator.of(context).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _printReceipt() async {
    if (_orderLines.isEmpty) {
      _showError('No items in order');
      return;
    }

    final order = Order(
      id: 'ORD-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}',
      items: List.from(_orderLines),
      subtotal: _subtotal,
      taxPercent: _taxPercent,
      taxAmount: _taxAmount,
      discount: _discount,
      total: _grandTotal,
      createdAt: DateTime.now(),
    );

    // Show print preview dialog
    _showPrintPreview(order);
  }

  void _showPrintPreview(Order order) {
    final config = _storage.getAppConfig();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Bill Receipt',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade400, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Restaurant Name Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400, width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    config.restaurantName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(thickness: 1, color: Colors.black),
                const SizedBox(height: 8),
                // Order Info
                Row(
                  children: [
                    const Text(
                      'Order: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(order.id, style: const TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Date:  ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(thickness: 1, color: Colors.black),
                const SizedBox(height: 12),
                // Items Header
                Row(
                  children: const [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Item',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Qty',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Price',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(thickness: 1, color: Colors.black),
                const SizedBox(height: 8),
                // Items List
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            item.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '₹${item.price.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 14),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '₹${item.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 14),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 8),
                const Divider(thickness: 1, color: Colors.black),
                const SizedBox(height: 12),
                // Tax
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tax (${order.taxPercent}%):',
                      style: const TextStyle(fontSize: 15),
                    ),
                    Text(
                      '₹${order.taxAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
                if (order.discount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Discount:', style: TextStyle(fontSize: 15)),
                      Text(
                        '-₹${order.discount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(thickness: 1, color: Colors.black),
                const SizedBox(height: 12),
                // Grand Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'GRAND TOTAL:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      '₹${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(thickness: 1, color: Colors.black),
                const SizedBox(height: 16),
                // Footer
                Text(
                  config.footerMessage,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Phone Number Input
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Customer Phone Number',
                    hintText: 'Enter phone number',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final phoneNumber = phoneController.text.trim();
              if (phoneNumber.isNotEmpty) {
                _sendBillViaSMS(order, phoneNumber);
              } else {
                _showError('Please enter phone number');
              }
            },
            icon: const Icon(Icons.sms),
            label: const Text('Send SMS', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();

              // First try to print the receipt
              bool printSuccess = false;
              try {
                if (_isPrinterConnected) {
                  await _printer.printReceipt(order);
                  printSuccess = true;
                }
              } catch (e) {
                debugPrint('Print failed: $e');
              }

              // Save the order
              await _storage.saveCompletedOrder(order);
              await _storage.clearCurrentOrder();

              // Show appropriate message
              if (printSuccess) {
                _showSuccess('Print bill successful');
              } else {
                _showSuccess('Bill saved successfully');
              }

              _clearOrder();
            },
            icon: const Icon(Icons.check),
            label: const Text('Complete Order', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _sendBillViaSMS(Order order, String phoneNumber) async {
    // Format bill as text message
    final config = _storage.getAppConfig();
    final buffer = StringBuffer();

    buffer.writeln('${config.restaurantName}');
    buffer.writeln('Order: ${order.id}');
    buffer.writeln(
      'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}',
    );
    buffer.writeln('--------------------');

    for (final item in order.items) {
      buffer.writeln(
        '${item.name} x${item.quantity} = ₹${item.total.toStringAsFixed(2)}',
      );
    }

    buffer.writeln('--------------------');
    buffer.writeln(
      'Tax (${order.taxPercent}%): ₹${order.taxAmount.toStringAsFixed(2)}',
    );
    if (order.discount > 0) {
      buffer.writeln('Discount: -₹${order.discount.toStringAsFixed(2)}');
    }
    buffer.writeln('GRAND TOTAL: ₹${order.total.toStringAsFixed(2)}');
    buffer.writeln(config.footerMessage);

    final message = buffer.toString();

    // Try different SMS URI formats
    final smsUri = Uri.parse(
      'sms:$phoneNumber?body=${Uri.encodeComponent(message)}',
    );

    try {
      await launchUrl(smsUri);
      _showSuccess('SMS app opened!');
    } catch (e) {
      _showError('Failed to open SMS: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.only(left: 48),
          child: Text('Malhar Dosa'),
        ),
        backgroundColor: const Color(0xFF6e88b0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _isPrinterConnected ? Icons.print : Icons.print_disabled,
              color: _isPrinterConnected ? Colors.green : Colors.red,
            ),
            onPressed: _checkPrinterStatus,
            tooltip: _isPrinterConnected && _printerName != null
                ? '$_printerName (Connected)'
                : _isPrinterConnected
                ? 'Printer Connected'
                : 'Printer Disconnected',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              await _loadData();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Left side - Menu items
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Search bar
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search items...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = category),
                          selectedColor: const Color(
                            0xFF92B49C,
                          ).withOpacity(0.2),
                          backgroundColor: Colors.grey.shade200,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? const Color(0xFF341E1B)
                                : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Quick Dosas Section - Fill entire left side
                if (_isLoading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_menuItems.isNotEmpty)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Column(
                        children: [
                          // Clean variety list - fills all space
                          Expanded(
                            child: GridView.builder(
                              scrollDirection: Axis.vertical,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 1,
                                    childAspectRatio: 2.6,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                              itemCount: _menuItems
                                  .where(
                                    (i) =>
                                        i.category == _selectedCategory &&
                                        (_searchQuery.isEmpty ||
                                            i.name.toLowerCase().contains(
                                              _searchQuery,
                                            )),
                                  )
                                  .length,
                              itemBuilder: (context, index) {
                                final categoryItems = _menuItems
                                    .where(
                                      (i) =>
                                          i.category == _selectedCategory &&
                                          (_searchQuery.isEmpty ||
                                              i.name.toLowerCase().contains(
                                                _searchQuery,
                                              )),
                                    )
                                    .toList();
                                final item = categoryItems[index];
                                final orderIndex = _orderLines.indexWhere(
                                  (l) => l.itemId == item.id,
                                );
                                final quantity = orderIndex >= 0
                                    ? _orderLines[orderIndex].quantity
                                    : 0;
                                return Card(
                                  color: const Color(0xFF6e88b0), // Calm Ocean
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: () => _addItemToOrder(item),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(
                                                0xFFf2e0d0,
                                              ), // Soft Nude
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '₹${item.price.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(
                                                    0xFFf2e0d0,
                                                  ), // Soft Nude
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (quantity > 0) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFf2e0d0, // Soft Nude
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '$quantity',
                                                    style: const TextStyle(
                                                      color: Color(
                                                        0xFF6e88b0,
                                                      ), // Calm Ocean
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Right side - Order panel
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey.shade100,
              child: Column(
                children: [
                  // Order header
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF6e88b0),
                    child: const Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Current Order',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Order items list
                  Expanded(
                    child: _orderLines.isEmpty
                        ? const Center(
                            child: Text(
                              'Tap items to add to order',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _orderLines.length,
                            itemBuilder: (context, index) {
                              final line = _orderLines[index];
                              return Card(
                                color: const Color(0xFFf2e0d0), // Soft Nude
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                child: Container(
                                  height: 85,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    children: [
                                      // Name and total row
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              line.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(
                                                  0xFF6e88b0,
                                                ), // Calm Ocean
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            '₹${line.total.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Color(
                                                0xFF6e88b0,
                                              ), // Calm Ocean
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Price and buttons row
                                      Row(
                                        children: [
                                          Text(
                                            '₹${line.price.toStringAsFixed(0)} each',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(
                                                0xFF6e88b0,
                                              ), // Calm Ocean
                                            ),
                                          ),
                                          const Spacer(),
                                          // Buttons
                                          Row(
                                            children: [
                                              SizedBox(
                                                width: 28,
                                                height: 28,
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.remove_circle_outline,
                                                    size: 20,
                                                  ),
                                                  onPressed: () =>
                                                      _decrementQuantity(index),
                                                  padding: EdgeInsets.zero,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 30,
                                                child: Text(
                                                  '${line.quantity}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(
                                                      0xFF6e88b0,
                                                    ), // Calm Ocean
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 28,
                                                height: 28,
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.add_circle_outline,
                                                    size: 20,
                                                  ),
                                                  onPressed: () =>
                                                      _incrementQuantity(index),
                                                  padding: EdgeInsets.zero,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  // Bill summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Individual items list
                        ..._orderLines
                            .map(
                              (line) => _buildSummaryRow(
                                '${line.name} x${line.quantity}',
                                line.total,
                              ),
                            )
                            .toList(),
                        const Divider(),
                        _buildSummaryRow('Tax ($_taxPercent%):', _taxAmount),
                        if (_discount > 0)
                          _buildSummaryRow(
                            'Discount:',
                            -_discount,
                            isDiscount: true,
                          ),
                        const Divider(),
                        _buildSummaryRow(
                          'Grand Total:',
                          _grandTotal,
                          isTotal: true,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _orderLines.isEmpty
                                    ? null
                                    : _showDiscountDialog,
                                icon: const Icon(Icons.local_offer, size: 16),
                                label: Text(
                                  _discount > 0
                                      ? '₹${_discount.toStringAsFixed(0)}'
                                      : 'Discount',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _showClearConfirmation,
                                icon: const Icon(Icons.clear_all, size: 16),
                                label: const Text(
                                  'Clear',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _orderLines.isEmpty
                                ? null
                                : _printReceipt,
                            icon: const Icon(Icons.print),
                            label: const Text(
                              'PRINT RECEIPT',
                              style: TextStyle(fontSize: 18),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final items = _menuItems
        .where((item) => item.category == _selectedCategory)
        .toList();
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          elevation: 2,
          child: InkWell(
            onTap: () => _addItemToOrder(item),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF2E5016),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    final searchItems = _menuItems
        .where((item) => item.name.toLowerCase().contains(_searchQuery))
        .toList();
    if (searchItems.isEmpty) {
      return const Center(
        child: Text('No items found', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      itemCount: searchItems.length,
      itemBuilder: (context, index) {
        final item = searchItems[index];
        final orderIndex = _orderLines.indexWhere((l) => l.itemId == item.id);
        final quantity = orderIndex >= 0 ? _orderLines[orderIndex].quantity : 0;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            dense: true,
            title: Text(item.name, style: const TextStyle(fontSize: 14)),
            subtitle: Text(
              '₹${item.price.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: quantity > 0
                      ? () => _decrementItemQuantity(item.id)
                      : null,
                  iconSize: 20,
                ),
                Text(
                  '$quantity',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.green,
                  ),
                  onPressed: () => _addItemToOrder(item),
                  iconSize: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _decrementItemQuantity(String itemId) {
    setState(() {
      final index = _orderLines.indexWhere((l) => l.itemId == itemId);
      if (index >= 0) {
        final line = _orderLines[index];
        if (line.quantity > 1) {
          final newQuantity = line.quantity - 1;
          _orderLines[index] = line.copyWith(
            quantity: newQuantity,
            total: line.price * newQuantity,
          );
        } else {
          _orderLines.removeAt(index);
        }
      }
    });
    _calculateTotals();
  }

  Widget _buildSummaryRow(
    String label,
    double value, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 14 : 11,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${isDiscount || value < 0 ? '-' : ''}₹${value.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 11,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green.shade800 : null,
            ),
          ),
        ],
      ),
    );
  }
}
