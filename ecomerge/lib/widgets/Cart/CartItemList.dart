import 'dart:typed_data';

import 'package:e_commerce_app/database/models/CartDTO.dart';
import 'package:e_commerce_app/database/Storage/CartStorage.dart';
import 'package:flutter/material.dart';

class CartItemList extends StatelessWidget {
  final List<CartItemDTO> cartItems;
  final Map<int?, bool> selectedItems;
  final Function(int) toggleSelectItem;
  final Function(int) increaseQuantity;
  final Function(int) decreaseQuantity;
  final Function(int) removeItem;

  const CartItemList({
    Key? key,
    required this.cartItems,
    required this.selectedItems,
    required this.toggleSelectItem,
    required this.increaseQuantity,
    required this.decreaseQuantity,
    required this.removeItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1100;
    final isTablet = MediaQuery.of(context).size.width >= 768 && MediaQuery.of(context).size.width < 1100;

    if (isDesktop) {
      return _buildDesktopLayout(context);
    } else if (isTablet) {
      return _buildTabletLayout(context);
    } else {
      return _buildMobileLayout(context);
    }
  }

  // Desktop layout - horizontal table with all columns
  Widget _buildDesktopLayout(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: const Text(
              'Giỏ hàng của bạn',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 4,
                  child: Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 1,
                  child: Text('Đơn giá',
                      textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 1,
                  child: Text('Số lượng',
                      textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 1,
                  child: Text('Thành tiền',
                      textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Expanded(
                  flex: 1,
                  child: Text('Thao tác',
                      textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          // Cart items
          ...cartItems.map((item) => _buildDesktopItemRow(item, context)).toList(),
        ],
      ),
    );
  }

  Widget _buildDesktopItemRow(CartItemDTO item, BuildContext context) {
    final cartItemId = item.cartItemId ?? -1;
    final isSelected = selectedItems[item.cartItemId] ?? false;
    
    final imageUrl = item.productVariant?.imageUrl ?? '';
    final name = item.productVariant?.name ?? 'Unknown product';
    final price = item.productVariant?.finalPrice ?? item.productVariant?.price ?? 0;
    final quantity = item.quantity ?? 0;
    final lineTotal = price * quantity;
    
    // Use CartStorage to get cached image if available
    final cartStorage = CartStorage();
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          // Product info with checkbox
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => toggleSelectItem(cartItemId),
                  activeColor: Colors.red,
                ),
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: FutureBuilder<Uint8List?>(
                    future: cartStorage.getImage(imageUrl),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (snapshot.hasData && snapshot.data != null) {
                        return Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                        );
                      }
                      
                      return Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          // Unit price
          Expanded(
            flex: 1,
            child: Text(
              '₫${price.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
            ),
          ),
          // Quantity control
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  color: Colors.red,
                  onPressed: () {
                    decreaseQuantity(cartItemId);
                  },
                ),
                Text(quantity.toString()),
                IconButton(
                  icon: const Icon(Icons.add),
                  color: Colors.green,
                  onPressed: () {
                    increaseQuantity(cartItemId);
                  },
                ),
              ],
            ),
          ),
          // Line total
          Expanded(
            flex: 1,
            child: Text(
              '₫${lineTotal.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          // Remove button
          Expanded(
            flex: 1,
            child: Center(
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                ),
                onPressed: () {
                  removeItem(cartItemId);
                },
                child: const Text('Xóa'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tablet layout with slight adjustments
  Widget _buildTabletLayout(BuildContext context) {
    // Similar to desktop but with fewer columns or adjusted layout
    // ... existing tablet layout code adapted for CartItemDTO ...
    return _buildDesktopLayout(context); // For simplicity, using desktop layout for now
  }

  // Mobile layout - vertical cards
  Widget _buildMobileLayout(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: const Text(
              'Giỏ hàng của bạn',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          // Mobile item cards
          ...cartItems.map((item) => _buildMobileItemCard(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildMobileItemCard(CartItemDTO item) {
    final cartItemId = item.cartItemId ?? -1;
    final isSelected = selectedItems[item.cartItemId] ?? false;
    
    final imageUrl = item.productVariant?.imageUrl ?? '';
    final name = item.productVariant?.name ?? 'Unknown product';
    final price = item.productVariant?.finalPrice ?? item.productVariant?.price ?? 0;
    final quantity = item.quantity ?? 0;
    final lineTotal = price * quantity;
    
    // Use CartStorage to get cached image if available
    final cartStorage = CartStorage();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Top row - product image and info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) => toggleSelectItem(cartItemId),
                    activeColor: Colors.red,
                  ),
                  
                  // Product image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: FutureBuilder<Uint8List?>(
                      future: cartStorage.getImage(imageUrl),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        if (snapshot.hasData && snapshot.data != null) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          );
                        }
                        
                        return Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.image_not_supported,
                            size: 30,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Product details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₫${price.toStringAsFixed(0)}',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const Divider(),
              
              // Bottom row - quantity controls and actions
              Row(
                children: [
                  const Spacer(),
                  // Quantity controls
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => decreaseQuantity(cartItemId),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(quantity.toString()),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => increaseQuantity(cartItemId),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Delete button
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    label: const Text('Xóa'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => removeItem(cartItemId),
                  ),
                ],
              ),
              
              // Total line
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                  child: Text(
                    'Tổng: ₫${lineTotal.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
