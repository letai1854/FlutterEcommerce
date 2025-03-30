import 'package:flutter/material.dart';


// New FilterPanel StatefulWidget
class FilterPanel extends StatefulWidget {
  final Function({
    required List<int> categories,
    required List<String> brands,
    required int minPrice, 
    required int maxPrice
  }) onFiltersApplied;

  const FilterPanel({
    Key? key,
    required this.onFiltersApplied,
  }) : super(key: key);

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  // State variables for tracking selections
  Map<int, bool> selectedCategories = {};
  Set<String> selectedBrands = {};
  TextEditingController minPriceController = TextEditingController();
  TextEditingController maxPriceController = TextEditingController();
  
  // Values for min and max prices
  int minPrice = 0;
  int maxPrice = 10000000; // 10 million VND default max
  final int priceStep = 1000000; // Step by 1 million VND
  
  final List<Map<String, dynamic>> catalog = [
    {
      'name': 'Laptop',
      'img': 'https://anhnail.com/wp-content/uploads/2024/11/son-goku-ngau-nhat.jpg',
      'id': 1,
    },
    {
      'name': 'Bàn phím',
      'img': 'https://hoangtuan.vn/media/product/844_ban_phim_co_geezer_gs2_rgb_blue_switch.jpg',
      'id': 2,
    },
    {
      'name': 'Chuột',
      'img': 'https://png.pngtree.com/png-vector/20240626/ourlar…n-transparent-background-a-png-image_12849468.png',
      'id': 3,
    },
    {
      'name': 'Hub',
      'img': 'https://vienthongxanh.vn/wp-content/uploads/2022/12/hinh-anh-minh-hoa-thiet-bi-switch.png',
      'id': 4,
    },
    {
      'name': 'Tai nghe',
      'img': 'https://img.lovepik.com/free-png/20211120/lovepik-headset-png-image_401058941_wh1200.png',
      'id': 5,
    }
  ];

  // List of brands
  final List<String> brands = [
    'Apple',
    'Samsung',
    'Dell',
    'HP',
    'Asus',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize the text controllers with formatted values
    minPriceController.text = formatPrice(minPrice);
    maxPriceController.text = formatPrice(maxPrice);
  }

  @override
  void dispose() {
    minPriceController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }

  // Format price with commas
  String formatPrice(int price) {
    return price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},');
  }
  
  // Parse price from formatted string
  int parsePrice(String text) {
    if (text.isEmpty) return 0;
    return int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }
  
  // Update min price with validation
  void updateMinPrice(int newValue) {
    if (newValue < 0) newValue = 0;
    if (newValue > maxPrice) newValue = maxPrice;
    
    setState(() {
      minPrice = newValue;
      minPriceController.text = formatPrice(newValue);
    });
  }
  
  // Update max price with validation
  void updateMaxPrice(int newValue) {
    if (newValue < minPrice) newValue = minPrice;
    
    setState(() {
      maxPrice = newValue;
      maxPriceController.text = formatPrice(newValue);
    });
  }
  
  // Apply the filters
  void applyFilters() {
    // Convert selected categories to list
    List<int> categoryIds = selectedCategories.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
        
    // Convert selected brands to list
    List<String> brandNames = selectedBrands.toList();
    
    // Notify parent about filters
    widget.onFiltersApplied(
      categories: categoryIds,
      brands: brandNames,
      minPrice: minPrice,
      maxPrice: maxPrice,
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
            ...catalog.map((category) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    // Toggle selection for this category
                    selectedCategories[category['id']] = 
                        !(selectedCategories[category['id']] ?? false);
                  });
                  print('Selected category: ${category['name']}, isSelected: ${selectedCategories[category['id']]}');
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: (selectedCategories[category['id']] ?? false)
                        ? Colors.red.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (selectedCategories[category['id']] ?? false)
                          ? Colors.red
                          : Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        (selectedCategories[category['id']] ?? false)
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        size: 16,
                        color: (selectedCategories[category['id']] ?? false)
                            ? Colors.red
                            : Colors.grey,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category['name'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: (selectedCategories[category['id']] ?? false)
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: (selectedCategories[category['id']] ?? false)
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
            ...brands.map((brand) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    // Toggle selection for this brand
                    if (selectedBrands.contains(brand)) {
                      selectedBrands.remove(brand);
                    } else {
                      selectedBrands.add(brand);
                    }
                  });
                  print('Selected brand: $brand, isSelected: ${selectedBrands.contains(brand)}');
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: selectedBrands.contains(brand)
                        ? Colors.red.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selectedBrands.contains(brand)
                          ? Colors.red
                          : Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedBrands.contains(brand)
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        size: 16,
                        color: selectedBrands.contains(brand)
                            ? Colors.red
                            : Colors.grey,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          brand,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: selectedBrands.contains(brand)
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selectedBrands.contains(brand)
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
                      onTap: () => updateMinPrice(minPrice - priceStep),
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
                        controller: minPriceController,
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
                          int parsedValue = parsePrice(value);
                          minPrice = parsedValue;
                        },
                        onSubmitted: (value) {
                          updateMinPrice(parsePrice(value));
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
                      onTap: () => updateMinPrice(minPrice + priceStep),
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
                      onTap: () => updateMaxPrice(maxPrice - priceStep),
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
                        controller: maxPriceController,
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
                          int parsedValue = parsePrice(value);
                          maxPrice = parsedValue;
                        },
                        onSubmitted: (value) {
                          updateMaxPrice(parsePrice(value));
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
                      onTap: () => updateMaxPrice(maxPrice + priceStep),
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

