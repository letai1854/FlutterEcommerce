import 'package:flutter/material.dart';
import 'dart:math';
import 'package:e_commerce_app/database/services/admin_user_service.dart';
import 'package:e_commerce_app/database/models/UserDTO.dart';
import 'dart:typed_data'; // Add this import at the top of the file

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  // Add service instance
  final AdminUserService _adminUserService = AdminUserService();

  // Variables for pagination
  int _currentPage = 0;
  final int _rowsPerPage = 10;
  int _totalUsers = 0;
  bool _isLoading = true;
  String _searchEmail = '';

  // List to store users
  List<UserDTO> _allUsers = [];
  List<UserDTO> _filteredUsers = [];

  // Get paginated data
  List<UserDTO> get _paginatedData {
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = min(startIndex + _rowsPerPage, _filteredUsers.length);

    if (startIndex >= _filteredUsers.length) return [];
    return _filteredUsers.sublist(startIndex, endIndex);
  }

  // Calculate total pages
  int get _pageCount => (_filteredUsers.length / _rowsPerPage).ceil();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _userDataSource = UserDataSource([], this);
  }

  // Load users from service
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _adminUserService.getAllUsers();
      print('Total users returned from API: ${users.length}');
      print('All users: ${users.map((u) => "${u.id}:${u.email}:${u.role}").join(', ')}');
      
      final filteredUsers = users.where((user) => user.role == 'khach_hang').toList();
      print('Customer users: ${filteredUsers.length}');
      print('Customer details: ${filteredUsers.map((u) => "${u.id}:${u.email}:${u.role}").join(', ')}');
      
      setState(() {
        // Filter to only show regular users (not admins), but include both active and locked accounts
        _allUsers = filteredUsers;
        _filteredUsers = List.from(_allUsers);
        _totalUsers = _filteredUsers.length;
        _userDataSource = UserDataSource(_paginatedData, this);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading users: $e');
    }
  }

  // Search users by email
  Future<void> _searchUsers(String email) async {
    setState(() {
      _isLoading = true;
      _searchEmail = email;
    });

    try {
      if (email.isEmpty) {
        // If search is empty, reset to all users
        setState(() {
          _filteredUsers = List.from(_allUsers);
          _currentPage = 0; // Reset to first page
          _userDataSource = UserDataSource(_paginatedData, this);
          _isLoading = false;
        });
      } else {
        // Filter locally first for quick feedback
        final localFiltered = _allUsers.where(
          (user) => user.email?.toLowerCase().contains(email.toLowerCase()) ?? false
        ).toList();
        
        setState(() {
          _filteredUsers = localFiltered;
          _currentPage = 0; // Reset to first page
          _userDataSource = UserDataSource(_paginatedData, this);
          _isLoading = false;
        });
        
        // If the email is very specific, try to fetch exact match from server
        if (email.contains('@')) {
          final user = await _adminUserService.getUserByEmail(email);
          if (user != null && user.role == 'khach_hang') {
            setState(() {
              _filteredUsers = [user];
              _userDataSource = UserDataSource(_paginatedData, this);
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error searching users: $e');
    }
  }

  // Show dialog to edit user
  void _showEditDialog(UserDTO user) {
    final TextEditingController nameController = TextEditingController(
      text: user.fullName,
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Chỉnh sửa thông tin',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Họ tên',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              // Display email but make it read-only
              TextField(
                controller: TextEditingController(text: user.email),
                readOnly: true,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Email (không thể chỉnh sửa)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng nhập họ tên'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      Navigator.pop(context);
                      
                      // Show loading indicator
                      setState(() {
                        _isLoading = true;
                      });
                      
                      // Update user with service
                      try {
                        final updatedUser = await _adminUserService.updateUser(
                          user.id!, 
                          {'fullName': nameController.text.trim()}
                        );
                        
                        if (updatedUser != null) {
                          // Update local data
                          setState(() {
                            final index = _allUsers.indexWhere((u) => u.id == user.id);
                            if (index != -1) {
                              _allUsers[index] = updatedUser;
                            }
                            
                            final filteredIndex = _filteredUsers.indexWhere((u) => u.id == user.id);
                            if (filteredIndex != -1) {
                              _filteredUsers[filteredIndex] = updatedUser;
                            }
                            
                            _userDataSource = UserDataSource(_paginatedData, this);
                            _isLoading = false;
                          });
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cập nhật thành công'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          setState(() {
                            _isLoading = false;
                          });
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Không thể cập nhật người dùng'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() {
                          _isLoading = false;
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Lỗi: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      backgroundColor: Colors.purple,
                    ),
                    child: const Text(
                      'Lưu thay đổi',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Toggle user status (lock/unlock)
  void _toggleUserStatus(UserDTO user) {
    final bool willLock = user.status == 'kich_hoat';
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    willLock ? Icons.lock : Icons.lock_open,
                    size: 24,
                    color: willLock ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    willLock
                        ? 'Xác nhận khóa tài khoản'
                        : 'Xác nhận kích hoạt tài khoản',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                willLock
                    ? 'Bạn có chắc chắn muốn khóa tài khoản của ${user.fullName}?'
                    : 'Bạn có chắc chắn muốn kích hoạt tài khoản của ${user.fullName}?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      
                      // Show loading indicator
                      setState(() {
                        _isLoading = true;
                      });
                      
                      try {
                        final newStatus = willLock ? 'khoa' : 'kich_hoat';
                        final updatedUser = await _adminUserService.updateUser(
                          user.id!,
                          {'status': newStatus}
                        );
                        
                        if (updatedUser != null) {
                          // Update local data
                          setState(() {
                            final index = _allUsers.indexWhere((u) => u.id == user.id);
                            if (index != -1) {
                              _allUsers[index] = updatedUser;
                            }
                            
                            final filteredIndex = _filteredUsers.indexWhere((u) => u.id == user.id);
                            if (filteredIndex != -1) {
                              _filteredUsers[filteredIndex] = updatedUser;
                            }
                            
                            _userDataSource = UserDataSource(_paginatedData, this);
                            _isLoading = false;
                          });
                          
                          // Show confirmation
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                willLock
                                    ? 'Đã khóa tài khoản của ${user.fullName}'
                                    : 'Đã kích hoạt tài khoản của ${user.fullName}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: willLock ? Colors.red : Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else {
                          setState(() {
                            _isLoading = false;
                          });
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Không thể cập nhật trạng thái người dùng'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() {
                          _isLoading = false;
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Lỗi: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: willLock ? Colors.red : Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      willLock ? 'Khóa tài khoản' : 'Kích hoạt tài khoản',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  late UserDataSource _userDataSource;

  @override
  Widget build(BuildContext context) {
    final double availableWidth = MediaQuery.of(context).size.width - 2 * 16.0;

    return Scaffold(
      body: _buildSmallScreenLayout(availableWidth),
    );
  }

  // Layout for small screens
  Widget _buildSmallScreenLayout(double availableWidth) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Page title
            const Text(
              'Quản lý người dùng',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Search and filter area
            SizedBox(
              width: availableWidth,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Search TextField
                  SizedBox(
                    width: 250,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Tìm kiếm theo email...',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        isDense: true,
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        _searchUsers(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Header for table section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Danh sách người dùng',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (_searchEmail.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchEmail = '';
                      });
                      _searchUsers('');
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Xóa tìm kiếm'),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Remove the inline loading indicator and only keep the content
            if (!_isLoading && _filteredUsers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Không tìm thấy người dùng nào',
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ),
              )
            else if (!_isLoading) // Only show list if not loading
              // User list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _paginatedData.length,
                itemBuilder: (context, index) {
                  final user = _paginatedData[index];
                  return Column(
                    children: [
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // User avatar
                              user.avatar != null && user.avatar!.isNotEmpty
                                  ? FutureBuilder<Uint8List?>(
                                      future: _adminUserService.getImageFromServer(user.avatar),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return CircleAvatar(
                                            radius: 20,
                                            backgroundColor: Colors.grey.shade200,
                                            child: SizedBox(
                                              width: 15,
                                              height: 15,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          );
                                        } else if (snapshot.hasError || snapshot.data == null) {
                                          return CircleAvatar(
                                            radius: 20,
                                            backgroundColor: Colors.grey.shade200,
                                            child: Icon(Icons.broken_image, color: Colors.grey),
                                          );
                                        } else {
                                          return CircleAvatar(
                                            radius: 20,
                                            backgroundColor: Colors.grey.shade200,
                                            backgroundImage: MemoryImage(snapshot.data!),
                                          );
                                        }
                                      },
                                    )
                                  : CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.grey.shade200,
                                      child: Icon(Icons.person, color: Colors.grey),
                                    ),
                              
                              const SizedBox(width: 12),
                              
                              // User information
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      user.fullName ?? 'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.email ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: user.status == 'kich_hoat'
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        user.status == 'kich_hoat'
                                            ? 'Đã kích hoạt'
                                            : 'Đã khóa',
                                        style: TextStyle(
                                          color: user.status == 'kich_hoat'
                                              ? Colors.green
                                              : Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Action buttons
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => _showEditDialog(user),
                                    icon: const Icon(Icons.edit, size: 18),
                                    tooltip: 'Chỉnh sửa',
                                    constraints: const BoxConstraints(
                                        minWidth: 36, minHeight: 36),
                                    padding: EdgeInsets.zero,
                                  ),
                                  IconButton(
                                    onPressed: () => _toggleUserStatus(user),
                                    icon: Icon(
                                      user.status == 'kich_hoat'
                                          ? Icons.lock
                                          : Icons.lock_open,
                                      size: 18,
                                      color: user.status == 'kich_hoat'
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                    tooltip: user.status == 'kich_hoat'
                                        ? 'Khóa tài khoản'
                                        : 'Kích hoạt tài khoản',
                                    constraints: const BoxConstraints(
                                        minWidth: 36, minHeight: 36),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (index < _paginatedData.length - 1)
                        const Divider(height: 1, thickness: 0.5),
                    ],
                  );
                },
              ),

            // Pagination controls
            if (_filteredUsers.isNotEmpty && !_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Pagination info
                    Text(
                      'Hiển thị ${_paginatedData.isEmpty ? 0 : (_currentPage * _rowsPerPage) + 1} - ${(_currentPage * _rowsPerPage) + _paginatedData.length} trên ${_filteredUsers.length}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),

                    // Pagination controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_left),
                          onPressed: _currentPage > 0
                              ? () {
                                  setState(() {
                                    _currentPage--;
                                  });
                                }
                              : null,
                          tooltip: 'Trang trước',
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            '${_currentPage + 1} / ${_pageCount > 0 ? _pageCount : 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_right),
                          onPressed: _currentPage < _pageCount - 1
                              ? () {
                                  setState(() {
                                    _currentPage++;
                                  });
                                }
                              : null,
                          tooltip: 'Trang tiếp',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
        
        // Loading overlay without background color
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}

class UserDataSource extends DataTableSource {
  final List<UserDTO> _data;
  final _UserScreenState _state;

  UserDataSource(this._data, this._state);

  @override
  DataRow? getRow(int index) {
    if (index >= _data.length) {
      return null;
    }
    final user = _data[index];
    return DataRow(cells: [
      DataCell(Text(user.fullName ?? 'Unknown')),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: user.status == 'kich_hoat'
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            user.status == 'kich_hoat' ? 'Đã kích hoạt' : 'Đã khóa',
            style: TextStyle(
              color:
                  user.status == 'kich_hoat' ? Colors.green : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _state._showEditDialog(user),
              icon: const Icon(Icons.edit),
              tooltip: 'Chỉnh sửa',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            IconButton(
              onPressed: () => _state._toggleUserStatus(user),
              icon: Icon(
                user.status == 'kich_hoat'
                    ? Icons.lock
                    : Icons.lock_open,
                color: user.status == 'kich_hoat'
                    ? Colors.red
                    : Colors.green,
              ),
              tooltip: user.status == 'kich_hoat'
                  ? 'Khóa tài khoản'
                  : 'Kích hoạt tài khoản',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ],
        ),
      ),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _data.length;

  @override
  int get selectedRowCount => 0;
}
