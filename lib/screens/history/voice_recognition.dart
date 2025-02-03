import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../utils/text_processing.dart';
import '../../models/expense.dart';
// import '../../utils/expense_nlp_service.dart';
// import 'package:nlp/nlp.dart';

class VoiceRecognitionScreen extends StatefulWidget {
  final bool isEditing;
  final Expense? existingExpense;

  const VoiceRecognitionScreen({
    super.key,
    this.isEditing = false,
    this.existingExpense,
  });

  @override
  State<VoiceRecognitionScreen> createState() => _VoiceRecognitionScreenState();
}

class _VoiceRecognitionScreenState extends State<VoiceRecognitionScreen> {
  final SpeechToText _speechToText = SpeechToText();
  // final ExpenseNLPService _nlpService = ExpenseNLPService();

  bool _isListening = false;
  String _recognizedText = '';
  Map<String, String>? _extractedData;
  bool _speechEnabled = false;
  bool _isProcessing = false;
  // Map<String, dynamic>? _nlpResults;

  // Add controllers for the text fields
  TextEditingController amountController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  TextEditingController dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initSpeech();

    // Pre-fill data if editing
    if (widget.isEditing && widget.existingExpense != null) {
      _recognizedText = widget.existingExpense!.note ?? '';
      _extractedData = {
        "amount": widget.existingExpense!.amount.toString(),
        "category": widget.existingExpense!.category,
        "date": widget.existingExpense!.date
            .toString()
            .split(' ')[0], // Only take the date part
      };
    }
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) {
        if (!mounted) return;
        print('Speech status: $status');

        // Don't stop immediately on 'notListening' status
        if (status == 'done') {
          setState(() => _isListening = false);
          if (_recognizedText.isNotEmpty) {
            _processText(_recognizedText);
          }
        }
      },
      onError: (errorNotification) {
        if (!mounted) return;
        print('Speech error: $errorNotification');

        // Only stop listening for permanent errors
        if (errorNotification.permanent) {
          setState(() => _isListening = false);
        }

        // Don't show error for timeout or no match
        if (errorNotification.errorMsg != 'error_speech_timeout' &&
            errorNotification.errorMsg != 'error_no_match') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorNotification.errorMsg),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  void _startListening() async {
    setState(() {
      _isListening = true;
      _recognizedText = '';
    });

    await _speechToText.listen(
      onResult: (result) {
        if (result.recognizedWords != _recognizedText) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
        }
      },
      localeId: 'en_MY',
      listenFor: Duration(seconds: 60), // Longer overall duration
      pauseFor: Duration(seconds: 3), // More tolerance for pauses
      onSoundLevelChange: (level) {
        // Monitor sound levels but don't stop on brief silence
        print('Sound level: $level');
      },
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation, // Better for continuous speech
        partialResults: true,
        cancelOnError: false,
      ),
    );
  }

  void _stopListening() async {
    await _speechToText.stop();

    if (mounted) {
      setState(() {
        _isListening = false;
      });

      // Only process if we have text to process
      if (_recognizedText.isNotEmpty) {
        await _processText(_recognizedText);
      }
    }
  }

  // for reverting back to text_processing.dart

  Future<void> _processText(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Use utility methods to process text
      String correctedText = TextProcessingUtils.correctText(text);
      print('Original text: $text');
      print('Corrected text: $correctedText');

      Map<String, String> extracted = {
        "amount": TextProcessingUtils.extractAmount(correctedText) ??
            "Not recognized",
        "category": TextProcessingUtils.extractCategory(correctedText) ??
            "Not recognized",
        "date":
            TextProcessingUtils.extractDate(correctedText) ?? "Not recognized",
      };

      if (mounted) {
        setState(() {
          _extractedData = extracted;
          _isProcessing = false;

          // Initialize controllers with extracted data
          amountController.text = _extractedData?['amount'] ?? '';
          categoryController.text = _extractedData?['category'] ?? '';
          dateController.text = _extractedData?['date'] ?? '';
        });
      }

      print('Extracted data: $_extractedData');
    } catch (e) {
      print('Error processing text: $e');
      _showError('Error processing text. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

// Future<void> _processText(String text) async {
//     if (text.isEmpty) return;

//     setState(() {
//       _isProcessing = true;
//     });

//     try {
//       // Process text using NLP service
//       final results = await _nlpService.processText(text);

//       if (results['error'] != null) {
//         _showError(results['error']);
//         return;
//       }

//       // Extract the recognized data
//       Map<String, String> extracted = {
//         "amount": results['amount']['value']?.toString() ?? "Not recognized",
//         "category": results['category']['value']?.toString() ?? "Not recognized",
//         "date": results['date']['value']?.toString().split(' ')[0] ?? "Not recognized",
//       };

//       if (mounted) {
//         setState(() {
//           _extractedData = extracted;
//           _nlpResults = results;
//           _isProcessing = false;

//           // Update controllers
//           amountController.text = results['amount']['value']?.toString() ?? '';
//           categoryController.text = results['category']['value']?.toString() ?? '';
//           dateController.text = results['date']['value']?.toString().split(' ')[0] ?? '';
//         });
//       }

//       print('Processed data: $results');
//       print('Extracted data: $_extractedData');

//     } catch (e) {
//       print('Error processing text: $e');
//       _showError('Error processing text. Please try again.');
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isProcessing = false;
//         });
//       }
//     }
//   }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    widget.isEditing ? 'Edit Voice Input' : 'Voice Input',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.isEditing)
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Expense'),
                              content: const Text(
                                  'Are you sure you want to delete this voice expense?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.pop(context, 'delete');
                                  },
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onLongPressStart: (_) =>
                            _speechEnabled ? _startListening() : null,
                        onLongPressEnd: (_) => _stopListening(),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening
                                ? Colors.green.withOpacity(0.1)
                                : Colors.white,
                            border: Border.all(
                              color: _isListening
                                  ? Colors.green.shade300
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.mic,
                            size: 30,
                            color: _isListening ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isListening)
                        const Text(
                          'Keep holding to continue speaking...',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        )
                      else if (_recognizedText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _recognizedText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        )
                      else
                        const Text(
                          'Press and hold to speak\n"Today I spent RM50 on food"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      if (_extractedData != null || _isProcessing) ...[
                        const SizedBox(height: 20),
                        _buildExtractedDataDisplay(),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(width: 32),
                  TextButton(
                    onPressed: _extractedData != null
                        ? () {
                            if (_extractedData!['amount'] != 'Not recognized' &&
                                _extractedData!['category'] !=
                                    'Not recognized') {
                              final String amountStr =
                                  _extractedData!['amount']!
                                      .replaceAll('RM', '')
                                      .replaceAll(',', '');

                              try {
                                final double amount = double.parse(amountStr);

                                // Parse the date from extracted data
                                DateTime expenseDate;
                                if (_extractedData!['date'] != null &&
                                    _extractedData!['date'] !=
                                        "Not recognized") {
                                  List<String> dateParts =
                                      _extractedData!['date']!.split('/');
                                  expenseDate = DateTime(
                                    int.parse(dateParts[2]), // year
                                    int.parse(dateParts[1]), // month
                                    int.parse(dateParts[0]), // day
                                    widget.existingExpense?.date.hour ??
                                        DateTime.now().hour,
                                    widget.existingExpense?.date.minute ??
                                        DateTime.now().minute,
                                  );
                                } else {
                                  expenseDate = widget.existingExpense?.date ??
                                      DateTime.now();
                                }

                                final expense = Expense(
                                  id: widget.existingExpense
                                      ?.id, // Pass the existing ID if editing
                                  amount: amount,
                                  category: TextProcessingUtils.toTitleCase(
                                      _extractedData!['category']!),
                                  date: expenseDate,
                                  note: _recognizedText,
                                  isVoiceInput: true,
                                );

                                Navigator.pop(context, expense);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invalid amount format'),
                                    behavior: SnackBarBehavior.floating,
                                    margin: EdgeInsets.only(
                                      bottom: 80,
                                      left: 16,
                                      right: 16,
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    child: Text(
                      'Save',
                      style: TextStyle(
                        color:
                            _extractedData != null ? Colors.green : Colors.grey,
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExtractedDataDisplay() {
    if (_isProcessing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            '1. Expense: ${_extractedData?['amount'] != null && _extractedData!['amount'] != "Not recognized" ? 'RM${_extractedData!['amount']}' : 'Not recognized'}',
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
          Text(
            '2. Category: ${_extractedData?['category'] != null && _extractedData!['category'] != "Not recognized" ? _extractedData!['category']! : 'Not recognized'}',
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
          Text(
            '3. Date: ${_extractedData?['date'] != null && _extractedData!['date'] != "Not recognized" ? _extractedData!['date']!.split(' ')[0] // Only show the date part
                : 'Not recognized'}',
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Dispose of the controllers
    amountController.dispose();
    categoryController.dispose();
    dateController.dispose();

    _speechToText.cancel();
    super.dispose();
  }
}
