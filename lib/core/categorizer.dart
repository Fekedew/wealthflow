/// Category ids. Display names live in l10n under `cat_<id>`.
const expenseCategories = [
  'food',
  'transport',
  'housing',
  'utilities',
  'health',
  'shopping',
  'entertainment',
  'education',
  'savings',
  'other',
];

const incomeCategories = ['salary', 'freelance', 'gift', 'other_income'];

const _expenseKeywords = <String, List<String>>{
  'food': [
    'restaurant', 'cafe', 'coffee', 'lunch', 'dinner', 'breakfast', 'grocery',
    'groceries', 'supermarket', 'bakery', 'pizza', 'injera', 'food', 'kitfo',
    'ምግብ', 'ቡና', 'ምሳ', 'እራት', 'ቁርስ', 'ሬስቶራንት', 'ሱፐርማርኬት',
  ],
  'transport': [
    'taxi', 'uber', 'ride', 'bus', 'fuel', 'gas', 'petrol', 'parking', 'bajaj',
    'train', 'flight', 'ታክሲ', 'ባጃጅ', 'ነዳጅ', 'ቤንዚን', 'መጓጓዣ', 'አውቶቡስ',
  ],
  'housing': [
    'rent', 'mortgage', 'landlord', 'furniture', 'repair', 'ቤት ኪራይ', 'ኪራይ', 'ቤት',
  ],
  'utilities': [
    'electric', 'water', 'internet', 'wifi', 'phone', 'airtime', 'telebirr',
    'ethio telecom', 'safaricom', 'utility', 'ኤሌክትሪክ', 'ውሃ', 'ኢንተርኔት', 'ስልክ', 'ካርድ',
  ],
  'health': [
    'pharmacy', 'doctor', 'hospital', 'clinic', 'medicine', 'dentist', 'gym',
    'ፋርማሲ', 'ሐኪም', 'ሆስፒታል', 'መድኃኒት', 'ክሊኒክ',
  ],
  'shopping': [
    'clothes', 'shoes', 'mall', 'amazon', 'shop', 'market', 'gift', 'ልብስ', 'ጫማ', 'ሸመታ', 'ገበያ',
  ],
  'entertainment': [
    'movie', 'cinema', 'netflix', 'spotify', 'game', 'concert', 'bar', 'club',
    'ፊልም', 'ሙዚቃ', 'መዝናኛ',
  ],
  'education': [
    'tuition', 'school', 'course', 'book', 'university', 'udemy', 'ትምህርት', 'መጽሐፍ', 'ትምህርት ቤት',
  ],
  'savings': ['saving', 'deposit', 'invest', 'equb', 'ቁጠባ', 'እቁብ', 'ኢንቨስት'],
};

const _incomeKeywords = <String, List<String>>{
  'salary': ['salary', 'payroll', 'wage', 'paycheck', 'ደመወዝ'],
  'freelance': ['freelance', 'client', 'invoice', 'contract', 'project', 'ነፃ ሥራ', 'ክፍያ'],
  'gift': ['gift', 'bonus', 'present', 'ስጦታ', 'ሽልማት'],
};

/// Guesses a category from the free-text note; falls back to "other".
String categorize(String note, {required bool isIncome}) {
  final text = note.toLowerCase();
  final table = isIncome ? _incomeKeywords : _expenseKeywords;
  for (final e in table.entries) {
    if (e.value.any(text.contains)) return e.key;
  }
  return isIncome ? 'other_income' : 'other';
}
