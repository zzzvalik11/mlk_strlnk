'use client';

import { useEffect, useState, useCallback } from 'react';
import {
  Bell, Settings, Plus, History, Globe, Lock as LockIcon,
  Home, CreditCard, FileText, HelpCircle, Loader2,
  ArrowDownLeft, ArrowUpRight, RefreshCw, Send, Clock, Tag,
  Wallet, Smartphone, Building2, CreditCard as CardIcon,
  CheckCircle2, AlertCircle, MessageSquare, Inbox, ChevronRight,
  User, Eye, EyeOff, Mail, LogOut,
} from 'lucide-react';
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription } from '@/components/ui/sheet';
import { toast } from 'sonner';

/* ================================================================== */
/*  Domain Types                                                       */
/* ================================================================== */

interface UserProfile {
  pin: string;
  fullName: string;
  phone: string | null;
  avatarUrl: string | null;
}

interface Balance {
  amount: number;
  currency: string;
  paidUntil: string;
  isPaid: boolean;
  paidUntilLabel: string;
}

interface ActiveService {
  id: string;
  name: string;
  category: string;
  cost: number;
  status: string;
  warningMessage: string | null;
  billingCycle: string | null;
}

interface ProfileResponse {
  user: UserProfile;
  balance: Balance;
  activeServices: ActiveService[];
}

interface Transaction {
  id: string;
  type: string;
  amount: number;
  description: string;
  date: string;
  status: string;
}

interface NewsItem {
  id: string;
  title: string;
  summary: string;
  imageUrl: string | null;
  publishedAt: string;
  readCount: number | null;
}

type FetchState = 'idle' | 'loading' | 'success' | 'error';

interface AuthState {
  token: string | null;
  fullName: string | null;
}

/* ================================================================== */
/*  Utility                                                            */
/* ================================================================== */

function formatDate(iso: string): string {
  const d = new Date(iso);
  return d.toLocaleDateString('ru-RU', { day: 'numeric', month: 'long', year: 'numeric' });
}

function txIcon(type: string) {
  switch (type) {
    case 'topUp':
    case 'bonus':
      return <ArrowDownLeft className="h-5 w-5 text-emerald-500" />;
    case 'refund':
      return <RefreshCw className="h-5 w-5 text-blue-500" />;
    default:
      return <ArrowUpRight className="h-5 w-5 text-red-400" />;
  }
}

function txSign(type: string): string {
  return type === 'topUp' || type === 'bonus' || type === 'refund' ? '+' : '-';
}

function txColor(type: string): string {
  return type === 'topUp' || type === 'bonus' || type === 'refund' ? 'text-emerald-600' : 'text-red-500';
}

function txLabel(type: string): string {
  switch (type) {
    case 'topUp': return 'Пополнение';
    case 'payment': return 'Оплата';
    case 'refund': return 'Возврат';
    case 'bonus': return 'Бонус';
    default: return type;
  }
}

const AUTH_KEY = 'telecom_auth';

function loadAuth(): AuthState {
  if (typeof window === 'undefined') return { token: null, fullName: null };
  try {
    const raw = localStorage.getItem(AUTH_KEY);
    return raw ? JSON.parse(raw) : { token: null, fullName: null };
  } catch {
    return { token: null, fullName: null };
  }
}

function saveAuth(auth: AuthState) {
  localStorage.setItem(AUTH_KEY, JSON.stringify(auth));
}

function clearAuth() {
  localStorage.removeItem(AUTH_KEY);
}

/* ================================================================== */
/*  Login Screen                                                       */
/* ================================================================== */

