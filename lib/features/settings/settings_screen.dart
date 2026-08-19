import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/services/audio_download_service.dart';
import '../../core/services/azkar_repository.dart';
import '../../core/services/quran_repository.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/user_progress_service.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  DateTime? _quranCachedAt;
  DateTime? _azkarCachedAt;
  int _downloadedAudioBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
    _loadDownloadedAudioSize();
  }

  Future<void> _loadDownloadedAudioSize() async {
    final bytes = await AudioDownloadService.totalStorageUsedBytes();
    if (context.mounted) setState(() => _downloadedAudioBytes = bytes);
  }

  String _downloadedAudioSize(AppLocalizations l10n) {
    if (_downloadedAudioBytes == 0) return l10n.settingsNoDownloadedAudio;
    final mb = _downloadedAudioBytes / (1024 * 1024);
    return l10n.settingsMbDownloaded(mb.toStringAsFixed(1));
  }

  Future<void> _confirmDeleteAllDownloads() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsDeleteAllDownloadsTitle),
        content: Text(l10n.settingsDeleteAllDownloadsBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.commonDelete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await AudioDownloadService.deleteAllDownloads();
      _loadDownloadedAudioSize();
    }
  }

  Future<void> _loadCacheInfo() async {
    final quranAt = await QuranRepository.cachedAt();
    final azkarAt = await AzkarRepository.cachedAt();
    if (context.mounted) {
      setState(() {
        _quranCachedAt = quranAt;
        _azkarCachedAt = azkarAt;
      });
    }
  }

  String _formatCacheDate(DateTime? date, String languageCode, AppLocalizations l10n) {
    if (date == null) return l10n.settingsNotDownloadedYet;
    return DateFormat('d MMMM y, h:mm a', languageCode).format(date);
  }

  Future<void> _confirmClearData() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsDeleteLocalData),
        content: Text(l10n.settingsDeleteLocalDataBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await UserProgressService.clearAllLocalData();
      await appSettings.load();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsLocalDataDeleted)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle), centerTitle: true),
      body: ListenableBuilder(
        listenable: appSettings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionLabel(l10n.settingsAppearance),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.settingsMode, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      SegmentedButton<ThemeMode>(
                        segments: [
                          ButtonSegment(value: ThemeMode.light, label: Text(l10n.settingsModeLight), icon: const Icon(Icons.light_mode_outlined)),
                          ButtonSegment(value: ThemeMode.dark, label: Text(l10n.settingsModeDark), icon: const Icon(Icons.dark_mode_outlined)),
                          ButtonSegment(value: ThemeMode.system, label: Text(l10n.settingsModeAuto), icon: const Icon(Icons.brightness_auto_outlined)),
                        ],
                        selected: {appSettings.themeMode},
                        onSelectionChanged: (set) => appSettings.setThemeMode(set.first),
                      ),
                      const SizedBox(height: 20),
                      Text(l10n.settingsFontSize, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Slider(
                        value: appSettings.fontScale,
                        min: 0.85,
                        max: 1.4,
                        divisions: 11,
                        label: '${(appSettings.fontScale * 100).round()}%',
                        onChanged: (value) => appSettings.setFontScale(value),
                      ),
                      Text(
                        l10n.settingsFontPreview,
                        style: TextStyle(fontSize: 16 * appSettings.fontScale),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.settingsShowTransliteration),
                        subtitle: Text(l10n.settingsShowTransliterationSubtitle),
                        value: appSettings.showTransliteration,
                        activeTrackColor: AppColors.primaryEmerald,
                        onChanged: (value) => appSettings.setShowTransliteration(value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.settingsTajweedColoring),
                        subtitle: Text(l10n.settingsTajweedColoringSubtitle),
                        value: appSettings.showTajweedColoring,
                        activeTrackColor: AppColors.primaryEmerald,
                        onChanged: (value) => appSettings.setShowTajweedColoring(value),
                      ),
                      const Divider(height: 24),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.language_outlined, color: AppColors.mutedText),
                        title: Text(l10n.settingsLanguage),
                        subtitle: Text(l10n.settingsLanguageSubtitle),
                        trailing: Text(
                          appSettings.explicitLocale == null
                              ? l10n.settingsLanguageSystem
                              : {
                                  'ar': l10n.languageName_ar,
                                  'en': l10n.languageName_en,
                                  'de': l10n.languageName_de,
                                  'tr': l10n.languageName_tr,
                                }[appSettings.explicitLocale!.languageCode] ?? '',
                          style: const TextStyle(color: AppColors.mutedText),
                        ),
                        onTap: () => _showLanguageSheet(context, l10n),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel(l10n.settingsDataManagement),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.menu_book_outlined, color: AppColors.mutedText),
                      title: Text(l10n.settingsQuranLastUpdate),
                      subtitle: Text(_formatCacheDate(_quranCachedAt, languageCode, l10n)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.favorite_outline, color: AppColors.mutedText),
                      title: Text(l10n.settingsAzkarLastUpdate),
                      subtitle: Text(_formatCacheDate(_azkarCachedAt, languageCode, l10n)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.refresh, color: AppColors.primaryEmerald),
                      title: Text(l10n.settingsUpdateNow),
                      subtitle: Text(l10n.settingsRequiresInternet),
                      onTap: () async {
                        await QuranRepository.load(forceRefresh: true);
                        await AzkarRepository.load(forceRefresh: true);
                        await _loadCacheInfo();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.settingsDataUpdated)),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.download_outlined, color: AppColors.mutedText),
                      title: Text(l10n.settingsDownloadedAudio),
                      subtitle: Text(_downloadedAudioSize(l10n)),
                      trailing: _downloadedAudioBytes > 0
                          ? TextButton(
                              onPressed: _confirmDeleteAllDownloads,
                              child: Text(l10n.settingsDeleteAll, style: const TextStyle(color: Colors.red)),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.restart_alt, color: Colors.orange),
                      title: Text(l10n.settingsResetKhatma),
                      subtitle: Text(l10n.settingsResetKhatmaSubtitle),
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.settingsResetKhatma),
                            content: Text(l10n.settingsResetKhatmaBody),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.settingsResetKhatmaConfirm)),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await UserProgressService.resetKhatmaProgress();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.settingsKhatmaResetDone)),
                            );
                          }
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: Colors.red),
                      title: Text(l10n.settingsDeleteLocalData, style: const TextStyle(color: Colors.red)),
                      onTap: _confirmClearData,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showLanguageSheet(BuildContext context, AppLocalizations l10n) async {
    String nameFor(Locale locale) {
      switch (locale.languageCode) {
        case 'ar': return l10n.languageName_ar;
        case 'de': return l10n.languageName_de;
        case 'tr': return l10n.languageName_tr;
        default: return l10n.languageName_en;
      }
    }

    final choice = await showModalBottomSheet<Locale>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final currentLocale = appSettings.explicitLocale;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(l10n.settingsLanguage, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
              RadioListTile<String?>(
                value: null,
                groupValue: currentLocale?.languageCode,
                activeColor: AppColors.primaryEmerald,
                title: Text(l10n.settingsLanguageSystem),
                onChanged: (_) => Navigator.pop(sheetContext, const Locale('system')),
              ),
              for (final locale in AppSettings.supportedLocales)
                RadioListTile<String>(
                  value: locale.languageCode,
                  groupValue: currentLocale?.languageCode,
                  activeColor: AppColors.primaryEmerald,
                  title: Text(nameFor(locale)),
                  onChanged: (_) => Navigator.pop(sheetContext, locale),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (choice == null) return;
    if (choice.languageCode == 'system') {
      await appSettings.setLocale(null);
    } else {
      await appSettings.setLocale(choice);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.mutedText, fontSize: 13)),
    );
  }
}
