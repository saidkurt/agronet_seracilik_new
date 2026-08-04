import 'package:flutter/material.dart';

class App {
  static final String appbarString = 'Agronet Seracılık A.Ş';
  static final String outsideurl= 'http://88.248.170.183:2626';
  static final String insideurl  = 'http://192.0.0.251:2626';
  static final String localurl = 'http://192.0.0.199:8085';
  Map<String, String> get drawerPageString => {
        "kutuekleDrawerTitle": "Kutu Ekle",
        "paketlemeDraweronTapMessage":
            "Sadece Paletleme Zamanında  Kullanın \n4 Saniye Sonra Menü Açılacaktır !",
        "paketlemeDrawerPageTitle": "Paketleme",
        "progressDialogmessage": "Lütfen Bekleyin..",
        "kutuekleShowMessage": "Lütfen İş Alınız !",
        "personelBilgileriPageTitle": "Personel Bilgileri",
        "paletlemeRaporuPageTitle": "Paletleme Raporu",
        "tutaRaporuPageTitle": "Tuta Raporu",
        "mesaiDurumuPageTitle": "Mesai Durumu",
        "depoDurumRaporuPageTitle": "Depo Durum Raporu",
        "dilekVeSikayetPageTitle": "Dilek Ve Şikayet",
        "mesajGonderPageTitle": "Mesaj Gönder",
        "kantarGirisTitle": "Kantar Giriş",
        "bitkiOlcumGiris":"Bitki Ölçüm Giriş",
        "paketlemeRapor":"Paketleme Raporu"
      };
  Map<String, IconData> get drawerPageIcon => {
        "paketleme": Icons.phone_android_outlined,
        "kutuEkle": Icons.add_box,
        "personelBilgileri": Icons.person,
        "tutaRaporu": Icons.account_tree,
        "mesaiDurumu": Icons.departure_board_outlined,
        "depoDurumu": Icons.analytics_outlined,
        "dilekVeSikayet": Icons.article_outlined,
        "mesajGonder": Icons.messenger_outline,
        "kantarGiris": Icons.line_weight_outlined,
      };

  Map<String, String> get loginPageString => {
        "buttonGiris": "Giriş",
        "rememberMe": "Beni Hatırla",
        "password": "Şifre",
        "id": "Kullanıcı ID",
      };
  Map<String, String> get depodurumPageString => {
        "buttonRaporuGetir": "Raporu Getir",
        "pageInfo": "Depo",
      };
  Map<String, String> get dilekVeSikayetPageString => {
        "onPressedMessage1": "Gönderildi",
        "onPressedMessage2": "Mesaj Boş Olamaz !",
        "showDialog": "Cevap Yaz",
      };
  Map<String, String> get kutuEklePageString => {
        "kutusayisi": "Kutu Sayısı",
      };
  Map<String, String> get mesajGonderPageString => {
        "textstring": "Gönder",
        "mesajyaz": "Mesaj Yaz",
        "dropDownMenuItemdDilek": "Dilek",
        "dropDownMenuItemdSikayet": "Şikayet"
      };
}