function LoginScreen({
  onLogin,
  onOpenSupport,
}: {
  onLogin: (auth: AuthState) => void;
  onOpenSupport: () => void;
}) {
  const [pin, setPin] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [pinFocused, setPinFocused] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!pin.trim() || !password.trim()) {
      setError('Введите ПИН и пароль');
      return;
    }
    setLoading(true);
    setError('');
    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ pin: pin.trim(), password }),
      });
      const json = await res.json();
      if (!res.ok) {
        setError(json.error || 'Ошибка авторизации');
        return;
      }
      onLogin({ token: json.token, fullName: json.user.fullName });
    } catch {
      setError('Сервер недоступен');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="mx-auto flex min-h-dvh w-full max-w-[430px] flex-col justify-center bg-[#FFF5F0] px-6">
      {/* ---- Logo ---- */}
      <div className="mb-10 flex items-center justify-center gap-4">
        <div className="text-center">
          <h1 className="text-[42px] font-extrabold leading-none tracking-tight text-gray-900">
            Starlink
          </h1>
          <p className="mt-1 text-[16px] font-medium text-gray-600">
            просто с нами проще
          </p>
        </div>
        <div
          className="flex h-[76px] w-[76px] shrink-0 items-center justify-center rounded-full"
          style={{ background: 'linear-gradient(135deg, #FF9A44 0%, #FC6076 100%)' }}
        >
          <span className="text-3xl font-black text-white" style={{ fontFamily: 'system-ui' }}>S</span>
        </div>
      </div>

      {/* ---- Form ---- */}
      <form onSubmit={handleSubmit} className="flex flex-col gap-5">
        {/* PIN */}
        <div
          className={`flex h-14 items-center gap-3 rounded-xl border-2 bg-white px-4 transition-colors ${
            pinFocused ? 'border-[#F37021]' : 'border-gray-200'
          }`}
        >
          <User className="h-6 w-6 shrink-0 text-gray-400" strokeWidth={1.8} />
          <input
            type="text"
            inputMode="numeric"
            placeholder="ПИН"
            value={pin}
            onChange={(e) => setPin(e.target.value)}
            onFocus={() => setPinFocused(true)}
            onBlur={() => setPinFocused(false)}
            autoComplete="off"
            className="h-full flex-1 bg-transparent text-[18px] text-gray-900 outline-none placeholder:text-gray-400"
          />
        </div>

        {/* Password */}
        <div className="flex h-14 items-center gap-3 rounded-xl border-2 border-gray-200 bg-white px-4 transition-colors focus-within:border-[#F37021]">
          <LockIcon className="h-6 w-6 shrink-0 text-gray-400" strokeWidth={1.8} />
          <input
            type={showPassword ? 'text' : 'password'}
            placeholder="Пароль"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            autoComplete="off"
            className="h-full flex-1 bg-transparent text-[18px] text-gray-900 outline-none placeholder:text-gray-400"
          />
          <button
            type="button"
            onClick={() => setShowPassword(!showPassword)}
            className="text-gray-500 transition-colors hover:text-gray-700"
            aria-label={showPassword ? 'Скрыть пароль' : 'Показать пароль'}
          >
            {showPassword
              ? <EyeOff className="h-[22px] w-[22px]" strokeWidth={1.8} />
              : <Eye className="h-[22px] w-[22px]" strokeWidth={1.8} />}
          </button>
        </div>

        {/* Error */}
        {error && (
          <p className="-mt-2 text-center text-[14px] font-medium text-red-500">{error}</p>
        )}

        {/* Submit */}
        <button
          type="submit"
          disabled={loading}
          className="mt-2 flex h-14 w-full items-center justify-center rounded-xl bg-[#F37021] text-[18px] font-bold text-white transition-colors hover:bg-[#D45A10] disabled:opacity-60"
        >
          {loading ? <Loader2 className="h-5 w-5 animate-spin" /> : 'Войти'}
        </button>
      </form>

      {/* ---- Support link ---- */}
      <button
        type="button"
        onClick={onOpenSupport}
        className="mx-auto mt-6 flex items-center gap-2 text-[17px] font-medium text-blue-500 transition-colors hover:text-blue-600"
      >
        <Mail className="h-[22px] w-[22px]" strokeWidth={2} />
        Написать в поддержку
      </button>
    </div>
  );
}

/* ================================================================== */
/*  Support Only Screen (unauthenticated)                               */
/* ================================================================== */

