// foldTurkish ve displayName fonksiyonları için birim testler.

import 'package:flutter_test/flutter_test.dart';
import 'package:vakit/location/turkish_text.dart';

void main() {
  group('foldTurkish', () {
    test('brifteki temel örnekleri doğru katlar', () {
      expect(foldTurkish('Edremit (V) '), equals('EDREMIT'));
      expect(foldTurkish('başakşehir'), equals('BASAKSEHIR'));
      expect(foldTurkish('İSTANBUL'), equals('ISTANBUL'));
      expect(foldTurkish('istanbul'), equals('ISTANBUL'));
      expect(foldTurkish('Istanbul'), equals('ISTANBUL'));
    });

    test('boş metin ve boşluk içeren metinleri doğru işler', () {
      expect(foldTurkish(''), equals(''));
      expect(foldTurkish('   '), equals(''));
      expect(foldTurkish('(V)'), equals(''));
      expect(foldTurkish('  (V)  '), equals(''));
      expect(foldTurkish('  başak    şehir  (V)   '), equals('BASAK SEHIR'));
    });

    test('tüm Türkçe özel harfleri ASCII büyük harfe katlar', () {
      expect(foldTurkish('çilek ÇİLEK'), equals('CILEK CILEK'));
      expect(foldTurkish('dağ DAĞ'), equals('DAG DAG'));
      expect(
        foldTurkish('ışık IŞIK ilik İLİK'),
        equals('ISIK ISIK ILIK ILIK'),
      );
      expect(foldTurkish('ördek ÖRDEK'), equals('ORDEK ORDEK'));
      expect(foldTurkish('şeker ŞEKER'), equals('SEKER SEKER'));
      expect(foldTurkish('üzüm ÜZÜM'), equals('UZUM UZUM'));
    });

    test('şapkalı sesli harfleri doğru katlar', () {
      expect(foldTurkish('kâğıt KÂĞIT'), equals('KAGIT KAGIT'));
      expect(foldTurkish('millî MİLLÎ'), equals('MILLI MILLI'));
      expect(foldTurkish('sükût SÜKÛT'), equals('SUKUT SUKUT'));
      expect(foldTurkish('lôdos LÔDOS'), equals('LODOS LODOS'));
      expect(foldTurkish('ê Ê'), equals('E E'));
    });

    test('ASCII harfleri ve sayıları korur', () {
      expect(
        foldTurkish('The Quick Brown Fox'),
        equals('THE QUICK BROWN FOX'),
      );
      expect(foldTurkish('34-istanbul 100%'), equals('34-ISTANBUL 100%'));
    });
  });

  group('displayName', () {
    test('brifteki temel örnekleri doğru biçimlendirir', () {
      expect(displayName('BAŞAKŞEHİR'), equals('Başakşehir'));
      expect(displayName('İSTANBUL'), equals('İstanbul'));
      expect(displayName('ŞEREFLİKOÇHİSAR'), equals('Şereflikoçhisar'));
      expect(displayName('EDREMİT (V)'), equals('Edremit'));
      expect(displayName('ARNAVUTKOY'), equals('Arnavutkoy'));
    });

    test('farklı ilçe ve şehir adı tuhaflıklarını doğru biçimlendirir', () {
      expect(displayName('SARAY (V)'), equals('Saray'));
      expect(displayName('CUBUK'), equals('Cubuk'));
      expect(displayName('IĞDIR'), equals('Iğdır'));
      expect(displayName('DİYARBAKIR'), equals('Diyarbakır'));
      expect(displayName('ISPARTA'), equals('Isparta'));
    });

    test('küçük harfle gelen girdileri Türkçe kurallarla büyütür', () {
      expect(displayName('isparta'), equals('İsparta'));
      expect(displayName('ısparta'), equals('Isparta'));
      expect(displayName('istanbul'), equals('İstanbul'));
      expect(displayName('şile'), equals('Şile'));
    });

    test('boş ve parantezli durumları doğru işler', () {
      expect(displayName(''), equals(''));
      expect(displayName('   '), equals(''));
      expect(displayName('(V)'), equals(''));
      expect(displayName('  (V)  '), equals(''));
      expect(displayName('   BAŞAKŞEHİR    (V)   '), equals('Başakşehir'));
    });

    test('çok kelimeli adları ve şapkalı harfleri doğru biçimlendirir', () {
      expect(displayName('KARA DENİZ'), equals('Kara Deniz'));
      expect(displayName('KÂĞITHANE'), equals('Kâğıthane'));
      expect(displayName('MİLLÎ'), equals('Millî'));
      expect(displayName('SÜKÛT'), equals('Sükût'));
      expect(displayName('1. BÖLGE'), equals('1. Bölge'));
    });
  });
}
