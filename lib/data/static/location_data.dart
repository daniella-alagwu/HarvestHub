class CountryInfo {
  final String name;
  final String iso2;
  final String dialCode;
  final String flag;
  final List<String> states;

  const CountryInfo({
    required this.name,
    required this.iso2,
    required this.dialCode,
    required this.flag,
    this.states = const [],
  });
}

class LocationData {
  LocationData._();

  static const CountryInfo defaultCountry = nigeria;

  static const nigeria = CountryInfo(
    name: 'Nigeria',
    iso2: 'NG',
    dialCode: '+234',
    flag: '🇳🇬',
    states: [
      'Abia', 'Adamawa', 'Akwa Ibom', 'Anambra', 'Bauchi', 'Bayelsa',
      'Benue', 'Borno', 'Cross River', 'Delta', 'Ebonyi', 'Edo', 'Ekiti',
      'Enugu', 'Gombe', 'Imo', 'Jigawa', 'Kaduna', 'Kano', 'Katsina',
      'Kebbi', 'Kogi', 'Kwara', 'Lagos', 'Nasarawa', 'Niger', 'Ogun',
      'Ondo', 'Osun', 'Oyo', 'Plateau', 'Rivers', 'Sokoto', 'Taraba',
      'Yobe', 'Zamfara', 'Federal Capital Territory',
    ],
  );

  static const List<CountryInfo> countries = [
    nigeria,
    CountryInfo(
      name: 'Ghana',
      iso2: 'GH',
      dialCode: '+233',
      flag: '🇬🇭',
      states: [
        'Ahafo', 'Ashanti', 'Bono', 'Bono East', 'Central', 'Eastern',
        'Greater Accra', 'North East', 'Northern', 'Oti', 'Savannah',
        'Upper East', 'Upper West', 'Volta', 'Western', 'Western North',
      ],
    ),
    CountryInfo(
      name: 'South Africa',
      iso2: 'ZA',
      dialCode: '+27',
      flag: '🇿🇦',
      states: [
        'Eastern Cape', 'Free State', 'Gauteng', 'KwaZulu-Natal',
        'Limpopo', 'Mpumalanga', 'North West', 'Northern Cape',
        'Western Cape',
      ],
    ),
    CountryInfo(name: 'Kenya', iso2: 'KE', dialCode: '+254', flag: '🇰🇪'),
    CountryInfo(
      name: 'United States',
      iso2: 'US',
      dialCode: '+1',
      flag: '🇺🇸',
      states: [
        'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California',
        'Colorado', 'Connecticut', 'Delaware', 'Florida', 'Georgia',
        'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas',
        'Kentucky', 'Louisiana', 'Maine', 'Maryland', 'Massachusetts',
        'Michigan', 'Minnesota', 'Mississippi', 'Missouri', 'Montana',
        'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey', 'New Mexico',
        'New York', 'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma',
        'Oregon', 'Pennsylvania', 'Rhode Island', 'South Carolina',
        'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont',
        'Virginia', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming',
        'District of Columbia',
      ],
    ),
    CountryInfo(
      name: 'United Kingdom',
      iso2: 'GB',
      dialCode: '+44',
      flag: '🇬🇧',
      states: ['England', 'Scotland', 'Wales', 'Northern Ireland'],
    ),
    CountryInfo(
      name: 'Canada',
      iso2: 'CA',
      dialCode: '+1',
      flag: '🇨🇦',
      states: [
        'Alberta', 'British Columbia', 'Manitoba', 'New Brunswick',
        'Newfoundland and Labrador', 'Nova Scotia', 'Ontario',
        'Prince Edward Island', 'Quebec', 'Saskatchewan',
        'Northwest Territories', 'Nunavut', 'Yukon',
      ],
    ),
    CountryInfo(name: 'India', iso2: 'IN', dialCode: '+91', flag: '🇮🇳'),
    CountryInfo(name: 'Egypt', iso2: 'EG', dialCode: '+20', flag: '🇪🇬'),
    CountryInfo(name: 'Cameroon', iso2: 'CM', dialCode: '+237', flag: '🇨🇲'),
    CountryInfo(name: "Côte d'Ivoire", iso2: 'CI', dialCode: '+225', flag: '🇨🇮'),
    CountryInfo(name: 'Senegal', iso2: 'SN', dialCode: '+221', flag: '🇸🇳'),
    CountryInfo(name: 'Ethiopia', iso2: 'ET', dialCode: '+251', flag: '🇪🇹'),
    CountryInfo(name: 'Tanzania', iso2: 'TZ', dialCode: '+255', flag: '🇹🇿'),
    CountryInfo(name: 'Uganda', iso2: 'UG', dialCode: '+256', flag: '🇺🇬'),
    CountryInfo(name: 'Rwanda', iso2: 'RW', dialCode: '+250', flag: '🇷🇼'),
    CountryInfo(name: 'Germany', iso2: 'DE', dialCode: '+49', flag: '🇩🇪'),
    CountryInfo(name: 'France', iso2: 'FR', dialCode: '+33', flag: '🇫🇷'),
    CountryInfo(name: 'Australia', iso2: 'AU', dialCode: '+61', flag: '🇦🇺'),
    CountryInfo(name: 'United Arab Emirates', iso2: 'AE', dialCode: '+971', flag: '🇦🇪'),
    CountryInfo(name: 'Saudi Arabia', iso2: 'SA', dialCode: '+966', flag: '🇸🇦'),
    CountryInfo(name: 'China', iso2: 'CN', dialCode: '+86', flag: '🇨🇳'),
    CountryInfo(name: 'Brazil', iso2: 'BR', dialCode: '+55', flag: '🇧🇷'),
    CountryInfo(name: 'Philippines', iso2: 'PH', dialCode: '+63', flag: '🇵🇭'),
  ];

  static CountryInfo byIso2(String iso2) =>
      countries.firstWhere((c) => c.iso2 == iso2, orElse: () => nigeria);
}