function SupportOnlyScreen({ onBack }: { onBack: () => void }) {
  const [subject, setSubject] = useState('');
  const [description, setDescription] = useState('');
  const [sending, setSending] = useState(false);
  const [sent, setSent] = useState(false);

  const handleSubmit = async () => {
    if (!subject.trim() || !description.trim()) {
      toast.error('Заполните все поля');
      return;
    }
    setSending(true);
    await new Promise((r) => setTimeout(r, 1000));
    setSending(false);
    setSent(true);
    toast.success('Обращение отправлено');
  };

  return (
    <div className="mx-auto min-h-dvh w-full max-w-[430px] bg-[#FFF5F0] px-5 pt-6 pb-10">
      <button
        type="button"
        onClick={onBack}
        className="mb-6 flex items-center gap-1.5 text-[16px] font-medium text-gray-600 transition-colors hover:text-gray-900"
      >
        <ChevronRight className="h-5 w-5 rotate-180" />
        Назад
      </button>

      <h1 className="mb-2 text-[22px] font-bold text-gray-900">Поддержка</h1>
      <p className="mb-6 text-[15px] text-gray-500">Оставьте обращение и мы свяжемся с вами</p>

      {sent ? (
        <div className="rounded-2xl bg-white p-8 text-center shadow-[0_1px_4px_rgba(0,0,0,0.06)]">
          <CheckCircle2 className="mx-auto mb-4 h-14 w-14 text-emerald-500" />
          <h2 className="mb-2 text-lg font-bold text-gray-900">Отправлено!</h2>
          <p className="mb-5 text-[15px] text-gray-500">Мы ответим в ближайшее время</p>
          <button
            type="button"
            onClick={() => { setSent(false); setSubject(''); setDescription(''); }}
            className="text-sm font-medium text-orange-500 underline"
          >
            Новое обращение
          </button>
        </div>
      ) : (
        <div className="rounded-2xl bg-white p-5 shadow-[0_1px_4px_rgba(0,0,0,0.06)]">
          <label htmlFor="sp-subject" className="mb-1.5 block text-sm font-medium text-gray-700">Тема</label>
          <input
            id="sp-subject"
            type="text"
            placeholder="Кратко опишите проблему"
            value={subject}
            onChange={(e) => setSubject(e.target.value)}
            className="mb-4 w-full rounded-xl border-2 border-gray-200 px-4 py-3 text-[15px] text-gray-900 outline-none transition-colors focus:border-orange-500"
          />
          <label htmlFor="sp-desc" className="mb-1.5 block text-sm font-medium text-gray-700">Описание</label>
          <textarea
            id="sp-desc"
            placeholder="Подробно опишите вашу проблему…"
            rows={5}
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            className="mb-5 w-full resize-none rounded-xl border-2 border-gray-200 px-4 py-3 text-[15px] text-gray-900 outline-none transition-colors focus:border-orange-500"
          />
          <button
            type="button"
            onClick={handleSubmit}
            disabled={sending}
            className="flex w-full items-center justify-center gap-2 rounded-xl bg-orange-500 px-6 py-3.5 text-[16px] font-semibold text-white transition-colors hover:bg-orange-600 disabled:opacity-50"
          >
            {sending ? <Loader2 className="h-5 w-5 animate-spin" /> : <Send className="h-5 w-5" />}
            Отправить
          </button>
        </div>
      )}

      {/* FAQ */}
      <div className="mt-8">
        <h2 className="mb-4 text-[17px] font-semibold text-gray-800">Частые вопросы</h2>
        <div className="flex flex-col gap-3">
          {[
            { q: 'Как пополнить баланс?', a: 'Войдите в личный кабинет и нажмите «Пополнить».' },
            { q: 'Забыл пароль', a: 'Обратитесь в поддержку через эту форму.' },
            { q: 'Как изменить тариф?', a: 'Обратитесь в поддержку через эту форму или позвоните на горячую линию.' },
          ].map((faq) => (
            <details key={faq.q} className="group rounded-2xl bg-white shadow-[0_1px_4px_rgba(0,0,0,0.06)]">
              <summary className="flex cursor-pointer items-center justify-between p-4 text-[15px] font-medium text-gray-800">
                {faq.q}
                <ChevronRight className="h-4 w-4 text-gray-400 transition-transform group-open:rotate-90" />
              </summary>
              <p className="px-4 pb-4 text-[14px] leading-relaxed text-gray-500">{faq.a}</p>
            </details>
          ))}
        </div>
      </div>
    </div>
  );
}

/* ================================================================== */
/*  Main App                                                           */
/* ================================================================== */

