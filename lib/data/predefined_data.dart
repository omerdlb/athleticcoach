import 'package:athleticcoach/data/models/test_definition_model.dart';

final List<TestDefinitionModel> predefinedTests = [
  // Aerobik Testler
  TestDefinitionModel(
    id: 'yo-yo-ir1',
    name: 'Yo-Yo Intermittent Recovery Test Level 1',
    category: 'Aerobik',
    description: 'Tekrarlı sprint ve aerobik kapasiteyi ölçer.',
    protocol: '''
**Parkur Hazırlığı:**
1. 20 metrelik düz bir parkur hazırlanır, iki uca işaret konur.
2. Sinyal ses kaydı ve kronometre hazır edilir.

**Uygulama:**
1. Katılımcı, sinyal sesiyle bir uçtan diğer uca koşar.
2. Her mekik sonrası 10 saniye aktif dinlenme (yavaş yürüyüş) yapılır.
3. Sinyale yetişilemezse uyarı verilir, üst üste iki kez yetişilemezse test biter.
4. Test boyunca sesli sinyal kaydı ve kronometre kullanılır.

**Sonuç ve Puanlama:**
- Son tamamlanan seviye ve mekik sayısı kaydedilir.
- Toplam koşulan mesafe = (mekik sayısı) x 20 metre.
- VO2max tahmini için: VO2max = (mesafe x 0.0084) + 36.4
''',
    resultUnit: 'Seviye.Mekik',
  ),
  TestDefinitionModel(
    id: 'yo-yo-ir2',
    name: 'Yo-Yo Intermittent Recovery Test Level 2',
    category: 'Aerobik',
    description: 'Daha yüksek tempoda tekrarlı sprint ve aerobik kapasiteyi ölçer.',
    protocol: '''
**Parkur Hazırlığı:**
1. 20 metrelik düz bir parkur hazırlanır, iki uca işaret konur.
2. Sinyal ses kaydı ve kronometre hazır edilir.

**Uygulama:**
1. Katılımcı, sinyal sesiyle bir uçtan diğer uca koşar.
2. Her mekik sonrası 10 saniye aktif dinlenme (yavaş yürüyüş) yapılır.
3. Başlangıç hızı ve artışlar Level 1'e göre daha yüksektir.
4. Sinyale yetişilemezse uyarı verilir, üst üste iki kez yetişilemezse test biter.

**Sonuç ve Puanlama:**
- Son tamamlanan seviye ve mekik sayısı kaydedilir.
- Toplam koşulan mesafe = (mekik sayısı) x 20 metre.
- VO2max tahmini için: VO2max = (mesafe x 0.0136) + 45.3
''',
    resultUnit: 'Seviye.Mekik',
  ),
  TestDefinitionModel(
    id: 'beep-test',
    name: '20m Shuttle Run (Beep Test)',
    category: 'Aerobik',
    description: 'VO2max tahmini için en yaygın saha testlerinden.',
    protocol: '''
**Parkur Hazırlığı:**
1. 20 metrelik düz bir parkur hazırlanır, iki uca işaret konur.
2. Sinyal ses kaydı ve kronometre hazır edilir.

**Uygulama:**
1. Katılımcı, sinyal sesiyle bir uçtan diğer uca koşar.
2. Her sinyalde bir uçtan diğer uca ulaşmak zorundadır.
3. Başlangıçta tempo yavaştır, her dakika hız artar (sinyaller arasındaki süre kısalır).
4. Katılımcı sinyale yetişemezse uyarılır, üst üste iki kez yetişemezse test sonlanır.

**Sonuç ve Puanlama:**
- Son tamamlanan seviye ve mekik sayısı kaydedilir (ör: 8.5).
- Toplam mesafe = (mekik sayısı) x 20m.
- VO2max tahmini için: VO2max = (mesafe x 0.0268) - 11.3
''',
    resultUnit: 'Seviye',
  ),
  TestDefinitionModel(
    id: 'cooper',
    name: 'Cooper Testi (12 Dakika Koşu)',
    category: 'Aerobik',
    description: '12 dakikada koşulan toplam mesafe ile aerobik kapasiteyi ölçer.',
    protocol: '''
**Parkur Hazırlığı:**
1. Düz bir atletizm pisti veya ölçülü bir alan hazırlanır.
2. Kronometre ve ölçüm bandı hazır edilir.

**Uygulama:**
1. Katılımcı 12 dakika boyunca mümkün olan en uzun mesafeyi koşar.
2. Süre dolduğunda koşulan toplam mesafe ölçülür.
3. Katılımcı istediği tempoda koşabilir, gerekirse yürüyebilir.

**Sonuç ve Puanlama:**
- Sonuç, 12 dakikada koşulan toplam mesafe (metre) olarak kaydedilir.
- VO2max tahmini için: VO2max = (koşulan mesafe (metre) - 504.9) / 44.73
''',
    resultUnit: 'metre',
  ),
  TestDefinitionModel(
    id: '6min-walk',
    name: '6 Dakika Yürüme Testi',
    category: 'Aerobik',
    description: 'Submaksimal aerobik kapasiteyi ölçer.',
    protocol: '''
**Parkur Hazırlığı:**
1. Düz bir parkurda 30m veya 50m'lik bir alan belirlenir.
2. Kronometre ve ölçüm bandı hazır edilir.

**Uygulama:**
1. Katılımcı 6 dakika boyunca mümkün olan en uzun mesafeyi yürür.
2. Süre dolduğunda yürüyüş durdurulur ve toplam mesafe ölçülür.

**Sonuç ve Puanlama:**
- Sonuç, 6 dakikada yürüyerek kat edilen toplam mesafe (metre) olarak kaydedilir.
- Klinik değerlendirmelerde referans tablolara bakılır.
''',
    resultUnit: 'metre',
  ),
  TestDefinitionModel(
    id: '2.4km-run',
    name: '2.4 km Koşu Testi',
    category: 'Aerobik',
    description: 'VO2max tahmini için kullanılır.',
    protocol: '''
**Parkur Hazırlığı:**
1. 400m pistte 6 tur veya düz bir 2.4 km parkur hazırlanır.
2. Kronometre hazır edilir.

**Uygulama:**
1. Katılımcı 2.4 km mesafeyi en kısa sürede koşar.
2. Süre kaydedilir.

**Sonuç ve Puanlama:**
- Sonuç, 2.4 km'yi tamamlama süresi (saniye) olarak kaydedilir.
- VO2max tahmini için: VO2max = 483 / süre (dakika) + 3.5
''',
    resultUnit: 'saniye',
  ),
  // Anaerobik Testler
  TestDefinitionModel(
    id: 'rast',
    name: 'RAST (Running-based Anaerobic Sprint Test)',
    category: 'Anaerobik',
    description: 'Kısa mesafe sprintlerle anaerobik gücü ölçer.',
    protocol: '''
**Parkur Hazırlığı:**
1. 35 metrelik düz bir parkur hazırlanır.
2. Kronometre hazır edilir.

**Uygulama:**
1. Katılımcı 6 kez 35 metreyi maksimum hızda koşar.
2. Her koşu arası 10 saniye dinlenir.
3. Her koşunun süresi kronometreyle ölçülür.

**Sonuç ve Puanlama:**
- Her sprintin süresi kaydedilir.
- En yüksek, en düşük ve ortalama güç hesaplanır:
  Güç (Watt) = (Vücut ağırlığı x mesafe²) / süre³
- Yorgunluk indeksi de hesaplanabilir.
''',
    resultUnit: 'saniye',
  ),
  TestDefinitionModel(
    id: 'wingate',
    name: 'Wingate Anaerobik Testi',
    category: 'Anaerobik',
    description: '30 sn bisiklet ergometresinde maksimum güç ve yorgunluk ölçümü.',
    protocol: '''
**Ekipman:**
- Bisiklet ergometresi, kronometre, ağırlıklar.

**Uygulama:**
1. Katılımcı 30 saniye boyunca maksimum hızda pedal çevirir.
2. Sabit direnç uygulanır (genellikle vücut ağırlığının %7.5'i).
3. Her 5 saniyede bir devir sayısı kaydedilir.

**Sonuç ve Puanlama:**
- En yüksek güç, ortalama güç ve yorgunluk indeksi hesaplanır.
- Güç (Watt) = (Ağırlık x toplam devir x pedal çevresi) / süre
''',
    resultUnit: 'Watt',
  ),
  TestDefinitionModel(
    id: 'margaria',
    name: 'Margaria-Kalamen Testi',
    category: 'Anaerobik',
    description: 'Basamak çıkma ile anaerobik gücü ölçer.',
    protocol: '''
**Parkur Hazırlığı:**
1. 9 basamaklı bir merdiven hazırlanır, 3. ve 9. basamaklar işaretlenir.
2. Kronometre hazır edilir.

**Uygulama:**
1. Katılımcı 6m mesafeden koşarak gelir, 3. basamaktan 9. basamağa en kısa sürede çıkar.
2. Süre kaydedilir.

**Sonuç ve Puanlama:**
- Güç (Watt) = (Ağırlık x 9.81 x yükseklik) / süre
- En iyi deneme kaydedilir.
''',
    resultUnit: 'Watt',
  ),
  // Güç/Patlayıcı Güç
  TestDefinitionModel(
    id: 'vertical-jump',
    name: 'Dikey Sıçrama (Vertical Jump)',
    category: 'Patlayıcı Güç',
    description: 'Alt ekstremite patlayıcı gücünü ölçer.',
    protocol: '''
**Parkur Hazırlığı:**
1. Düz bir duvar ve tebeşir veya özel ölçüm cihazı hazırlanır.

**Uygulama:**
1. Katılımcı duvara yan döner, kollar yukarıda uzanabildiği en yüksek noktayı işaretler.
2. Sonra hızlıca çömelip maksimum yükseklikte sıçrar ve tekrar işaret bırakır.
3. 3 deneme yapılır, en iyi sonuç alınır.

**Sonuç ve Puanlama:**
- Sıçrama yüksekliği = Sıçrama sonrası işaret - başlangıç işareti (cm).
- En iyi değer kaydedilir.
''',
    resultUnit: 'cm',
  ),
  TestDefinitionModel(
    id: 'cmj',
    name: 'Countermovement Jump (CMJ)',
    category: 'Patlayıcı Güç',
    description: 'Diz bükülerek yapılan sıçrama ile patlayıcı güç ölçümü.',
    protocol: '''
**Parkur Hazırlığı:**
1. Düz bir zemin ve ölçüm cihazı hazırlanır.

**Uygulama:**
1. Eller kalçada, dizler bükülüp hızla yukarı sıçranır.
2. Sıçrama yüksekliği ölçülür.
3. 3 deneme yapılır, en iyi sonuç alınır.

**Sonuç ve Puanlama:**
- Sıçrama yüksekliği (cm) olarak kaydedilir.
- En iyi değer alınır.
''',
    resultUnit: 'cm',
  ),
  TestDefinitionModel(
    id: 'medicine-ball',
    name: 'Medicine Ball Throw',
    category: 'Patlayıcı Güç',
    description: 'Üst vücut patlayıcı gücünü ölçer.',
    protocol: '''
**Parkur Hazırlığı:**
1. 2-3 kg'lık bir sağlık topu ve ölçüm bandı hazırlanır.

**Uygulama:**
1. Katılımcı oturur pozisyonda, göğüsten topu maksimum mesafeye fırlatır.
2. 3 deneme yapılır, en iyi sonuç alınır.

**Sonuç ve Puanlama:**
- Fırlatılan mesafe (metre) olarak kaydedilir.
- En iyi değer alınır.
''',
    resultUnit: 'metre',
  ),
  // Çeviklik
  TestDefinitionModel(
    id: 'illinois',
    name: 'Illinois Çeviklik Testi',
    category: 'Çeviklik',
    description: 'Saha üzerinde konilerle çeviklik ölçümü.',
    protocol: '''
**Parkur Hazırlığı:**
1. 10m uzunluğunda ve 5m genişliğinde bir parkur hazırlanır.
2. 4 koni ortada, 4 koni köşelerde olacak şekilde dizilir.
3. Kronometre hazır edilir.

**Uygulama:**
1. Katılımcı yere yatar pozisyonda başlar.
2. Başla komutuyla kalkıp parkuru belirlenen sırayla en kısa sürede tamamlar.
3. Her deneme için kronometre kullanılır.

**Sonuç ve Puanlama:**
- Sonuç, parkuru tamamlama süresi (saniye) olarak kaydedilir.
- Daha kısa süre, daha iyi çeviklik anlamına gelir.
''',
    resultUnit: 'saniye',
  ),
  TestDefinitionModel(
    id: 't-test',
    name: 'T-Test',
    category: 'Çeviklik',
    description: 'T şeklinde parkurda ileri, yan ve geri koşu ile çeviklik ölçümü.',
    protocol: '''
**Parkur Hazırlığı:**
1. T şeklinde dizilmiş 4 koni ve kronometre hazırlanır.

**Uygulama:**
1. Katılımcı başlangıç konisinden başlar.
2. Belirlenen sırayla ileri, yan ve geri koşu yapar.
3. Süre kaydedilir.

**Sonuç ve Puanlama:**
- Sonuç, parkuru tamamlama süresi (saniye) olarak kaydedilir.
- Daha kısa süre, daha iyi çeviklik anlamına gelir.
''',
    resultUnit: 'saniye',
  ),
  TestDefinitionModel(
    id: 'pro-agility',
    name: '5-10-5 Pro Agility Test',
    category: 'Çeviklik',
    description: 'Kısa mesafede yön değiştirme çevikliğini ölçer.',
    protocol: '''
**Parkur Hazırlığı:**
1. 5-10-5 yard arası işaretlenir, kronometre hazırlanır.

**Uygulama:**
1. Katılımcı ortadaki çizgiden başlar.
2. Bir yana 5 yard, diğer yana 10 yard, tekrar 5 yard koşar.
3. Süre kaydedilir.

**Sonuç ve Puanlama:**
- Sonuç, toplam süre (saniye) olarak kaydedilir.
- Daha kısa süre, daha iyi çeviklik anlamına gelir.
''',
    resultUnit: 'saniye',
  ),
  // Sürat
  TestDefinitionModel(
    id: '10m-sprint',
    name: '10m Sprint',
    category: 'Sürat',
    description: 'Kısa mesafede hız ölçümü.',
    protocol: '''
**Parkur Hazırlığı:**
1. 10 metrelik düz bir parkur hazırlanır.
2. Kronometre veya fotosel sistemi kurulur.

**Uygulama:**
1. Katılımcı başlangıç çizgisinden başlar.
2. 10 metreyi en kısa sürede koşar.
3. Süre kaydedilir.

**Sonuç ve Puanlama:**
- Sonuç, 10 metreyi tamamlama süresi (saniye) olarak kaydedilir.
- Daha kısa süre, daha iyi sürat anlamına gelir.
''',
    resultUnit: 'saniye',
  ),
  TestDefinitionModel(
    id: '20m-sprint',
    name: '20m Sprint',
    category: 'Sürat',
    description: 'Kısa mesafede hız ölçümü.',
    protocol: '''
**Parkur Hazırlığı:**
1. 20 metrelik düz bir parkur hazırlanır.
2. Kronometre veya fotosel sistemi kurulur.

**Uygulama:**
1. Katılımcı başlangıç çizgisinden başlar.
2. 20 metreyi en kısa sürede koşar.
3. Süre kaydedilir.

**Sonuç ve Puanlama:**
- Sonuç, 20 metreyi tamamlama süresi (saniye) olarak kaydedilir.
- Daha kısa süre, daha iyi sürat anlamına gelir.
''',
    resultUnit: 'saniye',
  ),
  TestDefinitionModel(
    id: '30m-sprint',
    name: '30m Sprint',
    category: 'Sürat',
    description: 'Kısa mesafede hız ölçümü.',
    protocol: '''
**Parkur Hazırlığı:**
1. 30 metrelik düz bir parkur hazırlanır.
2. Kronometre veya fotosel sistemi kurulur.

**Uygulama:**
1. Katılımcı başlangıç çizgisinden başlar.
2. 30 metreyi en kısa sürede koşar.
3. Süre kaydedilir.

**Sonuç ve Puanlama:**
- Sonuç, 30 metreyi tamamlama süresi (saniye) olarak kaydedilir.
- Daha kısa süre, daha iyi sürat anlamına gelir.
''',
    resultUnit: 'saniye',
  ),
  // Esneklik
  TestDefinitionModel(
    id: 'sit-reach',
    name: 'Sit and Reach (Otur-Uzan) Testi',
    category: 'Esneklik',
    description: 'Bel ve hamstring esnekliğini ölçer.',
    protocol: '''
**Parkur Hazırlığı:**
1. Otur-uzan kutusu veya cetvel hazırlanır.

**Uygulama:**
1. Katılımcı ayak tabanları kutuya dayalı şekilde oturur.
2. Eller üst üste, öne doğru en uzağa uzanır.
3. Uzanılan mesafe kutu veya cetvel üzerinden okunur.

**Sonuç ve Puanlama:**
- Sonuç, uzanılan mesafe (cm) olarak kaydedilir.
- Daha uzun mesafe, daha iyi esneklik anlamına gelir.
''',
    resultUnit: 'cm',
  ),
  TestDefinitionModel(
    id: 'shoulder-flex',
    name: 'Shoulder Flexibility Test',
    category: 'Esneklik',
    description: 'Omuz eklemi esnekliğini ölçer.',
    protocol: '''
**Parkur Hazırlığı:**
1. 1 metre uzunluğunda bir çubuk hazırlanır.

**Uygulama:**
1. Katılımcı çubuğu iki el ile tutar.
2. Kollar düz, çubuk baş üzerinden arkaya doğru götürülür.
3. Eller arası mesafe ölçülür.

**Sonuç ve Puanlama:**
- Sonuç, eller arası mesafe (cm) olarak kaydedilir.
- Daha kısa mesafe, daha iyi omuz esnekliği anlamına gelir.
''',
    resultUnit: 'cm',
  ),
  // Dayanıklılık
  TestDefinitionModel(
    id: 'yo-yo-endurance',
    name: 'Yo-Yo Endurance Test',
    category: 'Dayanıklılık',
    description: 'Uzun süreli tekrarlı koşu ile dayanıklılık ölçümü.',
    protocol: '''
**Parkur Hazırlığı:**
1. 20 metrelik düz bir parkur hazırlanır.
2. Sinyal ses kaydı ve kronometre hazır edilir.

**Uygulama:**
1. Katılımcı, sinyal sesiyle bir uçtan diğer uca koşar.
2. Dinlenme yoktur, tempo giderek artar.
3. Sinyale yetişilemezse test biter.

**Sonuç ve Puanlama:**
- Son tamamlanan seviye ve mekik sayısı kaydedilir.
- Toplam mesafe = (mekik sayısı) x 20m.
''',
    resultUnit: 'Seviye',
  ),
  TestDefinitionModel(
    id: 'harvard-step',
    name: 'Harvard Step Test',
    category: 'Dayanıklılık',
    description: 'Basamak çıkma ile kardiyovasküler dayanıklılık ölçümü.',
    protocol: '''
**Ekipman:**
- 45 cm yüksekliğinde basamak, kronometre.

**Uygulama:**
1. Katılımcı 5 dakika boyunca belirli tempoda basamağa çıkar ve iner (erkek: dakikada 30, kadın: 22).
2. Test bitince nabız 1., 2. ve 3. dakikalarda ölçülür.

**Sonuç ve Puanlama:**
- Harvard Step Test Puanı = (Test süresi (sn) x 100) / (toplam nabız x 2)
- Daha yüksek puan, daha iyi dayanıklılık.
''',
    resultUnit: 'puan',
  ),
  // Saha/İndirekt Testler
  TestDefinitionModel(
    id: 'astrand',
    name: 'Astrand-Rhyming Cycle Ergometer Test',
    category: 'İndirekt (Submaksimal)',
    description: 'Bisiklet ergometresi ile submaksimal VO2max tahmini.',
    protocol: '''
**Ekipman:**
- Bisiklet ergometresi, nabız ölçer, kronometre.

**Uygulama:**
1. Katılımcı 6 dakika sabit tempoda bisiklet çevirir (erkek: 600 kgm/dk, kadın: 450 kgm/dk).
2. Son 2 dakikada nabız sabitlenmiş olmalı.

**Sonuç ve Puanlama:**
- VO2max, yük ve nabız değerlerine göre özel tablo veya formülle hesaplanır.
''',
    resultUnit: 'ml/kg/dk',
  ),
  TestDefinitionModel(
    id: 'balke',
    name: 'Balke Testi',
    category: 'İndirekt (Submaksimal)',
    description: 'Koşu bandında submaksimal dayanıklılık testi.',
    protocol: '''
**Ekipman:**
- Koşu bandı, kronometre.

**Uygulama:**
1. Katılımcı koşu bandında sabit hızda (5.3 km/s) koşar.
2. Her dakika eğim %1 artırılır.
3. Katılımcı yorulana kadar devam eder.

**Sonuç ve Puanlama:**
- Toplam süre (saniye) kaydedilir.
- VO2max, süre ve eğime göre hesaplanır.
''',
    resultUnit: 'saniye',
  ),
  TestDefinitionModel(
    id: 'bruce',
    name: 'Bruce Protokolü',
    category: 'İndirekt (Submaksimal)',
    description: 'Koşu bandında artan hız ve eğimle yapılan submaksimal test.',
    protocol: '''
**Ekipman:**
- Koşu bandı, kronometre.

**Uygulama:**
1. Her 3 dakikada bir koşu bandının hızı ve eğimi artırılır.
2. Katılımcı yorulana kadar devam eder.

**Sonuç ve Puanlama:**
- Toplam süre (dakika) kaydedilir.
- VO2max, süreye göre özel formülle hesaplanır.
''',
    resultUnit: 'dk',
  ),
]; 