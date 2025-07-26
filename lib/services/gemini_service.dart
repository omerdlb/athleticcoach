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
    print('Ham Sonuç: $result');
    print('Sonuç Birimi: $resultUnit');
    print('Sonuç: $result $resultUnit');
    print('Notlar: ${notes ?? 'Yok'}');
    print('========================');

    // Veri doğrulama
    if (height <= 0 || weight <= 0 || result <= 0) {
      print('HATA: Geçersiz veri değerleri!');
      print('Height: $height, Weight: $weight, Result: $result');
      return 'Hata: Geçersiz veri değerleri. Boy, kilo ve test sonucu 0\'dan büyük olmalıdır.';
    }

    final bmi = weight / ((height / 100) * (height / 100));
    
    // Test sonucunu daha anlaşılır formatta hazırla
    String formattedResult = '';
    if (resultUnit == 'Seviye.Mekik') {
      // Yo-Yo testleri için seviye ve mekik ayrımı
      final level = result.floor();
      final shuttle = ((result - level) * 10).round();
      formattedResult = 'Seviye $level, Mekik $shuttle';
      print('Yo-Yo Formatı: $formattedResult (Ham: $result)');
    } else if (resultUnit == 'Seviye') {
      // Beep test gibi sadece seviye olan testler
      formattedResult = 'Seviye ${result.toStringAsFixed(1)}';
      print('Beep Test Formatı: $formattedResult (Ham: $result)');
    } else {
      // Diğer testler için normal format
      formattedResult = '${result.toStringAsFixed(2)} $resultUnit';
      print('Normal Format: $formattedResult (Ham: $result)');
    }
    
    print('Final Formatlanmış Sonuç: $formattedResult');
    
    final prompt = '''
Sen deneyimli bir spor antrenörüsün. Aşağıdaki sporcu test verilerini analiz et.

SPORCU BİLGİLERİ:
- Ad Soyad: $athleteName $athleteSurname
- Yaş: $age
- Cinsiyet: $gender
- Branş: $branch
- Boy: ${height.toStringAsFixed(1)} cm
- Kilo: ${weight.toStringAsFixed(1)} kg
- BMI: ${bmi.toStringAsFixed(1)}

TEST BİLGİLERİ:
- Test Adı: $testName
- Test Sonucu: $formattedResult
- Ham Sonuç Değeri: $result
- Sonuç Birimi: $resultUnit
- Ek Notlar: ${notes ?? 'Yok'}

KURALLAR:
1. Her bölümü MUTLAKA tamamla
2. Yarım cümle bırakma
3. Her bölüm en az 30 kelime olsun
4. Spesifik ve detaylı yaz
5. Test sonucunu mutlaka değerlendir
6. Test adını ve sonucunu tam olarak kullan
7. Ham sonuç değerini ($result) doğru algıla

Aşağıdaki 3 bölümü tam olarak yaz:

1. SONUÇ DEĞERLENDİRMESİ:
$testName testinde elde edilen $formattedResult sonucunu değerlendir. Ham sonuç değeri $result'tir. Bu yaş grubu ve cinsiyet için sonucun seviyesini belirt (zayıf/orta/iyi/çok iyi). $branch branşı için bu sonucun anlamını açıkla. Yaş grubuna göre performans seviyesini detaylı değerlendir.

2. EKSİK YÖNLER:
Bu test alanında sporcunun geliştirilmesi gereken 2-3 spesifik eksik yönünü belirt. Her eksik yön için detaylı açıklama ver. Neden bu alanların zayıf olduğunu ve nasıl geliştirilebileceğini açıkla.

3. EGZERSİZ ÖNERİSİ:
Bu kapasiteyi geliştirmek için 3-4 spesifik egzersiz öner. Her egzersizin adını, nasıl yapılacağını ve süresini belirt. Egzersizlerin faydalarını ve bu test performansını nasıl artıracağını kısaca açıkla.

ÖNEMLİ: Her bölümü tamamla ve yarım bırakma! Test adını ve sonucunu doğru kullan! Ham sonuç değeri $result'tir!
''';

    print('=== AI PROMPT GÖNDERİLİYOR ===');
    print('Prompt uzunluğu: ${prompt.length} karakter');
    print('Test adı: $testName');
    print('Formatlanmış sonuç: $formattedResult');
    print('Ham sonuç: $result');
    print('==============================');

    return await generateContent(prompt);
  }

  static Future<String?> generateComparativeAnalysis({
    required List<Map<String, dynamic>> results,
    required String testName,
  }) async {
    // Test sonuçlarını formatla
    final resultsText = results.map((result) {
      final athlete = result['athlete'];
      final testResult = result['result'];
      final unit = result['unit'];
      
      String formattedResult = '';
      if (unit == 'Seviye.Mekik') {
        final level = testResult.floor();
        final shuttle = ((testResult - level) * 10).round();
        formattedResult = 'Seviye $level, Mekik $shuttle';
      } else if (unit == 'Seviye') {
        formattedResult = 'Seviye ${testResult.toStringAsFixed(1)}';
      } else {
        formattedResult = '${testResult.toStringAsFixed(2)} $unit';
      }
      
      return '''
- ${athlete['name']} ${athlete['surname']} (${athlete['age']} yaş, ${athlete['gender']}): $formattedResult
''';
    }).join('\n');

    final prompt = '''
Sen deneyimli bir spor antrenörüsün. Aşağıdaki sporcu test verilerini karşılaştırmalı olarak analiz et.

TEST BİLGİLERİ:
- Test Adı: $testName
- Katılımcı Sayısı: ${results.length}

SPORCU SONUÇLARI:
$resultsText

KURALLAR:
1. Her bölümü MUTLAKA tamamla
2. Yarım cümle bırakma
3. Her bölüm en az 40 kelime olsun
4. Spesifik ve detaylı yaz
5. Sporcu isimlerini kullan
6. Karşılaştırmalı analiz yap
7. Test adını ve sonuçları doğru kullan

Aşağıdaki 4 bölümü tam olarak yaz:

1. GENEL DEĞERLENDİRME:
$testName testinde en iyi performans gösteren sporcuyu ve sonucunu belirt. En çok gelişim potansiyeli olan sporcuyu belirt. Grup ortalaması hakkında detaylı değerlendirme yap. Performans dağılımını açıkla.

2. YAŞ VE CİNSİYET FAKTÖRLERİ:
$testName testinde yaş gruplarına göre performans dağılımını değerlendir. Cinsiyet bazlı performans farklılıklarını belirt. Yaş-cinsiyet etkileşimini detaylı açıkla. Hangi yaş ve cinsiyet gruplarının daha iyi performans gösterdiğini belirt.

3. BİREYSEL GELİŞİM ÖNERİLERİ:
$testName testi için her sporcu için 1-2 spesifik gelişim alanı belirt. Grup içi rekabet avantajlarını detaylı açıkla. Bireysel antrenman ihtiyaçlarını belirt. Her sporcunun güçlü yönlerini vurgula.

4. TAKIM STRATEJİSİ:
$testName testi performansını artıracak 2-3 spesifik öneri ver. Sporcu eşleştirme önerilerini detaylı açıkla. Grup antrenmanı fırsatlarını belirt. Uzun vadeli gelişim planı önerilerini kısaca açıkla.

ÖNEMLİ: Her bölümü tamamla ve yarım bırakma! Test adını ve sonuçları doğru kullan!
''';

    return await generateContent(prompt);
  }

  static Future<String?> generateTeamAnalysis({
    required List<Map<String, dynamic>> results,
    required String testName,
  }) async {
    // Debug bilgileri
    print('=== TAKIM ANALİZ VERİLERİ ===');
    print('Test: $testName');
    print('Sporcu sayısı: ${results.length}');
    
    // Test sonuçlarını formatla
    final resultsText = results.map((result) {
      final athlete = result['athlete'];
      final testResult = result['result'];
      final unit = result['unit'];
      
      print('Sporcu: ${athlete['name']} ${athlete['surname']} - Ham sonuç: $testResult $unit');
      
      String formattedResult = '';
      if (unit == 'Seviye.Mekik') {
        final level = testResult.floor();
        final shuttle = ((testResult - level) * 10).round();
        formattedResult = 'Seviye $level, Mekik $shuttle';
        print('  Yo-Yo Formatı: $formattedResult');
      } else if (unit == 'Seviye') {
        formattedResult = 'Seviye ${testResult.toStringAsFixed(1)}';
        print('  Beep Test Formatı: $formattedResult');
      } else {
        formattedResult = '${testResult.toStringAsFixed(2)} $unit';
        print('  Normal Format: $formattedResult');
      }
      
      return '''
        - ${athlete['name']} ${athlete['surname']} (${athlete['age']} yaş, ${athlete['gender']}): $formattedResult
        ''';
    }).join('\n');

    print('==============================');

    final prompt = '''
Sen deneyimli bir spor antrenörüsün. Aşağıdaki takım test verilerini analiz et.

TEST BİLGİLERİ:
- Test Adı: $testName
- Katılımcı Sayısı: ${results.length}

SPORCU SONUÇLARI:
$resultsText

KURALLAR:
1. Her bölümü MUTLAKA tamamla
2. Yarım cümle bırakma
3. Her bölüm en az 30 kelime olsun
4. Spesifik ve detaylı yaz
5. Sporcu isimlerini kullan
6. Test adını ve sonuçları doğru kullan
7. Ham sonuç değerlerini doğru algıla

Aşağıdaki 3 bölümü tam olarak yaz:

1. GENEL DEĞERLENDİRME:
$testName testinde en iyi performans gösteren sporcuyu ve sonucunu belirt. En zayıf performans gösteren sporcuyu ve sonucunu belirt. Genel grup performansını değerlendir. Ortalama seviyeyi kısaca açıkla.

2. TAKIM SEVİYESİ:
Takımın $testName testindeki genel seviyesini değerlendir. Ortalama performans seviyesini belirt. Takımın güçlü yönlerini açıkla. Takımın zayıf yönlerini belirt. Genel takım potansiyelini değerlendir.

3. GELİŞİM ÖNERİSİ:
$testName testi performansını artırmak için 2-3 spesifik öneri ver. Her öneriyi detaylı açıkla. Bu önerilerin nasıl uygulanacağını belirt. Beklenen faydaları kısaca açıkla.

ÖNEMLİ: Her bölümü tamamla ve yarım bırakma! Test adını ve sonuçları doğru kullan!
''';

    print('=== TAKIM AI PROMPT GÖNDERİLİYOR ===');
    print('Prompt uzunluğu: ${prompt.length} karakter');
    print('Test adı: $testName');
    print('==============================');

    return await generateContent(prompt);
  }
} 