export default function DashboardScreen() {
  /* ---- Auth ---- */
  const [auth, setAuth] = useState<AuthState>({ token: null, fullName: null });
  const [authChecked, setAuthChecked] = useState(false);
  const [screen, setScreen] = useState<'login' | 'support-only' | 'app'>('login');

  /* Restore session on mount */
  useEffect(() => {
    const saved = loadAuth();
    if (saved.token) {
      setAuth(saved);
      setScreen('app');
    }
    setAuthChecked(true);
  }, []);

  const handleLogin = useCallback((newAuth: AuthState) => {
    saveAuth(newAuth);
    setAuth(newAuth);
    setScreen('app');
  }, []);

  const handleLogout = useCallback(() => {
    clearAuth();
    setAuth({ token: null, fullName: null });
    setScreen('login');
  }, []);

  /* ---- Profile state ---- */
  const [profile, setProfile] = useState<ProfileResponse | null>(null);
  const [profileState, setProfileState] = useState<FetchState>('idle');

  /* ---- Transactions state ---- */
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [txState, setTxState] = useState<FetchState>('idle');

  /* ---- News state ---- */
  const [news, setNews] = useState<NewsItem[]>([]);
  const [newsState, setNewsState] = useState<FetchState>('idle');

  /* ---- UI state ---- */
  const [activeTab, setActiveTab] = useState(0);
  const [topUpOpen, setTopUpOpen] = useState(false);
  const [historyOpen, setHistoryOpen] = useState(false);
  const [topUpAmount, setTopUpAmount] = useState('');
  const [topUpLoading, setTopUpLoading] = useState(false);
  const [selectedNews, setSelectedNews] = useState<NewsItem | null>(null);

  /* ---- Fetchers ---- */
  const fetchProfile = useCallback(async () => {
    setProfileState('loading');
    try {
      const res = await fetch('/api/account/profile');
      if (!res.ok) throw new Error();
      setProfile(await res.json());
      setProfileState('success');
    } catch { setProfileState('error'); }
  }, []);

  const fetchTransactions = useCallback(async () => {
    setTxState('loading');
    try {
      const res = await fetch('/api/transactions');
      if (!res.ok) throw new Error();
      const json = await res.json();
      setTransactions(json.transactions);
      setTxState('success');
    } catch { setTxState('error'); }
  }, []);

  const fetchNews = useCallback(async () => {
    setNewsState('loading');
    try {
      const res = await fetch('/api/news');
      if (!res.ok) throw new Error();
      const json = await res.json();
      setNews(json.news);
      setNewsState('success');
    } catch { setNewsState('error'); }
  }, []);

  /* ---- Load data on tab switch ---- */
  useEffect(() => { if (screen === 'app') fetchProfile(); }, [screen, fetchProfile]);
  useEffect(() => { if (screen === 'app' && activeTab === 1) fetchTransactions(); }, [screen, activeTab, fetchTransactions]);
  useEffect(() => { if (screen === 'app' && activeTab === 2) fetchNews(); }, [screen, activeTab, fetchNews]);

  /* ---- Top-up handler ---- */
  const handleTopUp = async () => {
    const amount = parseFloat(topUpAmount);
    if (isNaN(amount) || amount <= 0) {
      toast.error('Введите корректную сумму');
      return;
    }
    setTopUpLoading(true);
    try {
      const res = await fetch('/api/top-up', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ amount }),
      });
      if (!res.ok) throw new Error();
      toast.success(`Баланс пополнен на ${amount} ₽`);
      setTopUpAmount('');
      setTopUpOpen(false);
      fetchProfile();
    } catch {
      toast.error('Ошибка пополнения');
    } finally {
      setTopUpLoading(false);
    }
  };

  /* ---- Tabs ---- */
  const tabs = [
    { icon: Home, label: 'Главная' },
    { icon: CreditCard, label: 'Оплата' },
    { icon: FileText, label: 'Новости' },
    { icon: HelpCircle, label: 'Поддержка' },
  ];

  /* ---- Render ---- */
  if (!authChecked) return null;

  /* Login screen */
  if (screen === 'login') {
    return (
      <LoginScreen
        onLogin={handleLogin}
        onOpenSupport={() => setScreen('support-only')}
      />
    );
  }

  /* Support-only screen (no auth required) */
  if (screen === 'support-only') {
    return <SupportOnlyScreen onBack={() => setScreen('login')} />;
  }

  /* Authenticated app */
  return (
    <div className="relative mx-auto min-h-dvh w-full max-w-[430px] bg-white font-sans">
      {/* ============ CONTENT AREA ============ */}
      {activeTab === 0 && (
        <HomeTab
          profile={profile} profileState={profileState}
          onTopUp={() => setTopUpOpen(true)}
          onHistory={() => { setHistoryOpen(true); fetchTransactions(); }}
          onRetry={fetchProfile}
          userName={auth.fullName}
          onLogout={handleLogout}
        />
      )}
      {activeTab === 1 && <PaymentTab transactions={transactions} txState={txState} onRetry={fetchTransactions} />}
      {activeTab === 2 && <NewsTab news={news} newsState={newsState} onRetry={fetchNews} onSelect={setSelectedNews} />}
      {activeTab === 3 && <SupportTab />}

      {/* ============ TOP-UP SHEET ============ */}
      <Sheet open={topUpOpen} onOpenChange={setTopUpOpen}>
        <SheetContent side="bottom" className="mx-auto max-w-[430px] rounded-t-2xl px-6 pb-8 pt-4">
          <SheetHeader>
            <SheetTitle className="text-xl font-bold text-gray-900">Пополнить баланс</SheetTitle>
            <SheetDescription className="text-gray-500">Выберите или введите сумму пополнения</SheetDescription>
          </SheetHeader>
          <div className="mt-4">
            <div className="grid grid-cols-3 gap-3">
              {[100, 200, 500, 1000, 2000, 5000].map((a) => (
                <button
                  key={a}
                  type="button"
                  onClick={() => setTopUpAmount(String(a))}
                  className={`rounded-xl border-2 py-3 text-center text-lg font-semibold transition-all ${
                    topUpAmount === String(a)
                      ? 'border-orange-500 bg-orange-50 text-orange-600'
                      : 'border-gray-200 bg-white text-gray-700 hover:border-orange-300'
                  }`}
                >
                  {a} ₽
                </button>
              ))}
            </div>
            <div className="mt-4">
              <label htmlFor="topup-input" className="mb-1.5 block text-sm font-medium text-gray-600">Другая сумма</label>
              <input
                id="topup-input"
                type="number"
                inputMode="numeric"
                placeholder="0"
                value={topUpAmount}
                onChange={(e) => setTopUpAmount(e.target.value)}
                className="w-full rounded-xl border-2 border-gray-200 px-4 py-3 text-xl font-semibold text-gray-900 outline-none transition-colors focus:border-orange-500"
              />
            </div>
            <button
              type="button"
              onClick={handleTopUp}
              disabled={topUpLoading || !topUpAmount}
              className="mt-5 flex w-full items-center justify-center gap-2 rounded-xl bg-orange-500 px-6 py-3.5 text-lg font-semibold text-white transition-colors hover:bg-orange-600 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {topUpLoading ? <Loader2 className="h-5 w-5 animate-spin" /> : <Wallet className="h-5 w-5" />}
              Пополнить
            </button>
          </div>
        </SheetContent>
      </Sheet>

      {/* ============ HISTORY SHEET ============ */}
      <Sheet open={historyOpen} onOpenChange={setHistoryOpen}>
        <SheetContent side="bottom" className="mx-auto max-w-[430px] rounded-t-2xl px-6 pb-8 pt-4">
          <SheetHeader>
            <SheetTitle className="text-xl font-bold text-gray-900">История операций</SheetTitle>
            <SheetDescription className="text-gray-500">Все транзакции по вашему аккаунту</SheetDescription>
          </SheetHeader>
          <div className="mt-2 max-h-[60vh] overflow-y-auto">
            <TransactionList transactions={transactions} state={txState} onRetry={fetchTransactions} />
          </div>
        </SheetContent>
      </Sheet>

      {/* ============ NEWS DETAIL SHEET ============ */}
      <Sheet open={!!selectedNews} onOpenChange={() => setSelectedNews(null)}>
        <SheetContent side="bottom" className="mx-auto max-w-[430px] rounded-t-2xl px-6 pb-8 pt-4">
          {selectedNews && (
            <>
              <SheetHeader>
                <SheetTitle className="text-xl font-bold text-gray-900 leading-snug">{selectedNews.title}</SheetTitle>
                <SheetDescription className="text-gray-400 text-sm">
                  <Clock className="mr-1 inline h-3.5 w-3.5" />
                  {formatDate(selectedNews.publishedAt)}
                  {selectedNews.readCount != null && ` · ${selectedNews.readCount} просмотров`}
                </SheetDescription>
              </SheetHeader>
              <p className="mt-4 text-[16px] leading-relaxed text-gray-700">{selectedNews.summary}</p>
            </>
          )}
        </SheetContent>
      </Sheet>

      {/* ============ BOTTOM NAV ============ */}
      <nav className="fixed bottom-0 left-1/2 z-50 w-full max-w-[430px] -translate-x-1/2 border-t border-gray-200 bg-white shadow-[0_-2px_10px_rgba(0,0,0,0.06)]">
        <ul className="flex justify-around py-3 pb-5">
          {tabs.map((tab, idx) => {
            const Icon = tab.icon;
            const active = idx === activeTab;
            return (
              <li key={tab.label}>
                <button
                  type="button"
                  onClick={() => setActiveTab(idx)}
                  className={`flex flex-col items-center gap-1.5 transition-colors ${
                    active ? 'text-orange-500' : 'text-gray-400 hover:text-gray-600'
                  }`}
                >
                  <Icon className="h-[26px] w-[26px]" strokeWidth={active ? 2.2 : 1.8} />
                  <span className="text-[13px] font-medium">{tab.label}</span>
                </button>
              </li>
            );
          })}
        </ul>
      </nav>
    </div>
  );
}

