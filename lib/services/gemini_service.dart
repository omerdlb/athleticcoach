import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../data/models/athlete_model.dart';
import '../data/models/test_result_model.dart';

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
    if (resultUnit == 'Seviye') {
      // Yo-Yo testleri ve Beep test için seviye formatı
      formattedResult = 'Seviye ${result.toStringAsFixed(1)}';
      print('=== SEVİYE TEST FORMATLAMA ===');
      print('Ham Sonuç: $result');
      print('Formatlanmış: $formattedResult');
      print('=============================');
    } else {
      // Diğer testler için normal format
      formattedResult = '${result.toStringAsFixed(2)} $resultUnit';
      print('Normal Format: $formattedResult (Ham: $result)');
    }
    
    print('Final Formatlanmış Sonuç: $formattedResult');
    
    final prompt = '''
Sporcu: $athleteName $athleteSurname | Yaş: $age | Cinsiyet: $gender | Branş: $branch | Boy: ${height.toStringAsFixed(1)} cm | Kilo: ${weight.toStringAsFixed(1)} kg (BMI ${bmi.toStringAsFixed(1)})
Test: $testName – Sonuç: $formattedResult (ham: $result $resultUnit) | Not: ${notes ?? 'Yok'}

Aşağıdaki net formatta, anlaşılır Türkçe ile cevap ver (gereksiz süslü kelimelerden kaçın):
1. Değerlendirme (≤3 cümle; sonucu kısaca açıkla, iyi/kötü derecelendir)
2. Güçlü Yönler (• 2 madde)
3. Geliştirilecek Yönler (• 2 madde)
4. Önerilen Egzersizler (• 3 madde; her madde 1 satırı geçmesin)
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
      if (unit == 'Seviye') {
        formattedResult = 'Seviye ${testResult.toStringAsFixed(1)}';
        print('Comparative Analysis - Seviye Format: ${athlete['name']} → $formattedResult (Ham: $testResult)');
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
      if (unit == 'Seviye') {
        formattedResult = 'Seviye ${testResult.toStringAsFixed(1)}';
        print('Team Analysis - Seviye Format: ${athlete.name} → $formattedResult (Ham: $testResult)');
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

  // SPORCU TREND ANALİZİ (Zaman içindeki gelişim)
  static Future<String?> generateTrendAnalysis({
    required AthleteModel athlete,
    required String testName,
    required List<TestResultModel> results,
  }) async {
    if (results.isEmpty) return 'Yeterli veri bulunamadı.';

    // Sonuçları tarih sırasına göre sırala
    results.sort((a, b) => a.testDate.compareTo(b.testDate));

    final resultsText = results.map((r) {
      final dateStr = '${r.testDate.day.toString().padLeft(2, '0')}.${r.testDate.month.toString().padLeft(2, '0')}.${r.testDate.year}';
      return '- $dateStr: ${r.result.toStringAsFixed(2)} ${r.resultUnit}';
    }).join('\n');

    final prompt = '''
Sadece aşağıdaki verilere bakarak, kısa ve net bir değerlendirme yap.

Sporcu: ${athlete.name} ${athlete.surname} | Yaş: ${DateTime.now().year - athlete.birthDate.year} | Cinsiyet: ${athlete.gender} | Branş: ${athlete.branch}
Test: $testName

Ölçümler (tarih – değer):
$resultsText

Cevap formatı (Türkçe):
1. Genel Eğilim (en fazla 2 cümle)
2. Öne Çıkan Noktalar (• 2-3 madde)
3. Gelişim Önerileri (• 2-3 madde)

Tarih ve değerleri gerektiği yerde kısaca kullan. Uzun paragraflardan kaçın, sade ve anlaşılır yaz.
''';

    return await generateContent(prompt);
  }

  // SPORCU KARŞILAŞTIRMA ANALİZİ
  static Future<String?> compareAthletes({
    required AthleteModel athlete1,
    required AthleteModel athlete2,
    required List<TestResultModel> athlete1Results,
    required List<TestResultModel> athlete2Results,
  }) async {
    // Sporcu bilgilerini formatla
    final athlete1Info = '''
