import 'package:flutter/material.dart';

class GenderSelect extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final String initialValue;

  const GenderSelect({
    Key? key,
    this.initialValue = "male",
    this.onChanged,
  }) : super(key: key);

  @override
  State<GenderSelect> createState() => _GenderSelectState();
}

class _GenderSelectState extends State<GenderSelect> {
  late String _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Giới tính",
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedValue,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: "male",
                  child: Text("Nam"),
                ),
                DropdownMenuItem(
                  value: "female",
                  child: Text("Nữ"),
                ),
                DropdownMenuItem(
                  value: "other",
                  child: Text("Khác"),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedValue = value;
                  });
                  if (widget.onChanged != null) {
                    widget.onChanged!(value);
                  }
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