/* ================================================================== */
/*  Home Tab                                                           */
/* ================================================================== */

function HomeTab({
  profile, profileState, onTopUp, onHistory, onRetry, userName, onLogout,
}: {
  profile: ProfileResponse | null;
  profileState: FetchState;
  onTopUp: () => void;
  onHistory: () => void;
  onRetry: () => void;
  userName: string | null;
  onLogout: () => void;
}) {
  return (
    <>
      {/* ---- Header ---- */}
      <header className="bg-white px-5 pt-3 pb-6">
        <div className="mb-8 flex items-start justify-between">
          <div className="flex items-center gap-3">
            <div
              className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full text-xl font-bold text-white"
              style={{ background: 'linear-gradient(135deg, #FF9A44 0%, #FC6076 100%)' }}
            >
              S
            </div>
            <div>
              <h2 className="text-[21px] font-bold leading-tight tracking-tight text-gray-900">
                ПИН {profileState === 'loading' ? '---' : profile?.user.pin ?? '------'}
              </h2>
              <p className="text-[17px] leading-tight text-gray-500">
                {profileState === 'loading' ? '...' : (userName ?? profile?.user.fullName)}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-5 pt-0.5">
            <button type="button" aria-label="Уведомления" className="text-gray-600 transition-colors hover:text-gray-800">
              <Bell className="h-[26px] w-[26px]" strokeWidth={1.8} />
            </button>
            <button type="button" aria-label="Настройки" className="text-gray-600 transition-colors hover:text-gray-800">
              <Settings className="h-[26px] w-[26px]" strokeWidth={1.8} />
            </button>
            <button
              type="button"
              onClick={onLogout}
              aria-label="Выйти"
              className="text-gray-400 transition-colors hover:text-red-500"
              title="Выйти"
            >
              <LogOut className="h-[22px] w-[22px]" strokeWidth={1.8} />
            </button>
          </div>
        </div>

        {/* Balance */}
        {profileState === 'loading' ? (
          <div className="flex items-center gap-3 py-2">
            <Loader2 className="h-6 w-6 animate-spin text-gray-300" />
            <span className="text-lg text-gray-300">Загрузка…</span>
          </div>
        ) : profileState === 'error' ? (
          <div className="py-2">
            <p className="text-base text-red-500">Ошибка загрузки профиля</p>
            <button type="button" onClick={onRetry} className="mt-1 text-sm text-orange-500 underline">Повторить</button>
          </div>
        ) : (
          <>
            <div className="mb-2">
              <span
                className="text-[52px] font-medium leading-[1.1] tracking-[-0.03em] text-slate-700"
                style={{ fontFeatureSettings: '"tnum"' }}
              >
                {profile?.balance.amount.toFixed(1)}{' '}
                <span className="text-[36px]">₽</span>
              </span>
            </div>
            <p className="text-[17px] text-gray-500">
              Услуги оплачены {profile?.balance.paidUntilLabel ?? '---'}
            </p>
          </>
        )}

        {/* Action buttons */}
        <div className="mt-6 flex justify-between px-2.5">
          <button
            type="button"
            onClick={onTopUp}
            className="flex items-center gap-2.5 px-1 py-2 text-[17px] font-medium tracking-[-0.01em] text-gray-900 transition-colors hover:text-orange-600"
          >
            <Plus className="h-[28px] w-[28px] rounded-full border-2 border-gray-900" strokeWidth={2} />
            ПОПОЛНИТЬ
          </button>
          <button
            type="button"
            onClick={onHistory}
            className="flex items-center gap-2.5 px-1 py-2 text-[17px] font-medium tracking-[-0.01em] text-gray-900 transition-colors hover:text-orange-600"
          >
            <History className="h-[28px] w-[28px] rounded-full border-2 border-gray-900" strokeWidth={2} />
            ИСТОРИЯ
          </button>
        </div>
      </header>

      {/* ---- Active services ---- */}
      <main className="min-h-[50vh] rounded-t-[20px] bg-gray-50 px-5 pt-6 pb-28" style={{ boxShadow: '0 -4px 20px rgba(0,0,0,0.05)' }}>
        <div className="mb-5 flex items-center justify-between">
          <h2 className="text-[19px] font-semibold text-gray-900">Активные услуги</h2>
          <LockIcon className="h-[26px] w-[26px] text-orange-500" strokeWidth={1.8} />
        </div>
        {profileState === 'loading' ? (
          <div className="flex animate-pulse items-center justify-center rounded-2xl bg-white p-10">
            <Loader2 className="h-8 w-8 animate-spin text-gray-300" />
          </div>
        ) : profileState === 'error' ? null : (
          (profile?.activeServices ?? []).map((svc) => <ServiceCard key={svc.id} service={svc} />)
        )}
      </main>
    </>
  );
}

