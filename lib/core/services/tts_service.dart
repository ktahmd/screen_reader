import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TtsService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final FlutterTts _flutterTts = FlutterTts();

  static List<String> _textChunks = [];
  static int _currentChunkIndex = 0;
  static bool _isPlayingOnline = false;

  static Future<void> init() async {
    _audioPlayer.onPlayerComplete.listen((event) {
      if (_isPlayingOnline) {
        _currentChunkIndex++;
        if (_currentChunkIndex < _textChunks.length) {
          _playCurrentChunk();
        } else {
          _isPlayingOnline = false;
        }
      }
    });

    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.45); 
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  static Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  static Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    await stop(); 

    bool hasConnection = await _hasInternet();

    if (hasConnection) {
      debugPrint("🌐 TTS: Using High-Quality Online Voice");
      _textChunks = _splitTextIntoChunks(text, 150);
      _currentChunkIndex = 0;
      _isPlayingOnline = true;
      await _playCurrentChunk();
    } else {
      debugPrint("📴 TTS: No Internet. Using Offline Robotic Voice");
      await _flutterTts.speak(text); 
    }
  }

  static Future<void> _playCurrentChunk() async {
    if (!_isPlayingOnline || _currentChunkIndex >= _textChunks.length) return;

    final chunk = _textChunks[_currentChunkIndex];
    
    try {
      final url = "https://translate.google.com/translate_tts?ie=UTF-8&tl=en&client=tw-ob&q=${Uri.encodeComponent(chunk)}";
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      debugPrint("TTS Audio Error: $e");
      _isPlayingOnline = false;
      await _flutterTts.speak(chunk);
    }
  }

  static Future<void> stop() async {
    _isPlayingOnline = false;
    await _audioPlayer.stop();
    await _flutterTts.stop();
  }

  static List<String> _splitTextIntoChunks(String text, int maxLength) {
    List<String> chunks = [];
    List<String> sentences = text.split(RegExp(r'(?<=[.!?])\s+'));

    for (String sentence in sentences) {
      if (sentence.length <= maxLength) {
        chunks.add(sentence);
      } else {
        List<String> words = sentence.split(' ');
        String currentChunk = "";
        for (String word in words) {
          if ((currentChunk + word).length > maxLength) {
            chunks.add(currentChunk.trim());
            currentChunk = "$word ";
          } else {
            currentChunk += "$word ";
          }
        }
        if (currentChunk.trim().isNotEmpty) {
          chunks.add(currentChunk.trim());
        }
      }
    }
    return chunks.where((c) => c.isNotEmpty).toList();
  }
}