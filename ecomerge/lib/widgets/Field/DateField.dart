// Chuyển đổi trường ngày tháng thành StatefulWidget
import 'package:flutter/material.dart';

class DateField extends StatefulWidget {
  final String label;
  final String initialValue;
  final ValueChanged<String>? onChanged;

  const DateField({
    Key? key,
    required this.label,
    required this.initialValue,
    this.onChanged,
  }) : super(key: key);

  @override
  State<DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<DateField> {
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? initialDate;
    try {
      List<String> parts = widget.initialValue.split('/');
      if (parts.length == 3) {
        initialDate = DateTime(
          int.parse(parts[2]), // năm
          int.parse(parts[1]), // tháng
          int.parse(parts[0]), // ngày
        );
      }
    } catch (e) {
      initialDate = null;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: ColorScheme.light(primary: Colors.blue),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      String formattedDate =
          "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      setState(() {
        _dateController.text = formattedDate;
      });

      if (widget.onChanged != null) {
        widget.onChanged!(formattedDate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _dateController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _selectDate(context),
            ),
          ),
          readOnly: true,
          onTap: () => _selectDate(context),
        ),
      ],
    );
  }
}
