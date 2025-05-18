import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemChrome
import 'package:model_viewer_plus/model_viewer_plus.dart';

class GlbScreen extends StatefulWidget {
  const GlbScreen({super.key});

  @override
  State<GlbScreen> createState() => _GlbScreenState();
}

class _GlbScreenState extends State<GlbScreen> {
  final List<String> _modelPaths = ['assets/one.glb', 'assets/two.glb'];

  final List<String> _modelLabels = ['First Trimester', 'Second Trimester'];

  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // For a truly immersive experience, hide status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Restore system UI when exiting the screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.grey.shade800, // Dark grey background for immersion
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _modelPaths.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ModelViewer(
                    key: ValueKey(
                      _modelPaths[index],
                    ), // Important for updating viewer
                    src: _modelPaths[index],
                    alt: "A 3D model of ${_modelPaths[index].split('/').last}",
                    ar: false, // Disable AR for this specific immersive view, can be true if desired
                    autoRotate: true,
                    autoRotateDelay: 0, // Start rotation immediately
                    cameraControls: true, // Allow user to control camera
                    disableZoom: false, // Allow zoom
                    backgroundColor:
                        Colors
                            .transparent, // Transparent background for ModelViewer
                  ),
                  // Label overlay
                  Positioned(
                    top: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _modelLabels[index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Navigation Arrows
          if (_currentPage > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () {
                  _goToPage(_currentPage - 1);
                },
                tooltip: 'Previous Model',
              ),
            ),
          if (_currentPage < _modelPaths.length - 1)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () {
                  _goToPage(_currentPage + 1);
                },
                tooltip: 'Next Model',
              ),
            ),
          // Optional: Page indicator
          if (_modelPaths.length > 1)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_modelPaths.length, (index) {
                    return Container(
                      width: 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _currentPage == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                      ),
                    );
                  }),
                ),
              ),
            ),
          // Optional: Close button for immersive mode
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () {
                Navigator.of(context).pop();
              },
              tooltip: 'Close',
            ),
          ),
        ],
      ),
    );
  }
}
