class TextProcessingUtils {
  // Common corrections for speech recognition errors
  // Common language patterns for expense context
  static final Map<String, List<String>> contextPatterns = {
    'spend_verbs': [
      'spent',
      'bought',
      'purchased',
      'paid',
      'ordered',
      'got',
      'treated',
      'borrowed',
      'loaned',
      'invested',
      'transferred',
      'withdrew',
      'deposited',
      'charged',
      'cost',
      'paying',
      'buying',
      'purchasing',
      'spending'
    ],
    'money_nouns': [
      'price',
      'cost',
      'amount',
      'fee',
      'charge',
      'payment',
      'expense',
      'bill',
      'receipt',
      'total',
      'sum',
      'cash',
      'money',
      'ringgit',
      'rm'
    ],
    'time_indicators': [
      'this',
      'last',
      'next',
      'previous',
      'coming',
      'past',
      'morning',
      'afternoon',
      'evening',
      'night',
      'today',
      'yesterday',
      'tomorrow'
    ],
    'amount_adjectives': [
      'expensive',
      'cheap',
      'costly',
      'affordable',
      'pricey',
      'reasonable',
      'high',
      'low',
      'total',
      'full',
      'partial',
      'approximate',
      'about',
      'around',
      'nearly',
      'almost',
      'exactly',
      'precisely'
    ],
    'location_prepositions': ['at', 'in', 'from', 'to', 'for', 'on', 'by']
  };

  static String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .toLowerCase()
        .split(' ')
        .map((word) =>
            word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  static final Map<String, String> commonCorrections = {
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

    // Action verbs
    'span': 'spent',
    'spend': 'spent',
    'used': 'spent',
    'paid': 'spent',
    'costed': 'cost',
    'buy': 'bought',
  };

  // Category mappings with common variations
  static final Map<String, String> categoryMappings = {
    // Food & Drinks
    'food': 'food',
    'meal': 'food',
    'lunch': 'food',
    'dinner': 'food',
    'breakfast': 'food',
    'groceries': 'food',
    'grocery': 'food',
    'snacks': 'food',
    'drinks': 'drinks',
    'beverage': 'drinks',
    'coffee': 'drinks',

    // Transport
    'transport': 'transport',
    'transportation': 'transport',
    'bus': 'transport',
    'taxi': 'transport',
    'grab': 'transport',
    'fuel': 'transport',
    'petrol': 'transport',
    'mrt': 'transport',
    'train': 'transport',

    // Shopping
    'shopping': 'shopping',
    'clothes': 'shopping',
    'clothing': 'shopping',
    'apparel': 'shopping',
    'merchandise': 'shopping',
    'retail': 'shopping',
    'mall': 'shopping',

    // Entertainment
    'entertainment': 'entertainment',
    'movie': 'entertainment',
    'cinema': 'entertainment',
    'games': 'entertainment',
    'music': 'entertainment',
    'concert': 'entertainment',
    'show': 'entertainment',

    // Housing
    'housing': 'housing',
    'rent': 'housing',
    'utilities': 'housing',
    'bills': 'housing',
    'electricity': 'housing',
    'water': 'housing',
    'maintenance': 'housing',

    // Electronics
    'electronics': 'electronics',
    'gadgets': 'electronics',
    'phone': 'electronics',
    'laptop': 'electronics',
    'computer': 'electronics',
    'device': 'electronics',

    // Medical
    'medical': 'medical',
    'healthcare': 'medical',
    'doctor': 'medical',
    'medicine': 'medical',
    'clinic': 'medical',
    'hospital': 'medical',
    'pharmacy': 'medical',

    // Income
    'income': 'income',
    'salary': 'income',
    'wages': 'income',
    'earnings': 'income',
    'allowance': 'income',
    'payment': 'income',
  };

  static String correctText(String text) {
    String processed = text.toLowerCase();

    // Remove common filler words
    processed = processed.replaceAll(
        RegExp(r'\b(like|um|uh|you\s*know|i\s*mean)\b'), '');

    // Split into words and correct each one
    List<String> words = processed.split(' ');

    for (int i = 0; i < words.length; i++) {
      String word = words[i];
      String cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '');

      if (commonCorrections.containsKey(cleanWord)) {
        String punctuation = word.replaceAll(RegExp(r'[\w\s]'), '');
        words[i] = commonCorrections[cleanWord]! + punctuation;
      }
    }

    return words.join(' ');
  }

