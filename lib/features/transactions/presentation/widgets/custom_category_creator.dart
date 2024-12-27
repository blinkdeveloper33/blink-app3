import 'package:flutter/material.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;
import 'package:blink_app/features/transactions/domain/models/transaction_category.dart';
import 'color_palette_picker.dart';
import 'icon_selector.dart';

class CustomCategoryCreator extends StatefulWidget {
  final Function(TransactionCategory) onCategoryCreated;
  final bool isDarkMode;

  const CustomCategoryCreator({
    Key? key,
    required this.onCategoryCreated,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<CustomCategoryCreator> createState() => _CustomCategoryCreatorState();
}

class _CustomCategoryCreatorState extends State<CustomCategoryCreator> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Color _selectedColor = Colors.blue;
  IconData _selectedIcon = Icons.category;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleColorSelected(Color color) {
    setState(() {
      _selectedColor = color;
    });
  }

  void _handleIconSelected(IconData icon) {
    setState(() {
      _selectedIcon = icon;
    });
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      haptics.Haptics.vibrate(haptics.HapticsType.medium);
      final category = TransactionCategory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        color: _selectedColor,
        icon: _selectedIcon,
      );
      widget.onCategoryCreated(category);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Custom Category',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: 'Category Name',
                labelStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: widget.isDarkMode ? Colors.white30 : Colors.black12,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: widget.isDarkMode ? Colors.white : Colors.blue,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a category name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Choose Color',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            ColorPalettePicker(
              initialColor: _selectedColor,
              onColorSelected: _handleColorSelected,
              isDarkMode: widget.isDarkMode,
            ),
            const SizedBox(height: 24),
            Text(
              'Choose Icon',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            IconSelector(
              initialIcon: _selectedIcon,
              onIconSelected: _handleIconSelected,
              isDarkMode: widget.isDarkMode,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Create Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
