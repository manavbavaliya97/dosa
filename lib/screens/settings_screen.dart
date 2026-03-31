import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../models/app_config.dart';
import '../models/printer_config.dart';
import '../services/storage_service.dart';
import '../services/printer_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  final PrinterService _printer = PrinterService();

  List<MenuItem> _menuItems = [];
  List<String> _categories = [];
  double _taxPercent = 5.0;
  String _restaurantName = 'Malhar Dosa';
  String _footerMessage = 'Thank you for visiting!';

  // Printer state
  String? _printerName;
  String? _printerAddress;
  bool _isPrinterConnected = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final items = await _storage.getMenuItems();
    final categories = await _storage.getCategories();
    final config = _storage.getAppConfig();
    final printerConfig = _storage.getPrinterConfig();
    final isPrinterConnected = await _printer.isConnected();

    if (mounted) {
      setState(() {
        _menuItems = items;
        _categories = categories;
        _taxPercent = config.taxPercent;
        _restaurantName = config.restaurantName;
        _footerMessage = config.footerMessage;
        _printerName = printerConfig?.deviceName;
        _printerAddress = printerConfig?.deviceAddress;
        _isPrinterConnected = isPrinterConnected;
      });
    }
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String selectedCategory = 'Dosa'; // Default to Dosa
    bool isNewCategory = false;
    final newCategoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Menu Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Item Name'),
                  autofocus: true,
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price (₹)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                if (!isNewCategory) ...[
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: (_categories.isEmpty ? ['Dosa'] : _categories)
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedCategory = value!),
                  ),
                  TextButton(
                    onPressed: () => setDialogState(() => isNewCategory = true),
                    child: const Text('Create New Category'),
                  ),
                ] else ...[
                  TextField(
                    controller: newCategoryController,
                    decoration: const InputDecoration(
                      labelText: 'New Category Name',
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        setDialogState(() => isNewCategory = false),
                    child: const Text('Select Existing Category'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text) ?? 0.0;
                final category = isNewCategory
                    ? newCategoryController.text.trim()
                    : selectedCategory;

                if (name.isEmpty || price <= 0 || category.isEmpty) {
                  _showError('Please fill all fields');
                  return;
                }

                final item = MenuItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  price: price,
                  category: category,
                );

                await _storage.addMenuItem(item);
                Navigator.of(context).pop();
                _loadData();
                _showSuccess('Item added successfully');
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditItemDialog(MenuItem item) {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price (₹)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _storage.deleteMenuItem(item.id);
              Navigator.of(context).pop();
              _loadData();
              _showSuccess('Item deleted');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text) ?? 0.0;

              if (name.isEmpty || price <= 0) {
                _showError('Please fill all fields');
                return;
              }

              final updatedItem = item.copyWith(name: name, price: price);
              await _storage.updateMenuItem(updatedItem);
              Navigator.of(context).pop();
              _loadData();
              _showSuccess('Item updated');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAppConfigDialog() {
    final taxController = TextEditingController(text: _taxPercent.toString());
    final nameController = TextEditingController(text: _restaurantName);
    final footerController = TextEditingController(text: _footerMessage);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Configuration'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Restaurant Name'),
              ),
              TextField(
                controller: taxController,
                decoration: const InputDecoration(
                  labelText: 'Tax Percentage (%)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: footerController,
                decoration: const InputDecoration(
                  labelText: 'Receipt Footer Message',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final tax = double.tryParse(taxController.text) ?? 5.0;
              final name = nameController.text.trim();
              final footer = footerController.text.trim();

              if (name.isEmpty) {
                _showError('Restaurant name cannot be empty');
                return;
              }

              // Update UI immediately
              setState(() {
                _taxPercent = tax;
                _restaurantName = name;
                _footerMessage = footer;
              });

              // Save in background (fire and forget)
              final updatedConfig = AppConfig(
                taxPercent: tax,
                restaurantName: name,
                footerMessage: footer,
              );
              _storage.updateAppConfig(updatedConfig);

              Navigator.of(context).pop();
              _showSuccess('Configuration saved');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPrinterConfigDialog() {
    final nameController = TextEditingController(text: _printerName ?? '');
    final addressController = TextEditingController(
      text: _printerAddress ?? '',
    );
    bool isScanning = false;
    List<BluetoothPrinterDevice> foundDevices = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Printer Configuration'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current printer status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isPrinterConnected
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isPrinterConnected ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isPrinterConnected
                            ? Icons.print
                            : Icons.print_disabled,
                        color: _isPrinterConnected ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isPrinterConnected
                                  ? 'Printer Connected'
                                  : 'No Printer Connected',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isPrinterConnected
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                            if (_printerName != null &&
                                _printerName!.isNotEmpty)
                              Text(
                                _printerName!,
                                style: const TextStyle(fontSize: 12),
                              ),
                            if (_printerAddress != null &&
                                _printerAddress!.isNotEmpty)
                              Text(
                                'Address: $_printerAddress',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Enter Bluetooth Printer Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Printer Name',
                    hintText: 'e.g., XP-P300',
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'MAC Address',
                    hintText: 'e.g., 00:11:22:33:44:55',
                    prefixIcon: Icon(Icons.bluetooth),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Note: Make sure your Bluetooth printer is paired with this device before connecting.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (isScanning) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Scanning for printers...',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
                if (foundDevices.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Found Printers:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...foundDevices.map(
                    (device) => ListTile(
                      leading: const Icon(
                        Icons.print,
                        color: Color(0xFF6e88b0),
                      ),
                      title: Text(device.name),
                      subtitle: Text(device.address),
                      onTap: () {
                        nameController.text = device.name;
                        addressController.text = device.address;
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (_isPrinterConnected)
              TextButton(
                onPressed: () async {
                  await _printer.disconnect();
                  Navigator.of(context).pop();
                  _loadData();
                  _showSuccess('Printer disconnected');
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Disconnect'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isScanning
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final address = addressController.text.trim();

                      if (name.isEmpty || address.isEmpty) {
                        _showError('Please enter both name and address');
                        return;
                      }

                      // Show loading
                      setDialogState(() => isScanning = true);

                      // Try to connect
                      final connected = await _printer.connectToPrinter(
                        address,
                        name,
                      );

                      setDialogState(() => isScanning = false);

                      if (connected) {
                        Navigator.of(context).pop();
                        _loadData();
                        _showSuccess('Printer connected successfully');
                      } else {
                        _showError(
                          'Failed to connect to printer. Please check:\n'
                          '1. Bluetooth is enabled\n'
                          '2. Printer is paired with this device\n'
                          '3. MAC address is correct',
                        );
                      }
                    },
              child: isScanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Connect'),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF6e88b0),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: const Color(0xFF6e88b0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _buildMenuTab(),
    );
  }

  Widget _buildMenuTab() {
    return Column(
      children: [
        // Config bar
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFFf2e0d0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Restaurant: $_restaurantName',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Tax: $_taxPercent%'),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAppConfigDialog,
                icon: const Icon(Icons.edit),
                label: const Text('Edit Config'),
              ),
            ],
          ),
        ),
        // Printer config bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              Icon(
                _isPrinterConnected ? Icons.print : Icons.print_disabled,
                color: _isPrinterConnected ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isPrinterConnected
                          ? 'Printer Ready'
                          : 'Printer Not Connected',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isPrinterConnected
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                    if (_printerName != null)
                      Text(
                        _printerName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showPrinterConfigDialog,
                icon: const Icon(Icons.settings),
                label: const Text('Configure'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6e88b0),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Menu items list
        Expanded(
          child: _categories.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading menu items...'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, catIndex) {
                    final category = _categories[catIndex];
                    final items = _menuItems
                        .where((item) => item.category == category)
                        .toList();

                    return ExpansionTile(
                      title: Text(
                        category,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      children: items
                          .map(
                            (item) => ListTile(
                              title: Text(item.name),
                              subtitle: Text(
                                '₹${item.price.toStringAsFixed(0)}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditItemDialog(item),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
