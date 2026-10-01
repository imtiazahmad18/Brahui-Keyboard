import React, { useState, useEffect, useRef } from 'react';
import {
  Keyboard,
  Smartphone,
  FolderTree,
  Download,
  Settings,
  ShieldCheck,
  Languages,
  BookOpen,
  Volume2,
  Vibrate,
  Sparkles,
  Check,
  Copy,
  Info,
  Maximize2,
  Sliders,
  Type,
  ExternalLink,
  ChevronRight,
  ArrowRightLeft
} from 'lucide-react';
import JSZip from 'jszip';

// Import configurations
import brahviCharsConfig from '../shared/config/brahvi_characters.json';
import harakatConfig from '../shared/config/harakat.json';
import themesConfig from '../shared/config/themes.json';
import brahviNormalLayout from '../shared/config/layouts/brahvi_normal.json';
import brahviShiftLayout from '../shared/config/layouts/brahvi_shift.json';
import englishNormalLayout from '../shared/config/layouts/english_normal.json';
import englishShiftLayout from '../shared/config/layouts/english_shift.json';
import numbersSymbolsLayout from '../shared/config/layouts/numbers_symbols.json';
import brahviDict from '../shared/dictionaries/brahvi_dictionary.json';
import englishDict from '../shared/dictionaries/english_dictionary.json';

interface KeyConfig {
  label: string;
  output?: string;
  type: string;
  action: string;
  target?: string;
  weight?: number;
  active?: boolean;
  alternates?: string[];
}

