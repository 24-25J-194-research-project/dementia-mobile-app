import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../Components/user_avatar.dart';
import '../../Services/Cognitive_Training/memory_card_service.dart';

// Define difficulty levels
enum DifficultyLevel {
  easy,
  medium,
  hard
}

class MemoryCardGamePage extends StatefulWidget {
  final List<Map<String, String>>? cardData;

  const MemoryCardGamePage({
    super.key,
    this.cardData,
  });

  @override
  State<MemoryCardGamePage> createState() => _MemoryCardGamePageState();
}

class _MemoryCardGamePageState extends State<MemoryCardGamePage> {
  final List<Map<String, dynamic>> _cards = [];
  List<int> _flippedCardIndexes = [];
  List<int> _matchedCardIndexes = [];
  int _score = 100;
  int _attempts = 0;
  bool _isProcessing = false;
  bool _imagesLoaded = false;
  bool _isLoading = true;
  int _loadedImagesCount = 0;
  DifficultyLevel _difficultyLevel = DifficultyLevel.easy;
  List<Map<String, String>> _cardData = [];
  
  @override
  void initState() {
    super.initState();
    _loadCardData();
  }

  Future<void> _loadCardData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (widget.cardData != null && widget.cardData!.isNotEmpty) {
        // Use card data provided as a parameter (for newly uploaded cards)
        _cardData = widget.cardData!;
      } else {
        // Fetch card data from Supabase database
        final apiService = ApiService();
        _cardData = await apiService.fetchMemoryCards();
      }
      
      // Initialize the game with the loaded card data
      _initializeGame();
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading memory cards: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int get _getPairsCount {
    switch (_difficultyLevel) {
      case DifficultyLevel.easy:
        return 3;
      case DifficultyLevel.medium:
        return 4;
      case DifficultyLevel.hard:
        return 5;
    }
  }

  void _changeDifficulty(DifficultyLevel level) {
    if (_difficultyLevel != level) {
      setState(() {
        _difficultyLevel = level;
        _resetGame();
      });
    }
  }