  static String? _findContextualVerb(String text) {
    for (String verb in contextPatterns['spend_verbs']!) {
      if (text.contains(verb)) {
        return verb;
      }
    }
    return null;
  }

  static bool _hasMoneyContext(String text) {
    return contextPatterns['money_nouns']!.any((noun) => text.contains(noun)) ||
        contextPatterns['amount_adjectives']!.any((adj) => text.contains(adj));
  }

  static String? extractAmount(String text) {
    // Preprocess text to remove hyphens and normalize
    text = text.replaceAll('-', ' ').toLowerCase();

    // Match "X ringgit and Y cents" (e.g., "50 ringgit and 50 cents")
    final regexRinggitCents = RegExp(
        r'\b(\d+)\s*ringgits?\s*(?:and|&)?\s*(\d+)\s*(?:cents?|sen)\b',
        caseSensitive: false);
    final matchRinggitCents = regexRinggitCents.firstMatch(text);
    if (matchRinggitCents != null) {
      double total = double.parse(matchRinggitCents.group(1)!) +
          double.parse(matchRinggitCents.group(2)!) / 100;
      return total.toStringAsFixed(2);
    }

    // Match "RM X Y" (e.g., "RM 50 50")
    final regexRMSpaced = RegExp(
        r'\b(rm|ringgit)\s*(\d+)\s+(\d{1,2})\b', // Matches "RM 50 50", "ringgit 50 50"
        caseSensitive: false);
    final matchRMSpaced = regexRMSpaced.firstMatch(text);
    if (matchRMSpaced != null) {
      double total = double.parse(matchRMSpaced.group(2)!) +
          double.parse(matchRMSpaced.group(3)!) / 100;
      return total.toStringAsFixed(2);
    }

    // Match RM amounts with decimals (e.g., "RM50.50", "50.50 ringgit")
    final regexRM = RegExp(
        r'\b(rm|ringgit)?\s?(\d{1,3}(?:\.\d{1,2})?)\b', // Matches "RM50.50"
        caseSensitive: false);
    final matchRM = regexRM.firstMatch(text);
    if (matchRM != null) return matchRM.group(2);

    // Match written word numbers with "ringgit" (e.g., "fifty ringgit and fifty cents")
    final regexWordRinggit = RegExp(
        r'\b(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred|thousand)\s+ringgits?\s*(?:and|&)?\s*(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety)?\s*(?:cents?|sen)?\b',
        caseSensitive: false);
    final matchWordRinggit = regexWordRinggit.firstMatch(text);
    if (matchWordRinggit != null) {
      double total = 0;
      double? ringgit = convertWordsToNumber(matchWordRinggit.group(1)!);
      double? cents = matchWordRinggit.group(2) != null
          ? convertWordsToNumber(matchWordRinggit.group(2)!)
          : 0;
      if (ringgit != null) {
        total = ringgit + (cents! / 100);
        return total.toStringAsFixed(2);
      }
    }

    // If no match found, return null
    return null;
  }

  static String? extractCategory(String text) {
    text = text.toLowerCase();

    // Check each word/phrase against category mappings
    for (String key in categoryMappings.keys) {
      final regex =
          RegExp(r'\b' + RegExp.escape(key) + r'\b', caseSensitive: false);
      if (regex.hasMatch(text)) {
        return categoryMappings[key];
      }
    }

    // Look for category in context of spending words
    final spendingContexts = [
      r'spent (?:on|for)',
      r'paid (?:on|for)',
      r'bought',
      r'purchased',
    ];

    for (String context in spendingContexts) {
      final regex = RegExp('$context\\s+(?:some|the|a|an)?\\s*(\\w+)',
          caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null) {
        String potentialCategory = match.group(1)!.toLowerCase();
        if (categoryMappings.containsKey(potentialCategory)) {
          return categoryMappings[potentialCategory];
        }
      }
    }

    return null;
  }