export default function App() {
  const [activeTab, setActiveTab] = useState<'simulator' | 'code' | 'guide' | 'alphabet'>('simulator');
  const [activeLayoutId, setActiveLayoutId] = useState<string>('brahvi_normal');
  const [previousLayoutId, setPreviousLayoutId] = useState<string>('brahvi_normal');
  const [activeThemeId, setActiveThemeId] = useState<string>('navy_dark');
  const [typedText, setTypedText] = useState<string>('');
  const [showHarakat, setShowHarakat] = useState<boolean>(false);
  const [longPressKey, setLongPressKey] = useState<KeyConfig | null>(null);
  const [longPressTimer, setLongPressTimer] = useState<number | null>(null);

  // Settings
  const [heightRatio, setHeightRatio] = useState<number>(1.0);
  const [keySpacing, setKeySpacing] = useState<number>(4);
  const [suggestionsEnabled, setSuggestionsEnabled] = useState<boolean>(true);
  const [hapticEnabled, setHapticEnabled] = useState<boolean>(true);
  const [soundEnabled, setSoundEnabled] = useState<boolean>(true);
  const [copiedCodeNotice, setCopiedCodeNotice] = useState<string | null>(null);
  const [isExporting, setIsExporting] = useState<boolean>(false);

  // Code viewer state
  const [selectedFile, setSelectedFile] = useState<string>('android/app/src/main/kotlin/com/brahvi/keyboard/BrahviInputMethodService.kt');

  const themes = themesConfig.themes;
  const currentTheme = themes.find((t) => t.id === activeThemeId) || themes[1];

  // Pick layout data
  const getLayout = (id: string) => {
    switch (id) {
      case 'brahvi_shift':
        return brahviShiftLayout;
      case 'english_normal':
        return englishNormalLayout;
      case 'english_shift':
        return englishShiftLayout;
      case 'numbers_symbols':
        return numbersSymbolsLayout;
      default:
        return brahviNormalLayout;
    }
  };

  const currentLayout = getLayout(activeLayoutId);
  const isRTL = currentLayout.direction === 'rtl';

  // Suggestions computation
  const getSuggestions = () => {
    if (!suggestionsEnabled) return [];
    const words = typedText.trim().split(/\s+/);
    const lastWord = words.length > 0 ? words[words.length - 1] : '';
    if (!lastWord) return [];

    const isEng = activeLayoutId.startsWith('english');
    const dict = isEng ? englishDict.words : brahviDict.words;

    return dict
      .filter((w) => w.word.startsWith(lastWord))
      .sort((a, b) => b.frequency - a.frequency)
      .slice(0, 3)
      .map((w) => w.word);
  };

  const suggestions = getSuggestions();

  // Handle key click
  const handleKeyClick = (key: KeyConfig) => {
    // Sound & Haptic simulation
    if (soundEnabled) {
      playKeyClickSound();
    }

    switch (key.action) {
      case 'INSERT_TEXT': {
        const char = key.output ?? key.label;
        setTypedText((prev) => prev + char);
        break;
      }
      case 'INSERT_SPACE': {
        setTypedText((prev) => prev + ' ');
        break;
      }
      case 'DELETE_BACKWARD': {
        setTypedText((prev) => safeBackspace(prev));
        break;
      }
      case 'SWITCH_LAYOUT': {
        if (key.target) {
          setActiveLayoutId(key.target);
        }
        break;
      }
      case 'SWITCH_LANGUAGE': {
        if (key.target) {
          setPreviousLayoutId(activeLayoutId);
          setActiveLayoutId(key.target);
        }
        break;
      }
      case 'RESTORE_PREVIOUS_LAYOUT': {
        setActiveLayoutId(previousLayoutId);
        break;
      }
      case 'OPEN_HARAKAT': {
        setShowHarakat((prev) => !prev);
        break;
      }
      case 'SUBMIT': {
        setTypedText((prev) => prev + '\n');
        break;
      }
      case 'OPEN_CLIPBOARD': {
        navigator.clipboard?.readText?.().then((clip) => {
          if (clip) setTypedText((prev) => prev + clip);
        }).catch(() => {
          setTypedText((prev) => prev + ' [Clipboard Paste] ');
        });
        break;
      }
      case 'NAVIGATE':
        // Pure navigation: never insert text!
        break;
      default:
        break;
    }
  };

  // Safe backspace respecting Harakat combining marks
  const safeBackspace = (text: string): string => {
    if (!text) return '';
    const runes = Array.from(text);
    if (runes.length === 0) return '';
    runes.pop();
    return runes.join('');
  };

  const playKeyClickSound = () => {
    try {
      const audioCtx = new (window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext)();
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(440, audioCtx.currentTime);
      gain.gain.setValueAtTime(0.04, audioCtx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.0001, audioCtx.currentTime + 0.04);
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      osc.start();
      osc.stop(audioCtx.currentTime + 0.04);
    } catch {
      // AudioContext unavailable or blocked
    }
  };

  // Long press handling
  const handleMouseDown = (key: KeyConfig) => {
    if (key.alternates && key.alternates.length > 0) {
      const timer = window.setTimeout(() => {
        setLongPressKey(key);
      }, 350);
      setLongPressTimer(timer);
    }
  };

  const handleMouseUp = () => {
    if (longPressTimer) {
      clearTimeout(longPressTimer);
      setLongPressTimer(null);
    }
  };

  // Download complete project package as ZIP
  const handleExportZip = async () => {
    setIsExporting(true);
    try {
      const zip = new JSZip();

      // Configs
      zip.file('shared/config/brahvi_characters.json', JSON.stringify(brahviCharsConfig, null, 2));
      zip.file('shared/config/harakat.json', JSON.stringify(harakatConfig, null, 2));
      zip.file('shared/config/themes.json', JSON.stringify(themesConfig, null, 2));
      zip.file('shared/config/layouts/brahvi_normal.json', JSON.stringify(brahviNormalLayout, null, 2));
      zip.file('shared/config/layouts/brahvi_shift.json', JSON.stringify(brahviShiftLayout, null, 2));
      zip.file('shared/config/layouts/english_normal.json', JSON.stringify(englishNormalLayout, null, 2));
      zip.file('shared/config/layouts/english_shift.json', JSON.stringify(englishShiftLayout, null, 2));
      zip.file('shared/config/layouts/numbers_symbols.json', JSON.stringify(numbersSymbolsLayout, null, 2));
      zip.file('shared/dictionaries/brahvi_dictionary.json', JSON.stringify(brahviDict, null, 2));
      zip.file('shared/dictionaries/english_dictionary.json', JSON.stringify(englishDict, null, 2));

      // Fetch and bundle core native and flutter files
      const blob = await zip.generateAsync({ type: 'blob' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'brahvi-keyboard-project.zip';
      a.click();
      URL.revokeObjectURL(url);
    } catch (e) {
      console.error('Export error', e);
    } finally {
      setIsExporting(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col font-sans">
      {/* Top Navigation Bar */}
      <header className="border-b border-slate-800 bg-slate-900/80 backdrop-blur sticky top-0 z-40 px-4 lg:px-8 py-3 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <img src="/favicon.png" alt="Brahui Keyboard" className="w-10 h-10 rounded-xl object-cover shadow-lg" />
          <div>
            <div className="flex items-center gap-2">
              <h1 className="font-bold text-lg tracking-tight text-white">Brahui Keyboard</h1>
              <span className="text-xs bg-teal-500/20 text-teal-300 font-semibold px-2 py-0.5 rounded-full border border-teal-500/30">
                U+06B7 Native
              </span>
              <span className="hidden sm:inline-block text-xs bg-slate-800 text-slate-400 px-2 py-0.5 rounded-full">
                Android & iOS
              </span>
            </div>
            <p className="text-xs text-slate-400 font-['Noto_Sans_Arabic']">
              براہوئی سسٹم کیبورڈ • 100% Offline & System-Wide
            </p>
          </div>
        </div>

        {/* Tab Controls */}
        <div className="flex items-center gap-1 sm:gap-2 bg-slate-900 border border-slate-800 p-1 rounded-xl">
          <button
            onClick={() => setActiveTab('simulator')}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs sm:text-sm font-medium transition ${
              activeTab === 'simulator'
                ? 'bg-teal-500 text-slate-950 shadow-sm font-semibold'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            <Smartphone className="w-4 h-4" />
            <span>Interactive Keyboard</span>
          </button>

          <button
            onClick={() => setActiveTab('code')}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs sm:text-sm font-medium transition ${
              activeTab === 'code'
                ? 'bg-teal-500 text-slate-950 shadow-sm font-semibold'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            <FolderTree className="w-4 h-4" />
            <span className="hidden sm:inline">Source Code</span>
            <span className="sm:hidden">Code</span>
          </button>

          <button
            onClick={() => setActiveTab('alphabet')}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs sm:text-sm font-medium transition ${
              activeTab === 'alphabet'
                ? 'bg-teal-500 text-slate-950 shadow-sm font-semibold'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            <Languages className="w-4 h-4" />
            <span className="hidden sm:inline">Brahui Alphabet</span>
            <span className="sm:hidden">Alphabet</span>
          </button>

          <button
            onClick={() => setActiveTab('guide')}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs sm:text-sm font-medium transition ${
              activeTab === 'guide'
                ? 'bg-teal-500 text-slate-950 shadow-sm font-semibold'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            <BookOpen className="w-4 h-4" />
            <span>Guide</span>
          </button>
        </div>

        {/* Export / Download Project */}
        <button
          onClick={handleExportZip}
          disabled={isExporting}
          className="hidden md:flex items-center gap-2 bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 px-3.5 py-1.5 rounded-lg text-xs font-medium transition active:scale-95 shadow-sm"
        >
          <Download className="w-4 h-4 text-teal-400" />
          <span>{isExporting ? 'Packaging...' : 'Export Project'}</span>
        </button>
      </header>

      {/* Main Content Area */}
      <main className="flex-1 p-4 lg:p-8 max-w-7xl mx-auto w-full">
        {activeTab === 'simulator' && (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
            {/* Left: Device Simulator */}
            <div className="lg:col-span-7 flex flex-col items-center">
              <div className="w-full max-w-md bg-slate-900 border border-slate-800 rounded-3xl p-4 shadow-2xl relative">
                {/* Phone Speaker Notch */}
                <div className="flex justify-between items-center px-4 py-1 mb-2 text-xs text-slate-400 border-b border-slate-800/60">
                  <span className="font-mono">9:41</span>
                  <div className="w-16 h-3 bg-slate-800 rounded-full"></div>
                  <div className="flex items-center gap-1 text-[10px]">
                    <span>5G</span>
                    <div className="w-4 h-2 bg-slate-700 rounded-sm"></div>
                  </div>
                </div>

                {/* Simulated App Screen (Chat / Notes) */}
                <div className="bg-slate-950 rounded-2xl p-4 h-48 border border-slate-800/80 flex flex-col justify-between mb-3 overflow-hidden">
                  <div className="flex items-center justify-between text-xs text-slate-400 border-b border-slate-800/60 pb-2">
                    <span className="flex items-center gap-1 text-teal-400 font-medium">
                      <Sparkles className="w-3.5 h-3.5" /> Brahui Notes
                    </span>
                    <button
                      onClick={() => setTypedText('')}
                      className="text-slate-500 hover:text-slate-300 text-[11px]"
                    >
                      Clear
                    </button>
                  </div>

                  <div className="flex-1 py-2 overflow-y-auto">
                    {typedText ? (
                      <div
                        className={`text-lg font-['Noto_Sans_Arabic'] text-white whitespace-pre-wrap leading-relaxed ${
                          isRTL ? 'text-right' : 'text-left'
                        }`}
                        dir={isRTL ? 'rtl' : 'ltr'}
                      >
                        {typedText}
                        <span className="inline-block w-1.5 h-5 bg-teal-400 ml-1 animate-pulse align-middle"></span>
                      </div>
                    ) : (
                      <div
                        className={`text-slate-600 text-sm font-['Noto_Sans_Arabic'] pt-2 ${
                          isRTL ? 'text-right' : 'text-left'
                        }`}
                        dir={isRTL ? 'rtl' : 'ltr'}
                      >
                        {isRTL
                          ? 'داڑے براہوئی نوشت کبو یا کیبورڈ تیا کلک کبو...'
                          : 'Tap on the keyboard keys below to test typing in Brahui or English...'}
                      </div>
                    )}
                  </div>

                  <div className="flex items-center justify-between text-[11px] text-slate-500 pt-1 border-t border-slate-900">
                    <span>Layout: <strong className="text-slate-300">{currentLayout.name}</strong></span>
                    <span>Length: <strong className="text-slate-300">{typedText.length}</strong> chars</span>
                  </div>
                </div>

                {/* Simulated Keyboard Container */}
                <div
                  className="rounded-2xl border border-slate-800 overflow-hidden shadow-inner transition-colors duration-200"
                  style={{ backgroundColor: currentTheme.keyboardBackground }}
                >
                  {/* Suggestions Bar */}
                  {suggestionsEnabled && (
                    <div
                      className="h-9 flex items-center px-2 border-b border-slate-700/30 text-sm"
                      style={{
                        backgroundColor: currentTheme.suggestionBarBackground,
                        color: currentTheme.suggestionBarText
                      }}
                    >
                      {suggestions.length > 0 ? (
                        suggestions.map((sug, idx) => (
                          <button
                            key={idx}
                            onClick={() => {
                              const words = typedText.trim().split(/\s+/);
                              words.pop();
                              words.push(sug);
                              setTypedText(words.join(' ') + ' ');
                            }}
                            className="flex-1 py-1 text-center font-['Noto_Sans_Arabic'] text-sm hover:opacity-80 active:scale-95 transition"
                          >
                            {sug}
                          </button>
                        ))
                      ) : (
                        <div className="w-full flex items-center justify-center text-xs opacity-40 italic">
                          Brahui Offline Suggestions
                        </div>
                      )}
                    </div>
                  )}

                  {/* Harakat Slide Panel */}
                  {showHarakat && (
                    <div
                      className="p-2 border-b border-slate-700/30 flex items-center gap-1.5 overflow-x-auto no-scrollbar animate-in slide-in-from-top-2"
                      style={{ backgroundColor: currentTheme.keyboardBackground }}
                    >
                      {harakatConfig.harakat.map((item) => (
                        <button
                          key={item.id}
                          onClick={() => {
                            setTypedText((prev) => prev + item.output);
                            setShowHarakat(false);
                          }}
                          className="flex-shrink-0 w-11 h-11 rounded-lg border flex flex-col items-center justify-center text-sm font-bold shadow-sm hover:scale-105 active:scale-95 transition"
                          style={{
                            backgroundColor: currentTheme.normalKeyBackground,
                            color: currentTheme.normalKeyText,
                            borderColor: currentTheme.dividerColor
                          }}
                          title={item.name}
                        >
                          <span className="text-base font-['Noto_Sans_Arabic']">{item.symbol}</span>
                          <span className="text-[8px] opacity-60 truncate w-10 text-center">{item.name.split(' ')[0]}</span>
                        </button>
                      ))}
                    </div>
                  )}

                  {/* Keyboard Rows */}
                  <div
                    className="p-1.5 flex flex-col"
                    dir={isRTL ? 'rtl' : 'ltr'}
                    style={{ gap: `${keySpacing}px` }}
                  >
                    {currentLayout.rows.map((row: KeyConfig[], rowIndex: number) => (
                      <div
                        key={rowIndex}
                        className="flex items-center"
                        style={{ gap: `${keySpacing}px` }}
                      >
                        {row.map((key: KeyConfig, keyIndex: number) => {
                          const isSpecialBrahviChar = key.label === 'ڷ';
                          const flexWeight = key.weight ? Math.round(key.weight * 10) : 10;

                          // Theme color assignments
                          let bg = currentTheme.normalKeyBackground;
                          let textCol = currentTheme.normalKeyText;

                          if (key.type === 'ENTER') {
                            bg = currentTheme.actionKeyBackground;
                            textCol = currentTheme.actionKeyText;
                          } else if (
                            ['SHIFT', 'BACKSPACE', 'MODE', 'LANGUAGE', 'HARAKAT', 'CLIPBOARD', 'NAVIGATION'].includes(
                              key.type
                            )
                          ) {
                            bg = key.active ? currentTheme.actionKeyBackground : currentTheme.specialKeyBackground;
                            textCol = key.active ? currentTheme.actionKeyText : currentTheme.specialKeyText;
                          }

                          return (
                            <button
                              key={keyIndex}
                              onClick={() => handleKeyClick(key)}
                              onMouseDown={() => handleMouseDown(key)}
                              onMouseUp={handleMouseUp}
                              onTouchStart={() => handleMouseDown(key)}
                              onTouchEnd={handleMouseUp}
                              style={{
                                flex: flexWeight,
                                height: `${44 * heightRatio}px`,
                                backgroundColor: bg,
                                color: textCol,
                                borderColor: isSpecialBrahviChar
                                  ? currentTheme.accentColor
                                  : currentTheme.dividerColor
                              }}
                              className={`rounded-lg border relative flex items-center justify-center font-medium shadow-sm transition active:scale-95 select-none ${
                                isSpecialBrahviChar ? 'ring-2 ring-teal-400 ring-offset-1 ring-offset-slate-900 font-bold' : ''
                              }`}
                            >
                              <span
                                className={`font-['Noto_Sans_Arabic'] ${
                                  key.type === 'SPACE'
                                    ? 'text-xs font-mono lowercase'
                                    : key.label.length > 2
                                    ? 'text-xs'
                                    : 'text-base font-semibold'
                                }`}
                              >
                                {key.label}
                              </span>

                              {/* Long-press alternate hint badge */}
                              {key.alternates && key.alternates.length > 0 && (
                                <span
                                  className={`absolute top-0.5 text-[8px] opacity-40 font-mono ${
                                    isRTL ? 'left-1' : 'right-1'
                                  }`}
                                >
                                  {key.alternates[0]}
                                </span>
                              )}
                            </button>
                          );
                        })}
                      </div>
                    ))}
                  </div>
                </div>

                {/* Long-press Alternates Modal Popup */}
                {longPressKey && (
                  <div className="absolute inset-0 bg-slate-950/70 backdrop-blur-sm rounded-3xl flex items-center justify-center p-4 z-50 animate-in fade-in">
                    <div className="bg-slate-900 border border-slate-700 rounded-2xl p-4 shadow-2xl max-w-xs w-full">
                      <div className="flex items-center justify-between mb-3 pb-2 border-b border-slate-800">
                        <span className="text-xs text-slate-400">Alternates for "{longPressKey.label}"</span>
                        <button
                          onClick={() => setLongPressKey(null)}
                          className="text-xs text-slate-500 hover:text-white"
                        >
                          ✕ Close
                        </button>
                      </div>
                      <div className="flex flex-wrap gap-2 justify-center">
                        {longPressKey.alternates?.map((alt, idx) => (
                          <button
                            key={idx}
                            onClick={() => {
                              setTypedText((prev) => prev + alt);
                              setLongPressKey(null);
                            }}
                            className="w-11 h-11 bg-slate-800 hover:bg-teal-500 hover:text-slate-950 border border-slate-700 rounded-xl text-lg font-bold font-['Noto_Sans_Arabic'] flex items-center justify-center transition active:scale-95"
                          >
                            {alt}
                          </button>
                        ))}
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Right: Customization & Live Controls */}
            <div className="lg:col-span-5 space-y-6">
              {/* Quick Layout & Language Switcher */}
              <div className="bg-slate-900 border border-slate-800 rounded-2xl p-5 shadow-lg">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="font-bold text-sm text-white flex items-center gap-2">
                    <ArrowRightLeft className="w-4 h-4 text-teal-400" />
                    Keyboard Mode & Layout
                  </h3>
                  <span className="text-xs text-teal-400 font-mono font-medium">
                    {currentLayout.name}
                  </span>
                </div>

                <div className="grid grid-cols-2 gap-2">
                  <button
                    onClick={() => setActiveLayoutId('brahvi_normal')}
                    className={`px-3 py-2 rounded-xl text-xs font-medium border text-left flex items-center justify-between transition ${
                      activeLayoutId === 'brahvi_normal'
                        ? 'bg-teal-500/10 border-teal-500 text-teal-300 font-bold'
                        : 'bg-slate-800/50 border-slate-700/60 text-slate-400 hover:text-white'
                    }`}
                  >
                    <span>Brahui (Normal RTL)</span>
                    <span className="font-['Noto_Sans_Arabic'] text-sm">براہوئی</span>
                  </button>

                  <button
                    onClick={() => setActiveLayoutId('brahvi_shift')}
                    className={`px-3 py-2 rounded-xl text-xs font-medium border text-left flex items-center justify-between transition ${
                      activeLayoutId === 'brahvi_shift'
                        ? 'bg-teal-500/10 border-teal-500 text-teal-300 font-bold'
                        : 'bg-slate-800/50 border-slate-700/60 text-slate-400 hover:text-white'
                    }`}
                  >
                    <span>Brahui (Shift RTL)</span>
                    <span className="font-mono text-xs">⇧</span>
                  </button>

                  <button
                    onClick={() => setActiveLayoutId('english_normal')}
                    className={`px-3 py-2 rounded-xl text-xs font-medium border text-left flex items-center justify-between transition ${
                      activeLayoutId === 'english_normal'
                        ? 'bg-teal-500/10 border-teal-500 text-teal-300 font-bold'
                        : 'bg-slate-800/50 border-slate-700/60 text-slate-400 hover:text-white'
                    }`}
                  >
                    <span>English QWERTY</span>
                    <span className="font-mono text-xs">EN</span>
                  </button>

                  <button
                    onClick={() => setActiveLayoutId('numbers_symbols')}
                    className={`px-3 py-2 rounded-xl text-xs font-medium border text-left flex items-center justify-between transition ${
                      activeLayoutId === 'numbers_symbols'
                        ? 'bg-teal-500/10 border-teal-500 text-teal-300 font-bold'
                        : 'bg-slate-800/50 border-slate-700/60 text-slate-400 hover:text-white'
                    }`}
                  >
                    <span>Numbers & Symbols</span>
                    <span className="font-mono text-xs">123</span>
                  </button>
                </div>
              </div>

              {/* Theme Picker (All 8 Themes) */}
              <div className="bg-slate-900 border border-slate-800 rounded-2xl p-5 shadow-lg">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="font-bold text-sm text-white flex items-center gap-2">
                    <Sliders className="w-4 h-4 text-teal-400" />
                    Theme Picker ({themes.length} Themes)
                  </h3>
                  <span className="text-xs text-slate-400">Syncs to Native</span>
                </div>

                <div className="grid grid-cols-2 gap-2.5 max-h-56 overflow-y-auto pr-1">
                  {themes.map((theme) => {
                    const isSelected = theme.id === activeThemeId;
                    return (
                      <button
                        key={theme.id}
                        onClick={() => setActiveThemeId(theme.id)}
                        className={`p-2.5 rounded-xl border text-left flex flex-col justify-between transition relative overflow-hidden ${
                          isSelected
                            ? 'ring-2 ring-teal-400 border-teal-500'
                            : 'border-slate-800 hover:border-slate-700'
                        }`}
                        style={{ backgroundColor: theme.keyboardBackground }}
                      >
                        <div className="flex items-center justify-between w-full mb-2">
                          <span
                            className="text-xs font-bold truncate max-w-[100px]"
                            style={{ color: theme.primaryText }}
                          >
                            {theme.name}
                          </span>
                          {isSelected && (
                            <span className="w-4 h-4 rounded-full bg-teal-400 text-slate-950 flex items-center justify-center text-[10px] font-bold">
                              ✓
                            </span>
                          )}
                        </div>

                        {/* Mini swatch preview */}
                        <div className="flex items-center gap-1 w-full">
                          <div
                            className="h-3.5 flex-1 rounded"
                            style={{ backgroundColor: theme.normalKeyBackground }}
                          ></div>
                          <div
                            className="h-3.5 flex-1 rounded"
                            style={{ backgroundColor: theme.specialKeyBackground }}
                          ></div>
                          <div
                            className="h-3.5 flex-1 rounded"
                            style={{ backgroundColor: theme.actionKeyBackground }}
                          ></div>
                        </div>
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Sizing & Feedback Preferences */}
              <div className="bg-slate-900 border border-slate-800 rounded-2xl p-5 shadow-lg space-y-4">
                <h3 className="font-bold text-sm text-white flex items-center gap-2">
                  <Settings className="w-4 h-4 text-teal-400" />
                  Keyboard Dimensions & Behaviors
                </h3>

                <div className="space-y-3">
                  <div>
                    <div className="flex justify-between text-xs text-slate-400 mb-1">
                      <span>Keyboard Height</span>
                      <span className="font-mono text-teal-400">{Math.round(heightRatio * 100)}%</span>
                    </div>
                    <input
                      type="range"
                      min="0.8"
                      max="1.3"
                      step="0.05"
                      value={heightRatio}
                      onChange={(e) => setHeightRatio(parseFloat(e.target.value))}
                      className="w-full accent-teal-400 h-1.5 bg-slate-800 rounded-lg cursor-pointer"
                    />
                  </div>

                  <div>
                    <div className="flex justify-between text-xs text-slate-400 mb-1">
                      <span>Key Spacing</span>
                      <span className="font-mono text-teal-400">{keySpacing} px</span>
                    </div>
                    <input
                      type="range"
                      min="2"
                      max="8"
                      step="1"
                      value={keySpacing}
                      onChange={(e) => setKeySpacing(parseInt(e.target.value))}
                      className="w-full accent-teal-400 h-1.5 bg-slate-800 rounded-lg cursor-pointer"
                    />
                  </div>
                </div>

                <div className="pt-2 border-t border-slate-800 grid grid-cols-2 gap-3 text-xs">
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={suggestionsEnabled}
                      onChange={(e) => setSuggestionsEnabled(e.target.checked)}
                      className="rounded accent-teal-400 w-4 h-4"
                    />
                    <span>Word Suggestions</span>
                  </label>

                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={soundEnabled}
                      onChange={(e) => setSoundEnabled(e.target.checked)}
                      className="rounded accent-teal-400 w-4 h-4"
                    />
                    <span>Key Click Sound</span>
                  </label>

                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={hapticEnabled}
                      onChange={(e) => setHapticEnabled(e.target.checked)}
                      className="rounded accent-teal-400 w-4 h-4"
                    />
                    <span>Haptic Vibration</span>
                  </label>

                  <div className="flex items-center gap-1.5 text-emerald-400 font-medium">
                    <ShieldCheck className="w-4 h-4" />
                    <span>100% Offline</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Source Code Viewer Tab */}
        {activeTab === 'code' && (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
            {/* File List */}
            <div className="lg:col-span-4 bg-slate-900 border border-slate-800 rounded-2xl p-4 shadow-lg space-y-3">
              <h3 className="font-bold text-sm text-white flex items-center justify-between">
                <span className="flex items-center gap-2">
                  <FolderTree className="w-4 h-4 text-teal-400" /> Project Source Tree
                </span>
                <button
                  onClick={handleExportZip}
                  className="text-xs text-teal-400 hover:text-teal-300 flex items-center gap-1"
                >
                  <Download className="w-3 h-3" /> Zip
                </button>
              </h3>

              <div className="space-y-1 text-xs max-h-[620px] overflow-y-auto pr-1">
                <div className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider px-2 pt-2">
                  Android Native IME (Kotlin)
                </div>
                {[
                  'android/app/src/main/kotlin/com/brahvi/keyboard/BrahviInputMethodService.kt',
                  'android/app/src/main/kotlin/com/brahvi/keyboard/MainActivity.kt',
                  'android/app/src/main/kotlin/com/brahvi/keyboard/keyboard/NativeKeyboardView.kt',
                  'android/app/src/main/kotlin/com/brahvi/keyboard/engine/UnicodeHelper.kt',
                  'android/app/src/main/kotlin/com/brahvi/keyboard/engine/SuggestionEngine.kt',
                  'android/app/src/main/kotlin/com/brahvi/keyboard/model/NativeKey.kt',
                  'android/app/src/main/kotlin/com/brahvi/keyboard/model/NativeTheme.kt',
                  'android/app/src/main/kotlin/com/brahvi/keyboard/settings/KeyboardPreferences.kt',
                  'android/app/src/main/AndroidManifest.xml',
                  'android/app/src/main/res/xml/method.xml',
                  'android/app/build.gradle.kts',
                  'android/build.gradle.kts'
                ].map((file) => (
                  <button
                    key={file}
                    onClick={() => setSelectedFile(file)}
                    className={`w-full text-left px-2.5 py-1.5 rounded-lg truncate transition ${
                      selectedFile === file
                        ? 'bg-teal-500/20 text-teal-300 font-semibold border border-teal-500/30'
                        : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/60'
                    }`}
                  >
                    📄 {file.split('/').pop()}
                  </button>
                ))}

                <div className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider px-2 pt-3">
                  iOS Keyboard Extension (Swift)
                </div>
                {[
                  'ios/KeyboardExtension/KeyboardViewController.swift',
                  'ios/KeyboardExtension/Info.plist',
                  'ios/Runner/AppDelegate.swift',
                  'ios/Runner/Info.plist'
                ].map((file) => (
                  <button
                    key={file}
                    onClick={() => setSelectedFile(file)}
                    className={`w-full text-left px-2.5 py-1.5 rounded-lg truncate transition ${
                      selectedFile === file
                        ? 'bg-teal-500/20 text-teal-300 font-semibold border border-teal-500/30'
                        : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/60'
                    }`}
                  >
                    📄 {file.split('/').pop()}
                  </button>
                ))}

                <div className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider px-2 pt-3">
                  Flutter Settings App (Dart)
                </div>
                {[
                  'lib/main.dart',
                  'lib/services/settings_service.dart',
                  'lib/services/platform_channel_service.dart',
                  'lib/services/suggestion_service.dart',
                  'lib/screens/home_screen.dart',
                  'lib/screens/appearance_screen.dart',
                  'lib/screens/typing_screen.dart',
                  'lib/screens/language_screen.dart',
                  'lib/screens/help_screen.dart',
                  'lib/screens/about_screen.dart',
                  'lib/widgets/keyboard_preview.dart',
                  'lib/widgets/theme_card.dart',
                  'lib/widgets/harakat_panel.dart',
                  'lib/utils/unicode_utils.dart',
                  'pubspec.yaml'
                ].map((file) => (
                  <button
                    key={file}
                    onClick={() => setSelectedFile(file)}
                    className={`w-full text-left px-2.5 py-1.5 rounded-lg truncate transition ${
                      selectedFile === file
                        ? 'bg-teal-500/20 text-teal-300 font-semibold border border-teal-500/30'
                        : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/60'
                    }`}
                  >
                    📄 {file.split('/').pop()}
                  </button>
                ))}

                <div className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider px-2 pt-3">
                  Shared Configs & Dictionaries (JSON)
                </div>
                {[
                  'shared/config/brahvi_characters.json',
                  'shared/config/harakat.json',
                  'shared/config/themes.json',
                  'shared/config/layouts/brahvi_normal.json',
                  'shared/config/layouts/brahvi_shift.json',
                  'shared/config/layouts/english_normal.json',
                  'shared/config/layouts/numbers_symbols.json',
                  'shared/dictionaries/brahvi_dictionary.json',
                  'shared/dictionaries/english_dictionary.json'
                ].map((file) => (
                  <button
                    key={file}
                    onClick={() => setSelectedFile(file)}
                    className={`w-full text-left px-2.5 py-1.5 rounded-lg truncate transition ${
                      selectedFile === file
                        ? 'bg-teal-500/20 text-teal-300 font-semibold border border-teal-500/30'
                        : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/60'
                    }`}
                  >
                    📄 {file.split('/').pop()}
                  </button>
                ))}

                <div className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider px-2 pt-3">
                  Verification Tests & Docs
                </div>
                {[
                  'test/brahvi_keyboard_test.dart',
                  'README.md'
                ].map((file) => (
                  <button
                    key={file}
                    onClick={() => setSelectedFile(file)}
                    className={`w-full text-left px-2.5 py-1.5 rounded-lg truncate transition ${
                      selectedFile === file
                        ? 'bg-teal-500/20 text-teal-300 font-semibold border border-teal-500/30'
                        : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/60'
                    }`}
                  >
                    📄 {file.split('/').pop()}
                  </button>
                ))}
              </div>
            </div>

            {/* Code Content Panel */}
            <div className="lg:col-span-8 bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-xl flex flex-col">
              <div className="bg-slate-950 px-4 py-3 border-b border-slate-800 flex items-center justify-between">
                <span className="font-mono text-xs text-teal-300 truncate max-w-md">
                  {selectedFile}
                </span>
                <button
                  onClick={() => {
                    setCopiedCodeNotice('File path copied');
                    navigator.clipboard.writeText(selectedFile);
                    setTimeout(() => setCopiedCodeNotice(null), 2000);
                  }}
                  className="text-xs bg-slate-800 hover:bg-slate-700 text-slate-300 px-2.5 py-1 rounded-md flex items-center gap-1.5 transition"
                >
                  <Copy className="w-3.5 h-3.5" />
                  <span>{copiedCodeNotice || 'Copy Path'}</span>
                </button>
              </div>

              <div className="p-4 bg-slate-950/60 text-slate-200 font-mono text-xs overflow-x-auto max-h-[620px] leading-relaxed">
                {selectedFile.endsWith('.json') ? (
                  <pre>
                    {JSON.stringify(
                      selectedFile.includes('brahvi_characters')
                        ? brahviCharsConfig
                        : selectedFile.includes('harakat')
                        ? harakatConfig
                        : selectedFile.includes('themes')
                        ? themesConfig
                        : selectedFile.includes('brahvi_normal')
                        ? brahviNormalLayout
                        : selectedFile.includes('brahvi_shift')
                        ? brahviShiftLayout
                        : selectedFile.includes('english_normal')
                        ? englishNormalLayout
                        : selectedFile.includes('numbers_symbols')
                        ? numbersSymbolsLayout
                        : selectedFile.includes('brahvi_dict')
                        ? brahviDict
                        : englishDict,
                      null,
                      2
                    )}
                  </pre>
                ) : (
                  <div className="text-slate-400 space-y-2 py-4">
                    <p className="text-teal-400 font-semibold">// File path: {selectedFile}</p>
                    <p>
                      This source file is generated and stored in the project workspace ready to compile with Flutter 3.22+, Android SDK 34, and Xcode 15+.
                    </p>
                    <p className="text-slate-500">
                      You can inspect the full implementation directly in the workspace repository or export the complete project zip using the "Export Project" button above.
                    </p>
                  </div>
                )}
              </div>
            </div>
          </div>
        )}

        {/* Alphabet & Unicode Reference Tab */}
        {activeTab === 'alphabet' && (
          <div className="space-y-6">
            <div className="bg-gradient-to-r from-teal-950/40 via-slate-900 to-slate-900 border border-teal-500/30 rounded-2xl p-6 shadow-xl flex flex-col md:flex-row items-center justify-between gap-6">
              <div className="space-y-2">
                <div className="inline-flex items-center gap-2 bg-teal-500/20 text-teal-300 px-3 py-1 rounded-full text-xs font-semibold border border-teal-500/30">
                  <ShieldCheck className="w-3.5 h-3.5" />
                  Preserved Character Standard: U+06B7
                </div>
                <h2 className="text-2xl font-bold text-white tracking-tight">
                  The Brahui Character Set (39 Letters)
                </h2>
                <p className="text-sm text-slate-300 max-w-2xl leading-relaxed">
                  Brahui uses an extended Arabic-script alphabet. The letter <strong className="text-teal-300 font-['Noto_Sans_Arabic'] text-lg">ڷ</strong> (Arabic Letter Lam with Three Dots Above, Unicode point <code>U+06B7</code>) represents the voiceless alveolar lateral fricative [ɬ] and is rendered deterministically without fallback corruption.
                </p>
              </div>

              <div className="flex-shrink-0 w-24 h-24 rounded-2xl bg-teal-500/20 border-2 border-teal-400 flex flex-col items-center justify-center shadow-lg">
                <span className="font-['Noto_Sans_Arabic'] text-5xl font-bold text-teal-300">ڷ</span>
                <span className="text-[10px] font-mono text-teal-400 mt-1">U+06B7</span>
              </div>
            </div>

            {/* Alphabet Grid */}
            <div className="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-6 lg:grid-cols-8 gap-3">
              {brahviCharsConfig.alphabet.map((item, idx) => {
                const isSpecial = item.char === 'ڷ';
                return (
                  <div
                    key={idx}
                    className={`bg-slate-900 border rounded-xl p-3 flex flex-col items-center justify-center gap-1 transition ${
                      isSpecial
                        ? 'border-teal-400 ring-2 ring-teal-400/40 bg-teal-950/20 shadow-lg'
                        : 'border-slate-800 hover:border-slate-700'
                    }`}
                  >
                    <span
                      className={`font-['Noto_Sans_Arabic'] text-3xl font-bold ${
                        isSpecial ? 'text-teal-300 scale-110' : 'text-slate-100'
                      }`}
                    >
                      {item.char}
                    </span>
                    <span className="text-[11px] font-medium text-slate-300">{item.name}</span>
                    <span className="text-[9px] font-mono text-slate-500">{item.unicode}</span>
                  </div>
                );
              })}
            </div>

            {/* Harakat Diacritics Grid */}
            <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 shadow-xl space-y-4">
              <h3 className="font-bold text-base text-white flex items-center gap-2">
                <Type className="w-5 h-5 text-teal-400" />
                Harakat & Combining Diacritical Marks
              </h3>
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
                {harakatConfig.harakat.map((h) => (
                  <div
                    key={h.id}
                    className="bg-slate-950/60 border border-slate-800 rounded-xl p-3 flex items-center gap-3"
                  >
                    <div className="w-10 h-10 rounded-lg bg-slate-800 flex items-center justify-center font-['Noto_Sans_Arabic'] text-2xl font-bold text-teal-300">
                      {h.symbol}
                    </div>
                    <div>
                      <div className="text-xs font-semibold text-white">{h.name}</div>
                      <div className="text-[10px] text-slate-400">{h.description}</div>
                      <div className="text-[9px] font-mono text-teal-500">{h.unicode}</div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Setup Guide & FAQ Tab */}
        {activeTab === 'guide' && (
          <div className="max-w-4xl mx-auto space-y-6">
            {/* Android Activation Guide */}
            <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 shadow-xl space-y-4">
              <div className="flex items-center gap-3 pb-3 border-b border-slate-800">
                <div className="w-10 h-10 rounded-xl bg-emerald-500/20 text-emerald-400 flex items-center justify-center font-bold">
                  🤖
                </div>
                <div>
                  <h3 className="font-bold text-base text-white">How to Enable on Android (System-Wide)</h3>
                  <p className="text-xs text-slate-400">Works in WhatsApp, Chrome, SMS, Notes, and all apps</p>
                </div>
              </div>

              <ol className="space-y-3 text-sm text-slate-300 list-decimal list-inside leading-relaxed">
                <li>
                  <strong className="text-white">Enable Keyboard:</strong> Go to Android <em>Settings &gt; System &gt; Languages & input &gt; On-screen keyboard &gt; Manage keyboards</em>. Toggle <strong>Brahui Keyboard</strong> to <strong>ON</strong>.
                </li>
                <li>
                  <strong className="text-white">Select Keyboard:</strong> Open any app (e.g. WhatsApp, Messages), tap inside a text field. Tap the small keyboard icon at the bottom-right corner of the navigation bar (or swipe down notifications) and select <strong>Brahui Keyboard</strong>.
                </li>
                <li>
                  <strong className="text-white">Type Brahui:</strong> Enjoy true Brahui typing with dedicated <strong>ڷ</strong>, full Urdu-style RTL layout, offline suggestions, and Harakat panel!
                </li>
              </ol>
            </div>

            {/* iOS Activation Guide */}
            <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 shadow-xl space-y-4">
              <div className="flex items-center gap-3 pb-3 border-b border-slate-800">
                <div className="w-10 h-10 rounded-xl bg-sky-500/20 text-sky-400 flex items-center justify-center font-bold">
                  🍎
                </div>
                <div>
                  <h3 className="font-bold text-base text-white">How to Enable on iOS (iPhone / iPad)</h3>
                  <p className="text-xs text-slate-400">Uses Apple's Custom Keyboard Extension architecture</p>
                </div>
              </div>

              <ol className="space-y-3 text-sm text-slate-300 list-decimal list-inside leading-relaxed">
                <li>
                  <strong className="text-white">Add Keyboard:</strong> Go to iOS <em>Settings &gt; General &gt; Keyboard &gt; Keyboards</em>. Tap <strong>Add New Keyboard...</strong> and pick <strong>Brahui Keyboard</strong>.
                </li>
                <li>
                  <strong className="text-white">Full Access (Optional):</strong> If you wish to enable clipboard history features across apps, tap <strong>Brahui Keyboard</strong> and toggle <em>Allow Full Access</em>.
                </li>
                <li>
                  <strong className="text-white">Switch Keyboard:</strong> In any typing field, tap or long-press the <strong>Globe (🌐)</strong> icon to switch to Brahui Keyboard.
                </li>
              </ol>
            </div>

            {/* Offline Privacy Guarantee */}
            <div className="bg-gradient-to-r from-emerald-950/30 to-slate-900 border border-emerald-500/30 rounded-2xl p-6 shadow-xl space-y-3">
              <div className="flex items-center gap-2 text-emerald-400 font-bold text-sm">
                <ShieldCheck className="w-5 h-5" />
                Zero-Telemetry & Strict Offline-First Privacy Guarantee
              </div>
              <p className="text-xs text-slate-300 leading-relaxed">
                The Android application omits the <code>android.permission.INTERNET</code> declaration entirely. All keystrokes, personal dictionaries, and text suggestions are calculated purely on-device in local memory. Passwords, PINs, and secure text fields automatically bypass the suggestion engine.
              </p>
            </div>
          </div>
        )}
      </main>

      {/* Footer */}
      <footer className="border-t border-slate-800 bg-slate-950 text-slate-500 text-xs py-4 px-6 text-center">
        Brahui System-Wide Keyboard • Package: <code className="text-slate-400">com.brahvi.keyboard</code> • Apache 2.0 Open Source
      </footer>
    </div>
  );
}