${athlete1.name} ${athlete1.surname}:
- Yaş: ${DateTime.now().year - athlete1.birthDate.year}
- Cinsiyet: ${athlete1.gender}
- Branş: ${athlete1.branch}
- Boy: ${athlete1.height} cm
- Kilo: ${athlete1.weight} kg
''';

    final athlete2Info = '''
${athlete2.name} ${athlete2.surname}:
- Yaş: ${DateTime.now().year - athlete2.birthDate.year}
- Cinsiyet: ${athlete2.gender}
- Branş: ${athlete2.branch}
- Boy: ${athlete2.height} cm
- Kilo: ${athlete2.weight} kg
''';

    // Test sonuçlarını formatla
    String athlete1ResultsText = '';
    if (athlete1Results.isNotEmpty) {
      athlete1ResultsText = athlete1Results.take(5).map((r) {
        final dateStr = '${r.testDate.day.toString().padLeft(2, '0')}.${r.testDate.month.toString().padLeft(2, '0')}.${r.testDate.year}';
        String formattedResult = '';
        if (r.resultUnit == 'Seviye') {
          formattedResult = 'Seviye ${r.result.toStringAsFixed(1)}';
        } else {
          formattedResult = '${r.result.toStringAsFixed(2)} ${r.resultUnit}';
        }
        return '- $dateStr: ${r.testName} → $formattedResult';
      }).join('\n');
    } else {
      athlete1ResultsText = '- Henüz test sonucu bulunmuyor';
    }

    String athlete2ResultsText = '';
    if (athlete2Results.isNotEmpty) {
      athlete2ResultsText = athlete2Results.take(5).map((r) {
        final dateStr = '${r.testDate.day.toString().padLeft(2, '0')}.${r.testDate.month.toString().padLeft(2, '0')}.${r.testDate.year}';
        String formattedResult = '';
        if (r.resultUnit == 'Seviye') {
          formattedResult = 'Seviye ${r.result.toStringAsFixed(1)}';
        } else {
          formattedResult = '${r.result.toStringAsFixed(2)} ${r.resultUnit}';
        }
        return '- $dateStr: ${r.testName} → $formattedResult';
      }).join('\n');
    } else {
      athlete2ResultsText = '- Henüz test sonucu bulunmuyor';
    }

    final prompt = '''
Sen deneyimli bir spor antrenörüsün. İki sporcuyu karşılaştırmalı olarak analiz et.

SPORCU BİLGİLERİ:

${athlete1.name} ${athlete1.surname}:
$athlete1Info

Son Test Sonuçları:
$athlete1ResultsText

${athlete2.name} ${athlete2.surname}:
$athlete2Info

Son Test Sonuçları:
$athlete2ResultsText

KURALLAR:
1. Her bölümü MUTLAKA tamamla
2. Yarım cümle bırakma
3. Her bölüm en az 40 kelime olsun
4. Spesifik ve detaylı yaz
5. Sporcu isimlerini kullan
6. Karşılaştırmalı analiz yap
7. Test sonuçlarını doğru kullan

Aşağıdaki 4 bölümü tam olarak yaz:

1. GENEL KARŞILAŞTIRMA:
İki sporcunun genel özelliklerini karşılaştır. Yaş, cinsiyet, branş ve fiziksel özellikler açısından farklılıkları belirt. Hangi sporcunun hangi açıdan avantajlı olduğunu açıkla.

2. PERFORMANS ANALİZİ:
Mevcut test sonuçlarına göre her iki sporcunun performansını değerlendir. Hangi sporcunun hangi testlerde daha iyi performans gösterdiğini belirt. Performans farklılıklarının nedenlerini açıkla.

3. GÜÇLÜ YÖNLER:
Her sporcunun güçlü yönlerini ayrı ayrı belirt. Hangi alanlarda öne çıktıklarını açıkla. Bu güçlü yönlerin nasıl geliştirilebileceğini kısaca belirt.

4. GELİŞİM ÖNERİLERİ:
Her sporcu için 2-3 spesifik gelişim önerisi ver. Bu önerilerin nasıl uygulanacağını açıkla. Hangi sporcunun hangi alanlarda daha fazla çalışması gerektiğini belirt.

ÖNEMLİ: Her bölümü tamamla ve yarım bırakma! Sporcu isimlerini ve test sonuçlarını doğru kullan!
''';

    return await generateContent(prompt);
  }
} 