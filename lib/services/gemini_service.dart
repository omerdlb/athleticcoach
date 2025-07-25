import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static Future<String?> generateContent(String prompt) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-goog-api-key': _apiKey,
      },
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      return text?.toString();
    } else {
      return 'Hata: ${response.statusCode} - ${response.body}';
    }
  }

  static Future<String?> generateDetailedAnalysis({
    required String athleteName,
    required String athleteSurname,
    required int age,
    required String gender,
    required String branch,
    required double height,
    required double weight,
    required String testName,
    required double result,
    required String resultUnit,
    String? notes,
  }) async {
    final prompt = '''
Sen deneyimli bir spor antrenörü ve performans analisti olarak, sporcu test sonuçlarını detaylı bir şekilde analiz et ve kapsamlı öneriler sun.

SPORCU PROFİLİ:
- Ad Soyad: $athleteName $athleteSurname
- Yaş: $age yaşında
- Cinsiyet: $gender
- Branş: $branch
- Boy: ${height}cm
- Kilo: ${weight}kg
- BMI: ${(weight / ((height / 100) * (height / 100))).toStringAsFixed(1)}

TEST BİLGİLERİ:
- Test: $testName
- Sonuç: $result $resultUnit
- Antrenör Notu: ${notes ?? 'Not girilmemiş'}

Lütfen aşağıdaki başlıklar altında detaylı analiz yap:

1. SONUÇ DEĞERLENDİRMESİ:
- Bu yaş ve cinsiyet grubu için sonucun seviyesi (çok zayıf/zayıf/orta/iyi/çok iyi/mükemmel)
- Yaş grubuna göre yüzdelik dilim tahmini
- Branş için bu kapasitenin önemi ve etkisi
- Sonucun genel performans üzerindeki etkisi

2. EKSİK YÖNLER VE GÜÇLÜ YANLAR:
- Bu test sonucuna göre sporcunun güçlü yanları
- Geliştirilmesi gereken alanlar
- Branş için kritik olan eksiklikler
- Potansiyel risk faktörleri

3. GENEL PERFORMANS DEĞERLENDİRMESİ:
- Branş için bu kapasitenin önemi (1-10 arası puan)
- Diğer fiziksel özelliklerle ilişkisi
- Uzun vadeli gelişim potansiyeli
- Sezon içi performans etkisi

4. HAFTALIK GELİŞTİRME PROGRAMI:
- 4 haftalık detaylı antrenman planı
- Her hafta için spesifik hedefler
- Antrenman yoğunluğu ve süreleri
- İlerleme takibi için ölçüm noktaları

5. BESLENME VE DİNLENME ÖNERİLERİ:
- Bu kapasiteyi destekleyecek beslenme önerileri
- Dinlenme ve toparlanma stratejileri
- Uyku kalitesi için öneriler

6. UZUN VADELİ GELİŞİM PLANI:
- 3-6 aylık hedefler
- Sezonluk gelişim stratejisi
- Performans zirvesi için zamanlama

Yanıtını Türkçe olarak, profesyonel antrenör diliyle, kısa ve öz paragraflar halinde ver. Her bölüm maksimum 150 kelime olsun. Sporcu bilgilerini cevabında tekrar yazma, sadece analiz ve önerilere odaklan.
''';

    return await generateContent(prompt);
  }

  static Future<String?> generateComparativeAnalysis({
    required List<Map<String, dynamic>> results,
    required String testName,
  }) async {
    final resultsText = results.map((result) {
      final athlete = result['athlete'];
      return '''
- ${athlete['name']} ${athlete['surname']} (${athlete['age']} yaş, ${athlete['gender']}): ${result['result']} ${result['unit']}
''';
    }).join('\n');

    final prompt = '''
Sen deneyimli bir spor antrenörü olarak, aynı test için birden fazla sporcunun sonuçlarını karşılaştırmalı olarak analiz et.

TEST: $testName

SPORCU SONUÇLARI:
$resultsText

Lütfen aşağıdaki başlıklar altında karşılaştırmalı analiz yap:

1. GENEL DEĞERLENDİRME:
- En iyi performans gösteren sporcu
- En çok gelişim potansiyeli olan sporcu
- Grup ortalaması ve standart sapma analizi

2. YAŞ VE CİNSİYET FAKTÖRLERİ:
- Yaş gruplarına göre performans dağılımı
- Cinsiyet bazlı performans farklılıkları
- Yaş-cinsiyet etkileşimi analizi

3. BİREYSEL GELİŞİM ÖNERİLERİ:
- Her sporcu için özel gelişim alanları
- Grup içi rekabet avantajları
- Bireysel antrenman ihtiyaçları

4. TAKIM STRATEJİSİ:
- Takım performansını artıracak öneriler
- Sporcu eşleştirme önerileri
- Grup antrenmanı fırsatları

Türkçe olarak, kısa ve öz paragraflar halinde yanıtla. Her bölüm maksimum 120 kelime olsun.
''';

    return await generateContent(prompt);
  }
} 