//demo
//demo

class Ex6 extends StatelessWidget {
  final int currentScreen;
  final int totalScreen;

  const Ex6({
    super.key,
    required this.currentScreen,
    required this.totalScreen,
  });

  // Method to navigate back to a specific screen number
  void _navigateToScreen(BuildContext context, int targetScreenNumber) {
    Navigator.popUntil(context, (route) {
      // Check if the route we are checking is the target screen.
      // We identify routes by the screen number passed as arguments.
      return route.settings.arguments == targetScreenNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Multi-Screen App ($currentScreen/$totalScreen)'),
        // Automatically handles back navigation for pushed screens
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '$currentScreen',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 150),
            ),
            const SizedBox(height: 30),
            // Show grid only from screen 2 onwards
            if (currentScreen > 1)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 3 columns
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.5, // Adjust aspect ratio for button shape
                    ),
                    itemCount: totalScreen,
                    itemBuilder: (context, index) {
                      final screenNumber = index + 1;
                      final bool isActive = screenNumber != currentScreen;

                      return ElevatedButton(
                        // Disable button for the current screen
                        onPressed: isActive
                            ? () => _navigateToScreen(context, screenNumber)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive ? Colors.blue : Colors.grey,
                        ),
                        child: Text('$screenNumber'),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: currentScreen < totalScreen
          ? FloatingActionButton(
              onPressed: () {
                // Navigate to the next screen, passing the incremented number
                // Also pass the screen number as arguments for popUntil identification
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Ex1(
                      currentScreen: currentScreen + 1,
                      totalScreen: totalScreen,
                    ),
                    // Setting arguments helps identify the route in popUntil
                    settings: RouteSettings(arguments: currentScreen + 1),
                  ),
                );
              },
              child: const Icon(Icons.arrow_forward_ios),
            )
          : null, // No FAB on the last screen
    );
  }
}
