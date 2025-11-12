import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cart_item.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_providers.dart';

class CheckoutConfirmationScreen extends ConsumerStatefulWidget {
  final List<CartItem> items;
  final double total;

  const CheckoutConfirmationScreen({super.key, required this.items, required this.total});

  @override
  ConsumerState<CheckoutConfirmationScreen> createState() => _CheckoutConfirmationScreenState();
}

class _CheckoutConfirmationScreenState extends ConsumerState<CheckoutConfirmationScreen> {
  bool _loading = false;
  String? _shippingAddress;
  String? _paymentMethod;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final cartSvc = ref.read(cartServiceProvider);
    final addr = await cartSvc?.getShippingAddress();
    final pm = await cartSvc?.getPaymentMethod();
    if (!mounted) return;
    setState(() {
      _shippingAddress = addr;
      _paymentMethod = pm;
    });
  }

  Future<void> _placeOrder() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    try {
  // For now, we assume single-seller checkout like the existing service expects.
      if (_shippingAddress == null || _shippingAddress!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please set a shipping address')));
        return;
      }
      if (_paymentMethod == null || _paymentMethod!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a payment method')));
        return;
      }

      // Determine sellerId from the first product in the cart (single-seller
      // checkout assumed for MVP). Fall back to a placeholder only if lookup
      // fails.
      if (widget.items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart is empty')));
        return;
      }
      final productSvc = ref.read(productServiceProvider);
      final firstProd = await productSvc.fetch(widget.items.first.productId);
      final sellerId = firstProd?.sellerId ?? 'demo-seller';

      final orderId = await ref.read(orderServiceProvider).checkout(
            userId: user.uid,
            sellerId: sellerId,
            items: widget.items,
            shippingAddress: _shippingAddress ?? 'Sample address',
          );
  // Clear cart if CartService available
  final cartSvc = ref.read(cartServiceProvider);
  await cartSvc?.clear();

      if (!mounted) return;
      // Show success and pop to root or go to order details
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Order placed'),
          content: Text('Order #${orderId.substring(0, 8)} placed successfully'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
          ],
        ),
      );
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error placing order: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm order')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: ListTile(
                    title: const Text('Shipping address'),
                    subtitle: Text(_shippingAddress ?? 'No address set'),
                    trailing: TextButton(
                        onPressed: () async {
                          final res = await showDialog<String>(
                            context: context,
                            builder: (ctx) {
                              final ctrl = TextEditingController(text: _shippingAddress ?? '');
                              return AlertDialog(
                                title: const Text('Edit shipping address'),
                                content: TextField(
                                  controller: ctrl,
                                  maxLines: 4,
                                  decoration: const InputDecoration(hintText: 'Enter full shipping address'),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                                  ElevatedButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()), child: const Text('Save')),
                                ],
                              );
                            },
                          );
                          if (res != null) {
                            final cartSvc = ref.read(cartServiceProvider);
                            await cartSvc?.setShippingAddress(res);
                            if (!mounted) return;
                            setState(() => _shippingAddress = res);
                          }
                        },
                        child: const Text('Edit')),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...widget.items.map((i) => ListTile(
                              leading: i.imageUrl.isNotEmpty ? Image.network(i.imageUrl, width: 56, height: 56, fit: BoxFit.cover) : null,
                              title: Text(i.title),
                              trailing: Text('x${i.qty}'),
                            )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('Payment method'),
                    subtitle: Text(_paymentMethod ?? 'No payment selected'),
                    trailing: TextButton(
                        onPressed: () async {
                          final options = ['GCash • 63-9***20084', 'Credit/Debit Card', 'Cash on Delivery'];
                          final sel = await showModalBottomSheet<String>(
                            context: context,
                            builder: (ctx) => ListView.separated(
                              itemBuilder: (c, i) => ListTile(
                                title: Text(options[i]),
                                onTap: () => Navigator.of(ctx).pop(options[i]),
                              ),
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemCount: options.length,
                            ),
                          );
                          if (sel != null) {
                            final cartSvc = ref.read(cartServiceProvider);
                            await cartSvc?.setPaymentMethod(sel);
                            if (!mounted) return;
                            setState(() => _paymentMethod = sel);
                          }
                        },
                        child: const Text('Change')),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Order summary', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Subtotal'), Text('\₱${widget.total.toStringAsFixed(2)}')]),
                        const SizedBox(height: 4),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('Shipping'), Text('\₱0.00')]),
                        const SizedBox(height: 4),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('Promotion'), Text('-\₱0.00')]),
                        const Divider(),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total', style: Theme.of(context).textTheme.titleLarge), Text('\₱${widget.total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge)]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _placeOrder,
                  child: _loading ? const CircularProgressIndicator(color: Colors.white) : Text('Place order now • ₱${widget.total.toStringAsFixed(2)}'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
