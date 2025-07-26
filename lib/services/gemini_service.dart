import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static Future<String?> generateContent(String prompt) async {
    print('=== GEMINI API ÇAĞRISI ===');
    print('Prompt Uzunluğu: ${prompt.length} karakter');
    print('API Key: ${_apiKey.isNotEmpty ? 'Mevcut' : 'EKSİK!'}');
    print('==========================');
    
    // Retry mekanizması
    int maxRetries = 3;
    int currentRetry = 0;
    
    while (currentRetry < maxRetries) {
      try {
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

        print('=== API YANITI (Deneme ${currentRetry + 1}) ===');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('==================');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          
          print('=== PARSE EDİLEN YANIT ===');
          print('Text: ${text?.toString().substring(0, text.toString().length > 100 ? 100 : text.toString().length)}...');
          print('==========================');
          
          return text?.toString();
        } else if (response.statusCode == 503) {
          // Model aşırı yüklü, tekrar dene
          print('=== MODEL AŞIRI YÜKLÜ, TEKRAR DENENİYOR ===');
          print('Deneme: ${currentRetry + 1}/$maxRetries');
          print('Bekleme süresi: ${(currentRetry + 1) * 2} saniye');
          print('==========================================');
          
          currentRetry++;
          if (currentRetry < maxRetries) {
            // Exponential backoff: 2, 4, 6 saniye bekle
            await Future.delayed(Duration(seconds: currentRetry * 2));
            continue;
          }
        } else {
          print('=== API HATASI ===');
          print('Status Code: ${response.statusCode}');
          print('Error Body: ${response.body}');
          print('==================');
          return 'Hata: ${response.statusCode} - ${response.body}';
        }
      } catch (e) {
        print('=== NETWORK HATASI ===');
        print('Hata: $e');
        print('Deneme: ${currentRetry + 1}/$maxRetries');
        print('======================');
        
        currentRetry++;
        if (currentRetry < maxRetries) {
          await Future.delayed(Duration(seconds: currentRetry * 2));
          continue;
        }
      }
    }
    
    // Tüm denemeler başarısız
    print('=== TÜM DENEMELER BAŞARISIZ ===');
    print('Maksimum deneme sayısına ulaşıldı: $maxRetries');
    print('===============================');
    
    return 'API aşırı yüklü. Lütfen birkaç dakika sonra tekrar deneyin.';
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
    // Debug bilgileri
    print('=== AI ANALİZ VERİLERİ ===');
    print('Sporcu: $athleteName $athleteSurname');
    print('Yaş: $age');
    print('Cinsiyet: $gender');
    print('Branş: $branch');
    print('Boy: $height cm');
    print('Kilo: $weight kg');
    print('Test: $testName');
    print('Sonuç: $result $resultUnit');
    print('Notlar: ${notes ?? 'Yok'}');
    print('========================');

    // Veri doğrulama
    if (height <= 0 || weight <= 0 || result <= 0) {
      print('HATA: Geçersiz veri değerleri!');
      return 'Hata: Geçersiz veri değerleri. Boy, kilo ve test sonucu 0\'dan büyük olmalıdır.';
    }

    final bmi = weight / ((height / 100) * (height / 100));
    
    final prompt = '''
        Sen spor antrenörüsün. Sporcu test sonucunu analiz et.

        SPORCU: $athleteName $athleteSurname ($age yaş, $gender, $branch)
        BOY: ${height.toStringAsFixed(1)} cm, KİLO: ${weight.toStringAsFixed(1)} kg
        TEST: $testName
        SONUÇ: ${result.toStringAsFixed(2)} $resultUnit
        NOT: ${notes ?? 'Yok'}

        Şu 3 bölümde kısa analiz yap:

        1. SONUÇ DEĞERLENDİRMESİ:
        Bu yaş grubu için sonucun seviyesi (zayıf/orta/iyi/çok iyi)

        2. EKSİK YÖNLER:
        Geliştirilmesi gereken 2-3 alan

        3. EGZERSİZ ÖNERİSİ:
        Bu kapasiteyi geliştirmek için 3-4 egzersiz

        Her bölüm maksimum 50 kelime olsun. Kısa ve öz yaz.
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

  static Future<String?> generateTeamAnalysis({
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
        Sen spor antrenörüsün. Takım test sonuçlarını analiz et.

        TEST: $testName
        SPORCU SAYISI: ${results.length}

        SONUÇLAR:
        $resultsText

        Şu 3 bölümde kısa analiz yap:

        1. GENEL DEĞERLENDİRME:
        En iyi ve en zayıf performans gösteren sporcular

        2. TAKIM SEVİYESİ:
        Genel takım performansı ve seviyesi

        3. GELİŞİM ÖNERİSİ:
        Takım için 2-3 genel öneri

        Her bölüm maksimum 40 kelime olsun. Kısa ve öz yaz.
        ''';

    return await generateContent(prompt);
  }
} 