  static String? extractDate(String text) {
    text = text.toLowerCase();
    final now = DateTime.now();

    // Add specific handler for "last week"
    if (text.contains('last week')) {
      return formatDate(now.subtract(const Duration(days: 7)));
    }

    // Handle "yesterday", "today", "tomorrow"
    if (text.contains('yesterday')) {
      return formatDate(now.subtract(const Duration(days: 1)));
    } else if (text.contains('today')) {
      return formatDate(now);
    } else if (text.contains('tomorrow')) {
      return formatDate(now.add(const Duration(days: 1)));
    }

    // Handle "last month" and "next month"
    if (text.contains('last month')) {
      final lastMonth = DateTime(now.year, now.month - 1, now.day);
      return formatDate(lastMonth);
    } else if (text.contains('next month')) {
      final nextMonth = DateTime(now.year, now.month + 1, now.day);
      return formatDate(nextMonth);
    }

    // Handle "last year" and "next year"
    if (text.contains('last year')) {
      final lastYear = DateTime(now.year - 1, now.month, now.day);
      return formatDate(lastYear);
    } else if (text.contains('next year')) {
      final nextYear = DateTime(now.year + 1, now.month, now.day);
      return formatDate(nextYear);
    }

    // Handle "n days/weeks/months/years ago"
    final relativePastRegex = RegExp(r'(\d+)\s*(day|week|month|year)s?\s*ago');
    final relativePastMatch = relativePastRegex.firstMatch(text);
    if (relativePastMatch != null) {
      int value = int.parse(relativePastMatch.group(1)!);
      String unit = relativePastMatch.group(2)!;

      DateTime calculatedDate = now;
      switch (unit) {
        case 'day':
          calculatedDate = now.subtract(Duration(days: value));
          break;
        case 'week':
          calculatedDate = now.subtract(Duration(days: value * 7));
          break;
        case 'month':
          calculatedDate = DateTime(now.year, now.month - value, now.day);
          break;
        case 'year':
          calculatedDate = DateTime(now.year - value, now.month, now.day);
          break;
      }

      return formatDate(calculatedDate);
    }

    // Handle "in n days/weeks/months/years"
    final relativeFutureRegex = RegExp(r'in\s+(\d+)\s*(day|week|month|year)s?');
    final relativeFutureMatch = relativeFutureRegex.firstMatch(text);
    if (relativeFutureMatch != null) {
      int value = int.parse(relativeFutureMatch.group(1)!);
      String unit = relativeFutureMatch.group(2)!;

      DateTime calculatedDate = now;
      switch (unit) {
        case 'day':
          calculatedDate = now.add(Duration(days: value));
          break;
        case 'week':
          calculatedDate = now.add(Duration(days: value * 7));
          break;
        case 'month':
          calculatedDate = DateTime(now.year, now.month + value, now.day);
          break;
        case 'year':
          calculatedDate = DateTime(now.year + value, now.month, now.day);
          break;
      }

      return formatDate(calculatedDate);
    }

    // Match specific dates (e.g., "15th of December 2023")
    final regexSpecificDate = RegExp(
        r'(\d{1,2})(?:st|nd|rd|th)?\s+(of\s+)?(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{4})',
        caseSensitive: false);
    final specificDateMatch = regexSpecificDate.firstMatch(text);
    if (specificDateMatch != null) {
      int day = int.parse(specificDateMatch.group(1)!);
      int month = _monthStringToNumber(specificDateMatch.group(3)!);
      int year = int.parse(specificDateMatch.group(4)!);
      return formatDate(DateTime(year, month, day));
    }

    // Default fallback: today's date
    return formatDate(now);
  }

// Helper method to convert month names to numbers
  static int _monthStringToNumber(String month) {
    final monthMap = {
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'may': 5,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12,
    };
    return monthMap[month.toLowerCase()]!;
  }

// Helper method to format dates as DD/MM/YYYY
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static double? convertWordsToNumber(String words) {
    final numberMap = {
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

    double total = 0;
    double current = 0;

    List<String> tokens = words.toLowerCase().split(RegExp(r'\s+'));
    for (String token in tokens) {
      if (numberMap.containsKey(token)) {
        double value = numberMap[token]!.toDouble();
        if (value == 100 || value == 1000) {
          current = current == 0 ? value : current * value;
        } else {
          current += value;
        }
      } else if (token == 'and') {
        if (current > 0) {
          total += current;
          current = 0;
        }
      }
    }

    total += current;
    return total > 0 ? total : null;
  }
}
