import 'dart:math';

class ExpenseNLPService {
  static final ExpenseNLPService _instance = ExpenseNLPService._internal();
  
  factory ExpenseNLPService() {
    return _instance;
  }
  
  ExpenseNLPService._internal();

  // Integrated from TextProcessingUtils
  static final Map<String, String> _commonCorrections = {
    // Numbers and amounts
    'won': 'one',
    'tu': 'two',
    'tree': 'three',
    'fore': 'four',
    'phore': 'four',
    'phy': 'five',
    'sex': 'six',
    'ate': 'eight',
    'nyne': 'nine',
    'zen': 'ten',

    // Currency-related
    'ringet': 'ringgit',
    'ringt': 'ringgit',
    'ringit': 'ringgit',
    'rm': 'ringgit',
    'sens': 'cents',
    'sen': 'cents',
  };

  // Using original categories from TextProcessingUtils
  static final Set<String> _validCategories = {
    'food',
    'drinks',
    'transport',
    'shopping',
    'entertainment',
    'housing',
    'electronics',
    'medical',
    'income',
  };

  // Additional category patterns for enhanced detection
  static final Map<String, List<String>> _categoryPatterns = {
    'food': [
      r'\b(?:meal|lunch|dinner|breakfast|snack|groceries|restaurant|food|eat|dining)\b',
      r'\b(?:mamak|kopitiam|hawker|stall|warung|kedai|makan)\b',
    ],
    'drinks': [
      r'\b(?:cafe|coffee|tea|drinks|beverage|water|juice|boba)\b',
    ],
    'transport': [
      r'\b(?:taxi|grab|bus|train|mrt|lrt|petrol|parking|toll|transport|travel)\b',
      r'\b(?:teksi|kereta|minyak|tambang)\b',
    ],
    'shopping': [
      r'\b(?:clothes|shoes|accessories|mall|store|shop|shopping|buy|purchase)\b',
      r'\b(?:pasar|kedai|beli|barang)\b',
    ],
    'entertainment': [
      r'\b(?:movie|cinema|concert|show|game|theme park|entertainment)\b',
      r'\b(?:wayang|pawagam|permainan|hiburan)\b',
    ],
    'housing': [
      r'\b(?:rent|mortgage|house|apartment|maintenance|repair)\b',
      r'\b(?:sewa|rumah|apartmen|kondominium|baiki)\b',
    ],
    'electronics': [
      r'\b(?:phone|laptop|computer|gadget|electronic|device)\b',
      r'\b(?:telefon|komputer|alat|peranti)\b',
    ],
    'medical': [
      r'\b(?:medical|doctor|medicine|clinic|hospital|dental|health|pharmacy)\b',
      r'\b(?:ubat|klinik|doktor|hospital|gigi)\b',
    ],
    'income': [
      r'\b(?:salary|bonus|commission|payment|received|income)\b',
      r'\b(?:gaji|bonus|komisyen|bayaran|pendapatan)\b',
    ],
  };

  // Integrated number conversion from TextProcessingUtils
  static final Map<String, int> _numberMap = {
    'zero': 0,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'fifty': 50,
    'sixty': 60,
    'seventy': 70,
    'eighty': 80,
    'ninety': 90,
    'hundred': 100,
    'thousand': 1000,
  };

  String _normalizeText(String text) {
    // Using original TextProcessingUtils correction logic
    List<String> words = text.toLowerCase().split(' ');

    for (int i = 0; i < words.length; i++) {
      String word = words[i];
      String cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '');

      if (_commonCorrections.containsKey(cleanWord)) {
        String punctuation = word.replaceAll(RegExp(r'[\w\s]'), '');
        words[i] = _commonCorrections[cleanWord]! + punctuation;
      }
    }

