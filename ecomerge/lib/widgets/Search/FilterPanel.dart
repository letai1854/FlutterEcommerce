import 'package:flutter/material.dart';

class FilterPanel extends StatefulWidget {
  final Function({
    required List<int> categories,
    required List<String> brands,
    required int minPrice, 
    required int maxPrice
  }) onFiltersApplied;
  final Map<int, bool> selectedCategories;
  final Set<String> selectedBrands;
  final int minPrice;
  final int maxPrice;
  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;
  final int priceStep;
  final List<Map<String, dynamic>> catalog;
  final List<String> brands;
  final Function(int) updateMinPrice;
  final Function(int) updateMaxPrice;
  final String Function(int) formatPrice;
  final int Function(String) parsePrice;

  const FilterPanel({
    Key? key,
    required this.onFiltersApplied,
    required this.selectedCategories,
    required this.selectedBrands,
    required this.minPrice,
    required this.maxPrice,
    required this.minPriceController,
    required this.maxPriceController,
    required this.priceStep,
    required this.catalog,
    required this.brands,
    required this.updateMinPrice,
    required this.updateMaxPrice,
    required this.formatPrice,
    required this.parsePrice,
  }) : super(key: key);

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  void applyFilters() {
    // Convert selected categories to list
    List<int> categoryIds = widget.selectedCategories.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
        
    // Convert selected brands to list
    List<String> brandNames = widget.selectedBrands.toList();
    
    // Notify parent about filters
    widget.onFiltersApplied(
      categories: categoryIds,
      brands: brandNames,
      minPrice: widget.minPrice,
      maxPrice: widget.maxPrice,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: MediaQuery.of(context).size.height - 146, // Account for navbar and top padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ListView(
          children: [
            // Filter Title
            Text(
              'Bộ Lọc Sản Phẩm',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(height: 24),
            
            // Categories Filter
            Text(
              'Danh mục',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            
            // Selectable category items
            ...widget.catalog.map((category) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    // Toggle selection for this category
                    widget.selectedCategories[category['id']] = 
                        !(widget.selectedCategories[category['id']] ?? false);
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: (widget.selectedCategories[category['id']] ?? false)
                        ? Colors.red.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (widget.selectedCategories[category['id']] ?? false)
                          ? Colors.red
                          : Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        (widget.selectedCategories[category['id']] ?? false)
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        size: 16,
                        color: (widget.selectedCategories[category['id']] ?? false)
                            ? Colors.red
                            : Colors.grey,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category['name'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: (widget.selectedCategories[category['id']] ?? false)
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: (widget.selectedCategories[category['id']] ?? false)
                                ? Colors.red
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )).toList(),
            
            SizedBox(height: 16),
            Divider(),
            
            // Brands Filter
            Text(
              'Thương hiệu',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            
            // Selectable brand items
            ...widget.brands.map((brand) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    // Toggle selection for this brand
                    if (widget.selectedBrands.contains(brand)) {
                      widget.selectedBrands.remove(brand);
                    } else {
                      widget.selectedBrands.add(brand);
                    }
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: widget.selectedBrands.contains(brand)
                        ? Colors.red.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: widget.selectedBrands.contains(brand)
                          ? Colors.red
                          : Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.selectedBrands.contains(brand)
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        size: 16,
                        color: widget.selectedBrands.contains(brand)
                            ? Colors.red
                            : Colors.grey,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          brand,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: widget.selectedBrands.contains(brand)
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: widget.selectedBrands.contains(brand)
                                ? Colors.red
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )).toList(),
            
            SizedBox(height: 16),
            Divider(),
            
            // Price Range Filter
            Text(
              'Khoảng giá',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            
            // Min price input with improved styling
            Text('Tối thiểu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Decrement button
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
                    child: InkWell(
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
                      onTap: () => widget.updateMinPrice(widget.minPrice - widget.priceStep),
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
                        ),
                        child: Icon(
                          Icons.remove,
                          size: 18,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ),
                  
                  // Input field
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade300),
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                        color: Colors.white,
                      ),
                      child: TextField(
                        controller: widget.minPriceController,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: '0 đ',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                          suffixText: ' đ',
                          suffixStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        onChanged: (value) {
                          int parsedValue = widget.parsePrice(value);
                          widget.updateMinPrice(parsedValue);
                        },
                        onSubmitted: (value) {
                          widget.updateMinPrice(widget.parsePrice(value));
                        },
                      ),
                    ),
                  ),
                  
                  // Increment button
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
                    child: InkWell(
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
                      onTap: () => widget.updateMinPrice(widget.minPrice + widget.priceStep),
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
                        ),
                        child: Icon(
                          Icons.add,
                          size: 18,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Max price input with improved styling
            Text('Tối đa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Decrement button
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
                    child: InkWell(
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
                      onTap: () => widget.updateMaxPrice(widget.maxPrice - widget.priceStep),
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
                        ),
                        child: Icon(
                          Icons.remove,
                          size: 18,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ),
                  
                  // Input field
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade300),
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                        color: Colors.white,
                      ),
                      child: TextField(
                        controller: widget.maxPriceController,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: '10,000,000 đ',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                          suffixText: ' đ',
                          suffixStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        onChanged: (value) {
                          int parsedValue = widget.parsePrice(value);
                          widget.updateMaxPrice(parsedValue);
                        },
                        onSubmitted: (value) {
                          widget.updateMaxPrice(widget.parsePrice(value));
                        },
                      ),
                    ),
                  ),
                  
                  // Increment button
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
                    child: InkWell(
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
                      onTap: () => widget.updateMaxPrice(widget.maxPrice + widget.priceStep),
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
                        ),
                        child: Icon(
                          Icons.add,
                          size: 18,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Apply button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: applyFilters,
              child: Text(
                'Áp Dụng',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
