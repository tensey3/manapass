import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 設定画面で選んだ値。端末に保存されるので、アプリを閉じても残る。
class SettingsState {
  const SettingsState({
    this.furigana = true,
    this.rubyScale = 0.5,
    this.reduceEnglish = false,
    this.themeId = 'blue',
    this.font = 'Zen Maru Gothic',
    this.themeMode = ThemeMode.system,
    this.language = 'ja',
  });

  final bool furigana; // ふりがなを表示
  final double rubyScale; // ふりがなの大きさ（本文に対する比率）
  final bool reduceEnglish; // 3回調べた単語は英語を隠す
  final String themeId; // テーマカラー
  final String font; // フォント
  final ThemeMode themeMode; // ライト / ダーク / 端末に合わせる
  final String language; // 'ja' または 'en'

  SettingsState copyWith({
    bool? furigana,
    double? rubyScale,
    bool? reduceEnglish,
    String? themeId,
    String? font,
    ThemeMode? themeMode,
    String? language,
  }) {
    return SettingsState(
      furigana: furigana ?? this.furigana,
      rubyScale: rubyScale ?? this.rubyScale,
      reduceEnglish: reduceEnglish ?? this.reduceEnglish,
      themeId: themeId ?? this.themeId,
      font: font ?? this.font,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
    );
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsController, SettingsState>(SettingsController.new);

class SettingsController extends AsyncNotifier<SettingsState> {
  // 他の機能の保存データと混ざらないように "settings." を付ける
  static const _furigana = 'settings.furigana';
  static const _rubyScale = 'settings.rubyScale';
  static const _reduceEnglish = 'settings.reduceEnglish';
  static const _themeId = 'settings.themeId';
  static const _font = 'settings.font';
  static const _themeMode = 'settings.themeMode';
  static const _language = 'settings.language';

  late SharedPreferences _prefs;

  @override
  Future<SettingsState> build() async {
    _prefs = await SharedPreferences.getInstance();
    const defaults = SettingsState();
    return SettingsState(
      furigana: _prefs.getBool(_furigana) ?? defaults.furigana,
      rubyScale: _prefs.getDouble(_rubyScale) ?? defaults.rubyScale,
      reduceEnglish: _prefs.getBool(_reduceEnglish) ?? defaults.reduceEnglish,
      themeId: _prefs.getString(_themeId) ?? defaults.themeId,
      font: _prefs.getString(_font) ?? defaults.font,
      themeMode: ThemeMode.values.asNameMap()[_prefs.getString(_themeMode)] ?? defaults.themeMode,
      language: _prefs.getString(_language) ?? defaults.language,
    );
  }

  Future<void> setFurigana(bool value) =>
      _update((s) => s.copyWith(furigana: value), () => _prefs.setBool(_furigana, value));

  Future<void> setRubyScale(double value) =>
      _update((s) => s.copyWith(rubyScale: value), () => _prefs.setDouble(_rubyScale, value));

  Future<void> setReduceEnglish(bool value) =>
      _update((s) => s.copyWith(reduceEnglish: value), () => _prefs.setBool(_reduceEnglish, value));

  Future<void> setThemeId(String value) =>
      _update((s) => s.copyWith(themeId: value), () => _prefs.setString(_themeId, value));

  Future<void> setFont(String value) =>
      _update((s) => s.copyWith(font: value), () => _prefs.setString(_font, value));

  Future<void> setThemeMode(ThemeMode value) =>
      _update((s) => s.copyWith(themeMode: value), () => _prefs.setString(_themeMode, value.name));

  Future<void> setLanguage(String value) =>
      _update((s) => s.copyWith(language: value), () => _prefs.setString(_language, value));

  /// 画面をすぐ更新してから、端末に保存する。
  Future<void> _update(SettingsState Function(SettingsState) change, Future<bool> Function() save) async {
    final current = await future;
    state = AsyncData(change(current));
    await save();
  }
}
