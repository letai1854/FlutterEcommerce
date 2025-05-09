import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:flutter/material.dart';

class PointsContent extends StatelessWidget {
  const PointsContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return SingleChildScrollView(
      // Wrap in SingleChildScrollView to prevent overflow
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Points summary card
            _buildPointsSummaryCard(),

            const SizedBox(height: 24),

            // // Points history section with transactions
            // const Text(
            //   "Lịch sử điểm",
            //   style: TextStyle(
            //     fontSize: 18,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),

            const SizedBox(height: 16),

            // Use ListView.builder instead of Column for a list of transactions
            // This will make the list more efficient and scrollable within the SingleChildScrollView
            ListView.builder(
              physics:
                  const NeverScrollableScrollPhysics(), // Disable scrolling as parent is scrollable
              shrinkWrap:
                  true, // Important for ListView inside SingleChildScrollView
              itemCount: _getPointsTransactions().length,
              itemBuilder: (context, index) {
                final transaction = _getPointsTransactions()[index];
                // return _buildTransactionItem(transaction, isSmallScreen);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 28),
                SizedBox(width: 8),
                Text(
                  "Điểm tích lũy của bạn",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  UserInfo().currentUser?.customerPoints.toString() ?? "0",
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  "điểm",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    // Use Expanded to prevent overflow on small screens
                    child: Text(
                      "Điểm tích lũy sẽ được tính 10% cho mỗi đơn hàng thành công",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
      Map<String, dynamic> transaction, bool isSmallScreen) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction type icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: transaction["type"] == "earn"
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                transaction["type"] == "earn"
                    ? Icons.add_circle
                    : Icons.remove_circle,
                color:
                    transaction["type"] == "earn" ? Colors.green : Colors.red,
              ),
            ),

            const SizedBox(width: 16),

            // Transaction details - use Expanded to prevent overflow
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction["description"],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction["date"],
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Points amount
            Text(
              "${transaction["type"] == "earn" ? "+" : "-"}${transaction["points"]}",
              style: TextStyle(
                color:
                    transaction["type"] == "earn" ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getPointsTransactions() {
    return [
      {
        "type": "earn",
        "points": 250,
        "description": "Đơn hàng DH123456",
        "date": "15/05/2023",
      },
      {
        "type": "earn",
        "points": 150,
        "description": "Đánh giá sản phẩm",
        "date": "12/05/2023",
      },
      {
        "type": "spend",
        "points": 100,
        "description": "Đổi điểm thành voucher giảm giá",
        "date": "10/05/2023",
      },
      {
        "type": "earn",
        "points": 500,
        "description": "Đơn hàng DH123450",
        "date": "05/05/2023",
      },
      {
        "type": "spend",
        "points": 200,
        "description": "Đổi điểm thành voucher giảm giá",
        "date": "01/05/2023",
      },
    ];
  }
}