    return words.join(' ');
  }

  Map<String, dynamic> _extractAmount(String text) {
    try {
      // Using original TextProcessingUtils amount patterns
      
      // Match RM amounts e.g., RM50.30, RM50
      final regexRM = RegExp(r'\bRM\s?(\d{1,3}(?:\.\d{1,2})?)\b', caseSensitive: false);
      final matchRM = regexRM.firstMatch(text);
      if (matchRM != null) {
        return {
          'value': double.parse(matchRM.group(1)!),
          'currency': 'MYR',
          'confidence': 0.95,
          'source': matchRM.group(0),
        };
      }

      // Match formats like "RM50 90" or "rm50 90"
      final regexRMSeparated = RegExp(r'\bRM\s?(\d{1,3})\s?(\d{1,2})\b', caseSensitive: false);
      final matchRMSeparated = regexRMSeparated.firstMatch(text);
      if (matchRMSeparated != null) {
        double total = double.parse(matchRMSeparated.group(1)!) +
            double.parse(matchRMSeparated.group(2)!) / 100;
        return {
          'value': total,
          'currency': 'MYR',
          'confidence': 0.9,
          'source': matchRMSeparated.group(0),
        };
      }

      // Match amounts like "50 ringgit 90 sen"
      final regexRinggitCents = RegExp(
          r'\b(\d+)\s*ringgits?\s*(?:and|&)?\s*(\d+)\s*(?:cents|sen)\b',
          caseSensitive: false);
      final matchRinggitCents = regexRinggitCents.firstMatch(text);
      if (matchRinggitCents != null) {
        double total = double.parse(matchRinggitCents.group(1)!) +
            double.parse(matchRinggitCents.group(2)!) / 100;
        return {
          'value': total,
          'currency': 'MYR',
          'confidence': 0.9,
          'source': matchRinggitCents.group(0),
        };
      }

      // Match word numbers (e.g., "fifty ringgit")
      final regexWords = RegExp(
          r'\b(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred|thousand)+\s*(?:ringgit|rm)\b',
          caseSensitive: false);
      final matchWords = regexWords.firstMatch(text);
      if (matchWords != null) {
        double? amount = _convertWordsToNumber(matchWords.group(1)!);
        if (amount != null) {
          return {
            'value': amount,
            'currency': 'MYR',
            'confidence': 0.85,
            'source': matchWords.group(0),
          };
        }
      }

      return {
        'value': null,
        'confidence': 0.0,
        'error': 'No amount detected',
      };
    } catch (e) {
      return {
        'value': null,
        'confidence': 0.0,
        'error': e.toString(),
      };
    }
  }

  Map<String, dynamic> _extractCategory(String text) {
    // First try exact category matches (original method)
    for (String category in _validCategories) {
      final regex = RegExp(r'\b' + RegExp.escape(category) + r'\b', caseSensitive: false);
      if (regex.hasMatch(text)) {
        return {
          'value': category,
          'confidence': 0.95,
          'source': category,
        };
      }
    }

    // Then try pattern matching for more complex cases
    Map<String, double> categoryScores = {};
    
    _categoryPatterns.forEach((category, patterns) {
      double score = 0.0;
      
      for (String pattern in patterns) {
        final regex = RegExp(pattern, caseSensitive: false);
        final matches = regex.allMatches(text).length;
        if (matches > 0) {
          score += 0.5 + (0.1 * matches);
        }
      }
      
      if (score > 0) {
        categoryScores[category] = score;
      }
    });

    if (categoryScores.isEmpty) {
      return {
        'value': null,
        'confidence': 0.0,
        'error': 'No category detected',
      };
    }

    final topCategory = categoryScores.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    return {
      'value': topCategory.key,
      'confidence': _normalizeConfidence(topCategory.value),
      'alternatives': categoryScores,
    };
  }

  Map<String, dynamic> _extractDate(String text) {
    final now = DateTime.now();

    // Handle relative dates (from original implementation)
    if (text.toLowerCase().contains('today')) {
      return {
        'value': '${now.day}/${now.month}/${now.year}',
        'type': 'relative',
        'confidence': 0.95,
      };
    } else if (text.toLowerCase().contains('yesterday')) {
      final yesterday = now.subtract(const Duration(days: 1));
      return {
        'value': '${yesterday.day}/${yesterday.month}/${yesterday.year}',
        'type': 'relative',
        'confidence': 0.95,
      };
    } else if (text.toLowerCase().contains('tomorrow')) {
      final tomorrow = now.add(const Duration(days: 1));
      return {
        'value': '${tomorrow.day}/${tomorrow.month}/${tomorrow.year}',
        'type': 'relative',
        'confidence': 0.95,
      };
    }

    // Match specific dates (from original implementation)
    final regexSpecificDate = RegExp(
        r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})|' // Matches 12/09/2023
        r'(\d{1,2})\s+(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{4})',
        caseSensitive: false);
    final matchSpecific = regexSpecificDate.firstMatch(text);
    if (matchSpecific != null) {
      String dateStr;
      if (matchSpecific.group(1) != null) {
        dateStr = '${matchSpecific.group(1)}/${matchSpecific.group(2)}/${matchSpecific.group(3)}';
      } else {
        final monthMap = {
          'january': 1, 'february': 2, 'march': 3, 'april': 4,
          'may': 5, 'june': 6, 'july': 7, 'august': 8,
          'september': 9, 'october': 10, 'november': 11, 'december': 12,
        };
        dateStr = '${matchSpecific.group(4)}/${monthMap[matchSpecific.group(5)!.toLowerCase()]}/${matchSpecific.group(6)}';
      }
      return {
        'value': dateStr,
        'type': 'specific',
        'confidence': 0.9,
      };
    }

    // Default to current date
    return {
      'value': '${now.day}/${now.month}/${now.year}',
      'type': 'default',
      'confidence': 0.5,
      'isDefault': true,
    };
  }

  static double? _convertWordsToNumber(String words) {
    double total = 0;
    double current = 0;

    List<String> tokens = words.toLowerCase().split(RegExp(r'\s+'));
    for (String token in tokens) {
      if (_numberMap.containsKey(token)) {
        double value = _numberMap[token]!.toDouble();
        if (value == 100 || value == 1000) {
          current *= value;
        } else {
          current += value;
        }
      } else if (token == 'and') {
        total += current;
        current = 0;
      }
    }
    total += current;

    return total > 0 ? total : null;
  }

  double _normalizeConfidence(double score) {
    return (1 / (1 + exp(-score))).clamp(0.0, 1.0);
  }

  // The main process method remains the same
  Future<Map<String, dynamic>> processText(String text) async {
    try {
      final normalizedText = _normalizeText(text);
      
      return {
        'amount': _extractAmount(normalizedText),
        'category': _extractCategory(normalizedText),
        'date': _extractDate(normalizedText),
        'metadata': _extractMetadata(normalizedText),
        'original_text': text,
        'normalized_text': normalizedText,
      };
    } catch (e) {
      print('Error processing text: $e');
      return {
        'error': 'Failed to process text',
        'details': e.toString(),
      };
    }
  }

  Map<String, dynamic> _extractMetadata(String text) {
    return {
      'location': _extractLocation(text),
      'purpose': _extractPurpose(text),
    };
  }

  Map<String, dynamic> _extractLocation(String text) {
    final locationPattern = RegExp(
      r'\b(?:at|in|from|di|dalam)\s+([A-Za-z\s]+(?:mall|store|shop|restaurant|cafe|kedai|restoran))\b',
      caseSensitive: false,
    );

    final match = locationPattern.firstMatch(text);
    if (match != null) {
      return {
        'value': match.group(1)?.trim(),
        'confidence': 0.8,
      };
    }

    return {
      'value': null,
      'confidence': 0.0,
    };
  }

  Map<String, dynamic> _extractPurpose(String text) {
    final purposePattern = RegExp(
      r'\b(?:for|to|untuk)\s+([^.,!?]+?)(?=\s*[.,!?]|$)',
      caseSensitive: false,
    );

    final match = purposePattern.firstMatch(text);
    if (match != null) {
      return {
        'value': match.group(1)?.trim(),
        'confidence': 0.7,
      };
    }

    return {
      'value': null,
      'confidence': 0.0,
    };
  }

  // Helper methods for external use
  static List<String> getAvailableCategories() {
    return _categoryPatterns.keys.toList();
  }

  static String formatAmount(double amount) {
    return 'RM${amount.toStringAsFixed(2)}';
  }
}