/* ================================================================== */
/*  Payment Tab                                                       */
/* ================================================================== */

function PaymentTab({ transactions, txState, onRetry }: { transactions: Transaction[]; txState: FetchState; onRetry: () => void }) {
  return (
    <div className="min-h-dvh bg-gray-50 px-5 pt-6 pb-28">
      <h1 className="mb-6 text-[22px] font-bold text-gray-900">Оплата и финансы</h1>
      <div className="mb-6 grid grid-cols-2 gap-3">
        <QuickAction icon={Smartphone} label="Оплата услуг" color="bg-orange-500" />
        <QuickAction icon={Building2} label="Перевод" color="bg-emerald-500" />
        <QuickAction icon={CardIcon} label="Привязать карту" color="bg-blue-500" />
        <QuickAction icon={Tag} label="Промокод" color="bg-violet-500" />
      </div>
      <h2 className="mb-3 text-[17px] font-semibold text-gray-800">Последние операции</h2>
      <div className="rounded-2xl bg-white p-4 shadow-[0_1px_4px_rgba(0,0,0,0.06)]">
        <TransactionList transactions={transactions} state={txState} onRetry={onRetry} />
      </div>
    </div>
  );
}

function QuickAction({ icon: Icon, label, color }: { icon: typeof Smartphone; label: string; color: string }) {
  return (
    <button
      type="button"
      className="flex flex-col items-center gap-2.5 rounded-2xl bg-white p-5 shadow-[0_1px_4px_rgba(0,0,0,0.06)] transition-shadow active:shadow-none"
    >
      <div className={`flex h-12 w-12 items-center justify-center rounded-full ${color}`}>
        <Icon className="h-6 w-6 text-white" strokeWidth={1.8} />
      </div>
      <span className="text-[14px] font-medium text-gray-700">{label}</span>
    </button>
  );
}

