import 'package:flutter/material.dart';

/// An original caller. All characters and lines are invented for this app:
/// no real people, no copyrighted meme characters or audio.
class Caller {
  const Caller({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.language,
    required this.pitch,
    required this.rate,
    required this.lines,
  });

  final String id;
  final String name;
  final String subtitle;
  final String emoji;
  final Color color;

  /// Text-to-speech language, e.g. 'bn-IN', 'hi-IN', 'en-IN'.
  final String language;
  final double pitch;
  final double rate;

  /// Spoken one after another once the call is answered.
  final List<String> lines;
}

const callers = <Caller>[
  Caller(
    id: 'pishi',
    name: 'Pishi-ma',
    subtitle: 'Bengali aunt · wants news',
    emoji: '👵',
    color: Color(0xFFE76F51),
    language: 'bn-IN',
    pitch: 1.3,
    rate: 0.45,
    lines: [
      'হ্যালো! কি রে, কেমন আছিস?',
      'কতদিন ফোন করিস না! ভাত খেয়েছিস তো?',
      'শোন, পাড়ার মেয়েটার বিয়ে হয়ে গেল। তোর কবে?',
      'আচ্ছা আচ্ছা, রাখছি। মা কে বলিস ফোন করতে!',
    ],
  ),
  Caller(
    id: 'boss',
    name: 'Boss Babu',
    subtitle: 'Hindi · deadline today',
    emoji: '👔',
    color: Color(0xFF264653),
    language: 'hi-IN',
    pitch: 0.8,
    rate: 0.5,
    lines: [
      'हेलो! रिपोर्ट कहाँ है?',
      'मैंने कल ही बोला था, आज शाम तक चाहिए!',
      'छुट्टी? इस हफ्ते तो बिल्कुल नहीं।',
      'ठीक है, जल्दी भेजो। बाय!',
    ],
  ),
  Caller(
    id: 'tiffin',
    name: 'Tiffin Dada',
    subtitle: 'Bengali · lunch is coming',
    emoji: '🍱',
    color: Color(0xFF2A9D8F),
    language: 'bn-IN',
    pitch: 1.0,
    rate: 0.5,
    lines: [
      'দাদা, আপনার টিফিন রেডি!',
      'আজ মাছের ঝোল আর ভাত, সঙ্গে আলু পোস্ত।',
      'পাঁচ মিনিটে পৌঁছে যাচ্ছি, গেটে আসুন!',
    ],
  ),
  Caller(
    id: 'chacha',
    name: 'Cricket Chacha',
    subtitle: 'Hindi · last over!',
    emoji: '🏏',
    color: Color(0xFF3A86FF),
    language: 'hi-IN',
    pitch: 1.1,
    rate: 0.55,
    lines: [
      'अरे! मैच देख रहे हो?',
      'आखिरी ओवर, छह रन चाहिए!',
      'छक्का! मैंने कहा था ना!',
    ],
  ),
  Caller(
    id: 'dadu',
    name: 'Dadu',
    subtitle: 'Bengali · evening plans',
    emoji: '👴',
    color: Color(0xFF8D5A97),
    language: 'bn-IN',
    pitch: 0.7,
    rate: 0.4,
    lines: [
      'হ্যালো দাদুভাই!',
      'আজ সন্ধ্যেবেলা চলে আয়, মুড়ি আর চপ খাব।',
      'দেরি করিস না কিন্তু!',
    ],
  ),
  Caller(
    id: 'robo',
    name: 'Robo Rinku',
    subtitle: 'English · beep boop',
    emoji: '🤖',
    color: Color(0xFF6C757D),
    language: 'en-IN',
    pitch: 1.6,
    rate: 0.6,
    lines: [
      'Beep boop. Hello human.',
      'This is your friendly reminder to drink water.',
      'Also, you have been scrolling for too long. Beep. Goodbye.',
    ],
  ),
];

Caller callerById(String? id) =>
    callers.firstWhere((c) => c.id == id, orElse: () => callers.first);
