import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class AdministrativeDropdown extends StatefulWidget {
  @override
  _AdministrativeDropdownState createState() => _AdministrativeDropdownState();
}

class _AdministrativeDropdownState extends State<AdministrativeDropdown> {
  List<dynamic> provinces = [];
  Map<String, dynamic>? selectedProvince;
  Map<String, dynamic>? selectedDistrict;
  Map<String, dynamic>? selectedWard;
  TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadAdministrativeData();
  }

  Future<void> loadAdministrativeData() async {
    try {
      String jsonString =
          await rootBundle.loadString('assets/vietnam_locations.json');
      final data = json.decode(jsonString);

      setState(() {
        provinces = data;
        textController.text = "Chọn địa chỉ";
      });
    } catch (e) {
      print("Error loading JSON: $e");
      setState(() {
        textController.text = "Error loading data";
      });
    }
  }

  void _showDropdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              ListTile(
                title: Text('Chọn Tỉnh/Thành phố'),
                onTap: () {
                  Navigator.pop(context);
                  _showProvinceSelection(context);
                },
              ),
              ListTile(
                title: Text('Chọn Quận/Huyện'),
                enabled: selectedProvince != null,
                onTap: () {
                  Navigator.pop(context);
                  _showDistrictSelection(context);
                },
              ),
              ListTile(
                title: Text('Chọn Phường/Xã'),
                enabled: selectedDistrict != null,
                onTap: () {
                  Navigator.pop(context);
                  _showWardSelection(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProvinceSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return provinces.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: provinces.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(provinces[index]['Name']),
                    onTap: () {
                      setState(() {
                        selectedProvince = provinces[index];
                        selectedDistrict = null;
                        selectedWard = null;
                        textController.text = selectedProvince!['Name'];
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              );
      },
    );
  }

  void _showDistrictSelection(BuildContext context) {
    if (selectedProvince == null) return;

    var districts = selectedProvince!['Districts'] ?? [];

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return districts.isEmpty
            ? Center(child: Text("No districts found."))
            : ListView.builder(
                itemCount: districts.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(districts[index]['Name']),
                    onTap: () {
                      setState(() {
                        selectedDistrict = districts[index];
                        selectedWard = null;
                        textController.text =
                            '${selectedProvince!['Name']}, ${selectedDistrict!['Name']}';
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              );
      },
    );
  }

  void _showWardSelection(BuildContext context) {
    if (selectedDistrict == null) return;

    var wards = selectedDistrict!['Wards'] ?? [];

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return wards.isEmpty
            ? Center(child: Text("No wards found."))
            : ListView.builder(
                itemCount: wards.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(wards[index]['Name']),
                    onTap: () {
                      setState(() {
                        selectedWard = wards[index];
                        textController.text =
                            '${selectedProvince!['Name']}, ${selectedDistrict!['Name']}, ${selectedWard!['Name']}';
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: textController,
        readOnly: true,
        onTap: () => _showDropdown(context),
        decoration: InputDecoration(
          labelText: selectedProvince == null
              ? "Chọn địa chỉ"
              : "${selectedProvince!['Name']}, ${selectedDistrict?['Name'] ?? ''}",
          suffixIcon: Icon(Icons.arrow_drop_down),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