/* ================================================================== */
/*  News Tab                                                          */
/* ================================================================== */

function NewsTab({ news, newsState, onRetry, onSelect }: { news: NewsItem[]; newsState: FetchState; onRetry: () => void; onSelect: (n: NewsItem) => void }) {
  return (
    <div className="min-h-dvh bg-gray-50 px-5 pt-6 pb-28">
      <h1 className="mb-6 text-[22px] font-bold text-gray-900">Новости</h1>
      {newsState === 'loading' ? (
        <div className="flex items-center justify-center py-20"><Loader2 className="h-8 w-8 animate-spin text-gray-300" /></div>
      ) : newsState === 'error' ? (
        <div className="py-20 text-center">
          <AlertCircle className="mx-auto mb-3 h-10 w-10 text-red-300" />
          <p className="mb-2 text-gray-500">Не удалось загрузить новости</p>
          <button type="button" onClick={onRetry} className="text-sm text-orange-500 underline">Повторить</button>
        </div>
      ) : news.length === 0 ? (
        <div className="py-20 text-center">
          <Inbox className="mx-auto mb-3 h-10 w-10 text-gray-300" />
          <p className="text-gray-400">Новостей пока нет</p>
        </div>
      ) : (
        <div className="flex flex-col gap-3">
          {news.map((item) => (
            <button
              key={item.id}
              type="button"
              onClick={() => onSelect(item)}
              className="flex items-start gap-4 rounded-2xl bg-white p-4 text-left shadow-[0_1px_4px_rgba(0,0,0,0.06)] transition-shadow hover:shadow-md"
            >
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-orange-100">
                <FileText className="h-5 w-5 text-orange-500" strokeWidth={1.8} />
              </div>
              <div className="min-w-0 flex-1">
                <h3 className="mb-1 text-[15px] font-semibold leading-snug text-gray-900">{item.title}</h3>
                <p className="mb-2 line-clamp-2 text-[13px] leading-relaxed text-gray-500">{item.summary}</p>
                <div className="flex items-center gap-2 text-[12px] text-gray-400">
                  <Clock className="h-3 w-3" />
                  {formatDate(item.publishedAt)}
                  {item.readCount != null && <span>· {item.readCount} просм.</span>}
                </div>
              </div>
              <ChevronRight className="mt-1 h-5 w-5 shrink-0 text-gray-300" />
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

/* ================================================================== */
/*  Support Tab (authenticated)                                       */
/* ================================================================== */

function SupportTab() {
  const [subject, setSubject] = useState('');
  const [description, setDescription] = useState('');
  const [sending, setSending] = useState(false);
  const [sent, setSent] = useState(false);

  const handleSubmit = async () => {
    if (!subject.trim() || !description.trim()) { toast.error('Заполните все поля'); return; }
    setSending(true);
    await new Promise((r) => setTimeout(r, 1000));
    setSending(false);
    setSent(true);
    toast.success('Обращение отправлено');
    setSubject(''); setDescription('');
  };

  return (
    <div className="min-h-dvh bg-gray-50 px-5 pt-6 pb-28">
      <h1 className="mb-2 text-[22px] font-bold text-gray-900">Поддержка</h1>
      <p className="mb-6 text-[15px] text-gray-500">Оставьте обращение и мы свяжемся с вами</p>
      {sent ? (
        <div className="rounded-2xl bg-white p-8 text-center shadow-[0_1px_4px_rgba(0,0,0,0.06)]">
          <CheckCircle2 className="mx-auto mb-4 h-14 w-14 text-emerald-500" />
          <h2 className="mb-2 text-lg font-bold text-gray-900">Отправлено!</h2>
          <p className="mb-5 text-[15px] text-gray-500">Мы ответим в ближайшее время</p>
          <button type="button" onClick={() => setSent(false)} className="text-sm font-medium text-orange-500 underline">Новое обращение</button>
        </div>
      ) : (
        <div className="rounded-2xl bg-white p-5 shadow-[0_1px_4px_rgba(0,0,0,0.06)]">
          <label htmlFor="s-subject" className="mb-1.5 block text-sm font-medium text-gray-700">Тема</label>
          <input id="s-subject" type="text" placeholder="Кратко опишите проблему" value={subject} onChange={(e) => setSubject(e.target.value)} className="mb-4 w-full rounded-xl border-2 border-gray-200 px-4 py-3 text-[15px] text-gray-900 outline-none transition-colors focus:border-orange-500" />
          <label htmlFor="s-desc" className="mb-1.5 block text-sm font-medium text-gray-700">Описание</label>
          <textarea id="s-desc" placeholder="Подробно опишите вашу проблему…" rows={5} value={description} onChange={(e) => setDescription(e.target.value)} className="mb-5 w-full resize-none rounded-xl border-2 border-gray-200 px-4 py-3 text-[15px] text-gray-900 outline-none transition-colors focus:border-orange-500" />
          <button type="button" onClick={handleSubmit} disabled={sending} className="flex w-full items-center justify-center gap-2 rounded-xl bg-orange-500 px-6 py-3.5 text-[16px] font-semibold text-white transition-colors hover:bg-orange-600 disabled:opacity-50">
            {sending ? <Loader2 className="h-5 w-5 animate-spin" /> : <Send className="h-5 w-5" />}
            Отправить
          </button>
        </div>
      )}
      <div className="mt-8">
        <h2 className="mb-4 text-[17px] font-semibold text-gray-800">Частые вопросы</h2>
        <div className="flex flex-col gap-3">
          {[
            { q: 'Как пополнить баланс?', a: 'Нажмите «Пополнить» на главном экране и выберите сумму.' },
            { q: 'Как узнать остаток трафика?', a: 'Информация отображается в карточке активной услуги на главном экране.' },
            { q: 'Как изменить тариф?', a: 'Обратитесь в поддержку через эту форму или позвоните на горячую линию.' },
          ].map((faq) => (
            <details key={faq.q} className="group rounded-2xl bg-white shadow-[0_1px_4px_rgba(0,0,0,0.06)]">
              <summary className="flex cursor-pointer items-center justify-between p-4 text-[15px] font-medium text-gray-800">
                {faq.q}
                <ChevronRight className="h-4 w-4 text-gray-400 transition-transform group-open:rotate-90" />
              </summary>
              <p className="px-4 pb-4 text-[14px] leading-relaxed text-gray-500">{faq.a}</p>
            </details>
          ))}
        </div>
      </div>
    </div>
  );
}

/* ================================================================== */
/*  Shared Components                                                  */
/* ================================================================== */

function ServiceCard({ service }: { service: ActiveService }) {
  return (
    <div className="rounded-[14px] border border-orange-100 bg-orange-50/80 p-5 shadow-[0_2px_8px_rgba(0,0,0,0.1)]">
      <div className="mb-5 text-center">
        <h3 className="text-[27px] font-semibold leading-[1.3] tracking-[-0.01em] text-gray-700">{service.name}</h3>
      </div>
      <div className="flex items-start gap-4">
        <div className="flex h-14 w-14 shrink-0 items-center justify-center rounded-full bg-orange-500">
          <Globe className="h-8 w-8 text-white" strokeWidth={1.5} />
        </div>
        <div className="flex flex-col gap-1.5">
          <p className="text-[19px] font-medium leading-[1.3] text-gray-600">Стоимость {service.cost} ₽</p>
          <p className="text-[19px] font-medium leading-[1.3] text-gray-600">{service.category}</p>
        </div>
        {service.warningMessage && (
          <div className="ml-auto flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-pink-400 text-[20px] font-bold leading-none text-white">
            {service.warningMessage}
          </div>
        )}
      </div>
    </div>
  );
}

function TransactionList({ transactions, state, onRetry }: { transactions: Transaction[]; state: FetchState; onRetry: () => void }) {
  if (state === 'loading') {
    return <div className="flex items-center justify-center py-10"><Loader2 className="h-6 w-6 animate-spin text-gray-300" /></div>;
  }
  if (state === 'error') {
    return (
      <div className="py-10 text-center">
        <p className="mb-2 text-sm text-gray-400">Ошибка загрузки</p>
        <button type="button" onClick={onRetry} className="text-sm text-orange-500 underline">Повторить</button>
      </div>
    );
  }
  if (transactions.length === 0) {
    return (
      <div className="py-10 text-center">
        <MessageSquare className="mx-auto mb-2 h-8 w-8 text-gray-300" />
        <p className="text-sm text-gray-400">Нет транзакций</p>
      </div>
    );
  }
  return (
    <div className="divide-y divide-gray-100">
      {transactions.map((tx) => (
        <div key={tx.id} className="flex items-center gap-3 py-3 first:pt-0 last:pb-0">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-gray-50">
            {txIcon(tx.type)}
          </div>
          <div className="min-w-0 flex-1">
            <p className="truncate text-[14px] font-medium text-gray-800">{tx.description}</p>
            <div className="flex items-center gap-2 text-[12px] text-gray-400">
              <span className="rounded bg-gray-100 px-1.5 py-0.5 text-[11px] font-medium text-gray-500">{txLabel(tx.type)}</span>
              <span>{formatDate(tx.date)}</span>
            </div>
          </div>
          <span className={`shrink-0 text-[15px] font-semibold tabular-nums ${txColor(tx.type)}`}>{txSign(tx.type)}{tx.amount.toFixed(0)} ₽</span>
        </div>
      ))}
    </div>
  );
}
