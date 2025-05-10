import 'dart:typed_data';

import 'package:e_commerce_app/database/models/CartDTO.dart';
import 'package:e_commerce_app/database/Storage/CartStorage.dart';
import 'package:flutter/material.dart';

// Utility function to format numbers with thousands separators
String formatPrice(double price) {
  String priceStr = price.toStringAsFixed(0);
  final pattern = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
  return priceStr.replaceAllMapped(pattern, (Match m) => '${m[1]}.');
}

// Create a cached image widget that doesn't rebuild unnecessarily
class CachedCartImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double width;
  final double height;

  const CachedCartImage({
    Key? key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width = double.infinity,
    this.height = double.infinity,
  }) : super(key: key);

  @override
  State<CachedCartImage> createState() => _CachedCartImageState();
}

class _CachedCartImageState extends State<CachedCartImage> {
  Uint8List? _imageData;
  bool _isLoading = true;
  bool _hasError = false;
  final cartStorage = CartStorage();

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedCartImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageUrl.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final imageData = await cartStorage.getImage(widget.imageUrl);
      if (mounted) {
        setState(() {
          _imageData = imageData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError || _imageData == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Icon(
          Icons.image_not_supported,
          size: 40,
          color: Colors.grey,
        ),
      );
    }

    return Image.memory(
      _imageData!,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
    );
  }
}

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
    
    // Debug: Print the name we're receiving
    print('Cart item name: ${item.productVariant?.name}');
    
    // Make sure we're formatting correctly if the server didn't return a formatted name
    String name = item.productVariant?.name ?? 'Unknown product';
    
    // Get discount percentage and prices
    final double? discountPercentage = item.productVariant?.discountPercentage;
    final bool hasDiscount = discountPercentage != null && discountPercentage > 0;
    
    // Get final price (after discount) and original price
    final double finalPrice = item.productVariant?.finalPrice ?? item.productVariant?.price ?? 0;
    final double originalPrice = hasDiscount 
        ? finalPrice / (1 - (discountPercentage / 100))  // Calculate original price if discounted
        : finalPrice;
        
    final quantity = item.quantity ?? 0;
    final lineTotal = finalPrice * quantity;
    
    // Check if the item is out of stock
    final int stockQuantity = item.productVariant?.stockQuantity ?? 0;
    final bool isOutOfStock = stockQuantity <= 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        color: isOutOfStock ? Colors.grey[50] : Colors.transparent,
      ),
      child: Row(
        children: [
          // Product info with checkbox
          Expanded(
            flex: 4,
            child: Row(
              children: [
                // Disabled checkbox for out-of-stock items
                Checkbox(
                  value: isSelected,
                  onChanged: isOutOfStock ? null : (value) => toggleSelectItem(cartItemId),
                  activeColor: Colors.red,
                ),
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedCartImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: 100,
                        height: 100,
                      ),
                      // Show "Out of Stock" overlay for items with no stock
                      if (isOutOfStock)
                        Container(
                          color: Colors.black.withOpacity(0.5),
                          child: const Center(
                            child: Text(
                              'Hết hàng',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      // Show discount badge if product has discount
                      if (hasDiscount)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: Text(
                              '-${discountPercentage!.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (isOutOfStock)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Sản phẩm tạm hết hàng',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Unit price with discount info
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasDiscount)
                  Text(
                    '${formatPrice(originalPrice)} VND',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      decoration: TextDecoration.lineThrough,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                Text(
                  '${formatPrice(finalPrice)} VND',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: hasDiscount ? Colors.red : null,
                    fontWeight: hasDiscount ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
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
              '${formatPrice(lineTotal)} VND',
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
    
    // Make sure we're formatting consistently on mobile too
    String name = item.productVariant?.name ?? 'Unknown product';
    
    // Get discount percentage and prices
    final double? discountPercentage = item.productVariant?.discountPercentage;
    final bool hasDiscount = discountPercentage != null && discountPercentage > 0;
    
    // Get final price (after discount) and original price
    final double finalPrice = item.productVariant?.finalPrice ?? item.productVariant?.price ?? 0;
    final double originalPrice = hasDiscount 
        ? finalPrice / (1 - (discountPercentage! / 100))  // Calculate original price if discounted
        : finalPrice;
        
    final quantity = item.quantity ?? 0;
    final lineTotal = finalPrice * quantity;
    
    // Check if the item is out of stock
    final int stockQuantity = item.productVariant?.stockQuantity ?? 0;
    final bool isOutOfStock = stockQuantity <= 0;
    
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
                  // Disabled checkbox for out-of-stock items
                  Checkbox(
                    value: isSelected,
                    onChanged: isOutOfStock ? null : (value) => toggleSelectItem(cartItemId),
                    activeColor: Colors.red,
                  ),
                  
                  // Product image with out-of-stock overlay
                  Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: CachedCartImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                        ),
                      ),
                      if (isOutOfStock)
                        Container(
                          width: 80,
                          height: 80,
                          color: Colors.black.withOpacity(0.5),
                          child: const Center(
                            child: Text(
                              'Hết hàng',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      // Show discount badge if product has discount
                      if (hasDiscount)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: Text(
                              '-${discountPercentage!.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Product details with discount info
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
                        if (hasDiscount) ...[
                          Text(
                            '${formatPrice(originalPrice)} VND',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Row(
                          children: [
                            Text(
                              '${formatPrice(finalPrice)} VND',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (hasDiscount) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  '-${discountPercentage!.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (isOutOfStock)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Sản phẩm tạm hết hàng',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
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
                    'Tổng: ${formatPrice(lineTotal)} VND',
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