  void _initializeGame() {
    // Reset activity state
    _flippedCardIndexes = [];
    _matchedCardIndexes = [];
    _score = 100;
    _attempts = 0;
    _imagesLoaded = false;
    _loadedImagesCount = 0;
    
    // Generate card pairs
    _cards.clear();

    // Check if we have any cards to use
    if (_cardData.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No memory cards available. Please upload some cards first.')),
        );
      }
      return;
    }

    // Determine number of pairs based on difficulty level
    final pairsCount = _getPairsCount;
    
    // Make sure we don't exceed available cards
    final maxPairs = _cardData.length;
    final actualPairsCount = min(pairsCount, maxPairs);
    
    // Randomly select cards if we have more available than needed
    List<Map<String, String>> selectedCards = _cardData;
    if (_cardData.length > actualPairsCount) {
      selectedCards = List.from(_cardData)..shuffle();
      selectedCards = selectedCards.take(actualPairsCount).toList();
    }
    
    // For each card data, create two cards with same id
    for (var i = 0; i < actualPairsCount; i++) {
      final cardData = selectedCards[i];
      
      // Create two identical cards
      _cards.add({
        'id': i,
        'imageUrl': cardData['image_url'],
        'text': cardData['text'],
        'isLoaded': false,
      });
      
      _cards.add({
        'id': i,
        'imageUrl': cardData['image_url'],
        'text': cardData['text'],
        'isLoaded': false,
      });
    }
    
    // Shuffle the cards for UI
    _cards.shuffle(Random());
    
    // Preload all images before starting the activity
    _preloadImages();
  }

  void _flipCard(int index) {
    // Do not allow more than 2 cards flipped at once or if already processing
    if (_flippedCardIndexes.length >= 2 || _isProcessing) return;
    
    // Do not flip already matched cards
    if (_matchedCardIndexes.contains(index)) return;
    
    // Do not flip already flipped card
    if (_flippedCardIndexes.contains(index)) return;
    
    setState(() {
      _flippedCardIndexes.add(index);
    });
    
    // If we have 2 cards flipped, check for match
    if (_flippedCardIndexes.length == 2) {
      _isProcessing = true;
      _attempts++;
      
      // Check if the cards match
      final card1 = _cards[_flippedCardIndexes[0]];
      final card2 = _cards[_flippedCardIndexes[1]];
      
      if (card1['id'] == card2['id']) {
        // Match found
        setState(() {
          _matchedCardIndexes.addAll(_flippedCardIndexes);
          _flippedCardIndexes = [];
          _isProcessing = false;
        });
        
        // Check if game is complete
        if (_matchedCardIndexes.length == _cards.length) {
          // Game over -> show congratulations
          _showGameCompleteDialog();
        }
      } else {
        // No match, flip back after delay
        setState(() {
          // Deduct points for wrong attempt
          _score = max(0, _score - 5);
        });
        
        // Wait before flipping back
        Timer(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _flippedCardIndexes = [];
              _isProcessing = false;
            });
          }
        });
      }
    }
  }

  void _showGameCompleteDialog() async {
    // Save history to API
    final apiService = ApiService();
    String difficultyString = '';
    
    // Convert enum to string
    switch (_difficultyLevel) {
      case DifficultyLevel.easy:
        difficultyString = 'easy';
        break;
      case DifficultyLevel.medium:
        difficultyString = 'medium';
        break;
      case DifficultyLevel.hard:
        difficultyString = 'hard';
        break;
    }
    
    final success = await apiService.saveMemoryCardHistory(
      level: difficultyString,
      attempts: _attempts,
    );
    
    // Show dialog with status
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Congratulations!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('You completed the memory card activity!'),
              const SizedBox(height: 8),
              Text('Attempts: $_attempts'),
              if (!success) ...[
                const SizedBox(height: 8),
                const Text(
                  'Note: Could not save your progress.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              child: const Text('Play Again'),
            ),
          ],
        ),
      );
    }
  }

  void _resetGame() {
    setState(() {
      _initializeGame();
    });
  }

  // Function to preload all images before starting the activity
  void _preloadImages() {
    final Set<String> uniqueUrls = {};
    
    // Collect unique image URLs to avoid loading duplicates
    for (var card in _cards) {
      uniqueUrls.add(card['imageUrl']);
    }
    
    final totalImagesToLoad = uniqueUrls.length;
    int loadedCount = 0;
    
    // Preload each unique image
    for (String url in uniqueUrls) {
      final imageProvider = NetworkImage(url);
      final imageStream = imageProvider.resolve(const ImageConfiguration());
      
      late final ImageStreamListener listener;
      
      listener = ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          // Mark all cards with this URL as loaded
          for (var card in _cards) {
            if (card['imageUrl'] == url) {
              card['isLoaded'] = true;
            }
          }
          
          loadedCount++;
          setState(() {
            _loadedImagesCount = loadedCount;
          });
          
          if (loadedCount >= totalImagesToLoad) {
            setState(() {
              _imagesLoaded = true;
            });
          }
          
          imageStream.removeListener(listener);
        },
        onError: (exception, stackTrace) {
          // Handle loading errors
          loadedCount++;
          
          if (loadedCount >= totalImagesToLoad) {
            setState(() {
              _imagesLoaded = true;
            });
          }
          
          imageStream.removeListener(listener);
        },
      );
      
      imageStream.addListener(listener);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Memory Card'),
          centerTitle: true,
          backgroundColor: Colors.white,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue[100]!, Colors.blue[50]!],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading memory cards...'),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Card'),
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: UserAvatar(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[100]!, Colors.blue[50]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Stats row
              if (_imagesLoaded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Difficulty
                      Row(
                        children: [
                          const Icon(Icons.speed, size: 18, color: Colors.blue),
                          const SizedBox(width: 6),
                          DropdownButton<DifficultyLevel>(
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(16), 
                            itemHeight: 50,
                            style: const TextStyle(
                              color: Colors.black, // Text color
                              fontSize: 16,
                            ),
                            value: _difficultyLevel,
                            underline: const SizedBox(),
                            isDense: true,
                            hint: const Text("Cards"),
                            onChanged: (value) {
                              if (value != null) _changeDifficulty(value);
                            },
                            items: const [
                              DropdownMenuItem(
                                value: DifficultyLevel.easy,
                                child: Text("6 Cards"),
                              ),
                              DropdownMenuItem(
                                value: DifficultyLevel.medium,
                                child: Text("8 Cards"),
                              ),
                              DropdownMenuItem(
                                value: DifficultyLevel.hard,
                                child: Text("10 Cards"),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      //separator
                      Container(
                        height: 24,
                        width: 1,
                        color: Colors.grey.withOpacity(0.3),
                      ),
                      
                      //attempts counter
                      Row(
                        children: [
                          const Icon(Icons.compare_arrows, size: 18, color: Colors.blue),
                          const SizedBox(width: 6),
                          Text(
                            '$_attempts',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      
                      // Score counter
                      // Row(
                      //   children: [
                      //     const Icon(Icons.stars, size: 18, color: Colors.amber),
                      //     const SizedBox(width: 6),
                      //     Text(
                      //       '$_score',
                      //       style: const TextStyle(
                      //         fontWeight: FontWeight.bold,
                      //         fontSize: 14,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
                
              const SizedBox(height: 16),
              
              if (!_imagesLoaded && !_isLoading)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        Text(
                          'Loading images (${_loadedImagesCount}/${_getPairsCount})...',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_cards.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No memory cards available. Please upload some cards first.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _cards.length,
                    itemBuilder: (context, index) {
                      final isFlipped = _flippedCardIndexes.contains(index) || 
                                        _matchedCardIndexes.contains(index);
                      return _buildCard(index, isFlipped);
                    },
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _imagesLoaded ? _resetGame : null,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.blue.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(int index, bool isFlipped) {
    return GestureDetector(
      onTap: _imagesLoaded ? () => _flipCard(index) : null,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _matchedCardIndexes.contains(index) ? Colors.green : Colors.blue,
            width: 2,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isFlipped
              ? Column(
                  key: ValueKey('flipped_$index'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Text(
                        _cards[index]['text'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _cards[index]['imageUrl'],
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.error, color: Colors.red, size: 40),
                              );
                            },
                          ),
                        ),
                      ),
                    )
                  ],
                )
              : Container(
                  key: ValueKey('unflipped_$index'),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.question_mark,
                      size: 50,
                      color: Colors.blue,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}