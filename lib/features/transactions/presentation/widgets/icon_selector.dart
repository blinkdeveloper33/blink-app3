import 'package:flutter/material.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;

class IconSelector extends StatefulWidget {
  final IconData initialIcon;
  final Function(IconData) onIconSelected;
  final bool isDarkMode;

  const IconSelector({
    Key? key,
    required this.initialIcon,
    required this.onIconSelected,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<IconSelector> createState() => _IconSelectorState();
}

class _IconSelectorState extends State<IconSelector>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late IconData _selectedIcon;

  // Categorized icons
  final Map<String, List<IconData>> _categorizedIcons = {
    'Finance': [
      Icons.account_balance_wallet,
      Icons.credit_card,
      Icons.attach_money,
      Icons.savings,
      Icons.currency_exchange,
      Icons.payment,
      Icons.receipt_long,
      Icons.account_balance,
      Icons.trending_up,
      Icons.price_check,
      Icons.money_off,
      Icons.currency_bitcoin,
    ],
    'Shopping': [
      Icons.shopping_bag,
      Icons.shopping_cart,
      Icons.store,
      Icons.local_mall,
      Icons.shopping_basket,
      Icons.storefront,
      Icons.local_offer,
      Icons.redeem,
      Icons.loyalty,
      Icons.sell,
      Icons.receipt,
      Icons.inventory_2,
    ],
    'Food': [
      Icons.restaurant,
      Icons.fastfood,
      Icons.local_cafe,
      Icons.local_bar,
      Icons.local_pizza,
      Icons.bakery_dining,
      Icons.lunch_dining,
      Icons.dinner_dining,
      Icons.coffee,
      Icons.local_dining,
      Icons.restaurant_menu,
      Icons.food_bank,
    ],
    'Transport': [
      Icons.directions_car,
      Icons.local_taxi,
      Icons.directions_bus,
      Icons.train,
      Icons.flight,
      Icons.directions_bike,
      Icons.electric_scooter,
      Icons.local_shipping,
      Icons.motorcycle,
      Icons.electric_car,
      Icons.pedal_bike,
      Icons.subway,
    ],
    'Lifestyle': [
      Icons.movie,
      Icons.sports_esports,
      Icons.fitness_center,
      Icons.spa,
      Icons.sports,
      Icons.theater_comedy,
      Icons.music_note,
      Icons.local_activity,
      Icons.sports_basketball,
      Icons.park,
      Icons.beach_access,
      Icons.pool,
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.initialIcon;
    _tabController = TabController(
      length: _categorizedIcons.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleIconTap(IconData icon) {
    haptics.Haptics.vibrate(haptics.HapticsType.light);
    setState(() {
      _selectedIcon = icon;
    });
    widget.onIconSelected(icon);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: widget.isDarkMode ? Colors.white : Colors.blue,
            unselectedLabelColor:
                widget.isDarkMode ? Colors.white60 : Colors.black54,
            indicatorColor: widget.isDarkMode ? Colors.white : Colors.blue,
            tabs: _categorizedIcons.keys
                .map((category) => Tab(text: category))
                .toList(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categorizedIcons.entries.map((entry) {
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: entry.value.length,
                  itemBuilder: (context, index) {
                    final icon = entry.value[index];
                    final isSelected =
                        _selectedIcon.codePoint == icon.codePoint;

                    return GestureDetector(
                      onTap: () => _handleIconTap(icon),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (widget.isDarkMode
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.blue.withOpacity(0.1))
                              : (widget.isDarkMode
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? (widget.isDarkMode
                                    ? Colors.white
                                    : Colors.blue)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected
                              ? (widget.isDarkMode ? Colors.white : Colors.blue)
                              : (widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54),
                          size: 28,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
