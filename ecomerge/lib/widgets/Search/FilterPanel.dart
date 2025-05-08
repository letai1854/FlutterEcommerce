import 'package:flutter/material.dart';

class FilterPanel extends StatefulWidget {
  final Function({
    required int? categoryId,
    required String? brandName,
    required int minPrice, 
    required int maxPrice
  }) onFiltersApplied;
  // Changed from Map<int, bool> to int? for single selection
  final int? selectedCategoryId;
  // Changed from Set<String> to String? for single selection
  final String? selectedBrandName;
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
    required this.selectedCategoryId,
    required this.selectedBrandName,
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
  // Local state to track selections
  int? _categoryId;
  String? _brandName;
  
  @override
  void initState() {
    super.initState();
    _categoryId = widget.selectedCategoryId;
    _brandName = widget.selectedBrandName;
  }
  
  @override
  void didUpdateWidget(FilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update local state if external state changed
    if (widget.selectedCategoryId != oldWidget.selectedCategoryId) {
      _categoryId = widget.selectedCategoryId;
    }
    
    if (widget.selectedBrandName != oldWidget.selectedBrandName) {
      _brandName = widget.selectedBrandName;
    }
  }

  void applyFilters() {
    // Send single selected category and brand
    widget.onFiltersApplied(
      categoryId: _categoryId,
      brandName: _brandName,
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
            
            // Categories Filter - Now using Radio buttons
            Text(
              'Danh mục',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            
            // All categories option (no filter)
            _buildCategoryRadioItem(null, 'Tất cả danh mục'),
            
            // Selectable category items
            ...widget.catalog.map((category) => 
              _buildCategoryRadioItem(category['id'], category['name'])
            ).toList(),
            
            SizedBox(height: 16),
            Divider(),
            
            // Brands Filter - Now using Radio buttons
            Text(
              'Thương hiệu',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            
            // All brands option (no filter)
            _buildBrandRadioItem(null, 'Tất cả thương hiệu'),
            
            // Selectable brand items
            ...widget.brands.map((brand) => 
              _buildBrandRadioItem(brand, brand)
            ).toList(),
            
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
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
            ),
          ],
        ),
      ),
    );
  }
  
  // New method to build category radio button
  Widget _buildCategoryRadioItem(int? categoryId, String name) {
    final bool isSelected = _categoryId == categoryId;
    
    return InkWell(
      onTap: () {
        setState(() {
          _categoryId = categoryId; // Select this category or null to deselect
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: isSelected ? Colors.red : Colors.grey,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.red : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // New method to build brand radio button
  Widget _buildBrandRadioItem(String? brand, String displayName) {
    final bool isSelected = _brandName == brand;
    
    return InkWell(
      onTap: () {
        setState(() {
          _brandName = brand; // Select this brand or null to deselect
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: isSelected ? Colors.red : Colors.grey,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.red : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
