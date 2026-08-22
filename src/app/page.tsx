'use client';

import { useEffect, useState, useCallback } from 'react';
import {
  Bell,
  Settings,
  Plus,
  History,
  Globe,
  Lock,
  Home,
  CreditCard,
  FileText,
  HelpCircle,
  Loader2,
} from 'lucide-react';

/* ------------------------------------------------------------------ */
/*  Domain Types (mirrors ARCHITECTURE.md §2)                         */
/* ------------------------------------------------------------------ */

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

type FetchState = 'idle' | 'loading' | 'success' | 'error';

/* ------------------------------------------------------------------ */
/*  Dashboard Screen                                                  */
/* ------------------------------------------------------------------ */

export default function DashboardScreen() {
  const [data, setData] = useState<ProfileResponse | null>(null);
  const [state, setState] = useState<FetchState>('idle');
  const [activeTab, setActiveTab] = useState(0);

  const fetchProfile = useCallback(async () => {
    setState('loading');
    try {
      const res = await fetch('/api/account/profile');
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const json: ProfileResponse = await res.json();
      setData(json);
      setState('success');
    } catch {
      setState('error');
    }
  }, []);

  useEffect(() => {
    fetchProfile();
  }, [fetchProfile]);

  /* ---- Tabs ---- */
  const tabs = [
    { icon: Home, label: 'Главная' },
    { icon: CreditCard, label: 'Оплата' },
    { icon: FileText, label: 'Новости' },
    { icon: HelpCircle, label: 'Поддержка' },
  ];

  /* ---- Render ---- */
  return (
    <div className="relative mx-auto min-h-dvh w-full max-w-[430px] bg-white font-sans">
      {/* ============ HEADER ============ */}
      <header className="bg-white px-5 pt-3 pb-6">
        {/* Top row */}
        <div className="flex items-start justify-between mb-8">
          {/* User info */}
          <div className="flex items-center gap-3">
            {/* Avatar circle */}
            <div
              className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full text-white text-xl font-bold"
              style={{
                background:
                  'linear-gradient(135deg, #FF9A44 0%, #FC6076 100%)',
              }}
            >
              S
            </div>
            <div>
              <h2 className="text-[21px] font-bold leading-tight tracking-tight text-gray-900">
                ПИН{' '}
                {state === 'loading'
                  ? '---'
                  : data?.user.pin ?? '039103'}
              </h2>
              <p className="text-[17px] font-normal leading-tight text-gray-500">
                {state === 'loading'
                  ? '...'
                  : data?.user.fullName ?? 'Примеров-Заде П.'}
              </p>
            </div>
          </div>

          {/* Actions */}
          <div className="flex items-center gap-5 pt-0.5">
            <button
              type="button"
              aria-label="Уведомления"
              className="text-gray-600 transition-colors hover:text-gray-800"
            >
              <Bell className="h-[26px] w-[26px]" strokeWidth={1.8} />
            </button>
            <button
              type="button"
              aria-label="Настройки"
              className="text-gray-600 transition-colors hover:text-gray-800"
            >
              <Settings className="h-[26px] w-[26px]" strokeWidth={1.8} />
            </button>
          </div>
        </div>

        {/* Balance */}
        {state === 'loading' ? (
          <div className="flex items-center gap-3 py-2">
            <Loader2 className="h-6 w-6 animate-spin text-gray-300" />
            <span className="text-lg text-gray-300">Загрузка…</span>
          </div>
        ) : state === 'error' ? (
          <div className="py-2">
            <p className="text-base text-red-500">
              Ошибка загрузки профиля
            </p>
            <button
              type="button"
              onClick={fetchProfile}
              className="mt-1 text-sm text-orange-500 underline"
            >
              Повторить
            </button>
          </div>
        ) : (
          <>
            <div className="mb-2">
              <span className="text-[52px] font-medium leading-[1.1] tracking-[-0.03em] text-slate-700"
                style={{ fontFeatureSettings: '"tnum"' }}
              >
                {data?.balance.amount.toFixed(1)}{' '}
                <span className="text-[36px]">₽</span>
              </span>
            </div>
            <p className="text-[17px] font-normal text-gray-500">
              Услуги оплачены{' '}
              {data?.balance.paidUntilLabel ?? 'до 11 ноября 2024'}
            </p>
          </>
        )}

        {/* Action buttons */}
        <div className="mt-6 flex justify-between px-2.5">
          <button
            type="button"
            className="flex items-center gap-2.5 px-1 py-2 text-[17px] font-medium tracking-[-0.01em] text-gray-900 transition-colors hover:text-orange-600"
          >
            <Plus
              className="h-[28px] w-[28px] rounded-full border-2 border-gray-900"
              strokeWidth={2}
            />
            ПОПОЛНИТЬ
          </button>
          <button
            type="button"
            className="flex items-center gap-2.5 px-1 py-2 text-[17px] font-medium tracking-[-0.01em] text-gray-900 transition-colors hover:text-orange-600"
          >
            <History
              className="h-[28px] w-[28px] rounded-full border-2 border-gray-900"
              strokeWidth={2}
            />
            ИСТОРИЯ
          </button>
        </div>
      </header>

      {/* ============ MAIN CONTENT ============ */}
      <main
        className="min-h-[50vh] rounded-t-[20px] bg-gray-50 px-5 pt-6 pb-28"
        style={{
          boxShadow: '0 -4px 20px rgba(0,0,0,0.05)',
        }}
      >
        {/* Section header */}
        <div className="mb-5 flex items-center justify-between">
          <h2 className="text-[19px] font-semibold text-gray-900">
            Активные услуги
          </h2>
          <Lock
            className="h-[26px] w-[26px] text-orange-500"
            strokeWidth={1.8}
          />
        </div>

        {/* Service cards */}
        {state === 'loading' ? (
          <div className="flex animate-pulse items-center justify-center rounded-2xl bg-white p-10">
            <Loader2 className="h-8 w-8 animate-spin text-gray-300" />
          </div>
        ) : state === 'error' ? null : (
          (data?.activeServices ?? []).map((svc) => (
            <ServiceCard key={svc.id} service={svc} />
          ))
        )}
      </main>

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
                    active
                      ? 'text-orange-500'
                      : 'text-gray-400 hover:text-gray-600'
                  }`}
                >
                  <Icon
                    className="h-[26px] w-[26px]"
                    strokeWidth={active ? 2.2 : 1.8}
                  />
                  <span className="text-[13px] font-medium">
                    {tab.label}
                  </span>
                </button>
              </li>
            );
          })}
        </ul>
      </nav>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/*  Service Card Component                                            */
/* ------------------------------------------------------------------ */

function ServiceCard({ service }: { service: ActiveService }) {
  return (
    <div className="rounded-[14px] border border-orange-100 bg-orange-50/80 p-5 shadow-[0_2px_8px_rgba(0,0,0,0.1)]">
      {/* Card title — centered */}
      <div className="mb-5 text-center">
        <h3 className="text-[27px] font-semibold leading-[1.3] tracking-[-0.01em] text-gray-700">
          {service.name}
        </h3>
      </div>

      {/* Card body */}
      <div className="flex items-start gap-4">
        {/* Globe icon */}
        <div className="flex h-14 w-14 shrink-0 items-center justify-center rounded-full bg-orange-500">
          <Globe className="h-8 w-8 text-white" strokeWidth={1.5} />
        </div>

        {/* Details */}
        <div className="flex flex-col gap-1.5">
          <p className="text-[19px] font-medium leading-[1.3] text-gray-600">
            Стоимость {service.cost} ₽
          </p>
          <p className="text-[19px] font-medium leading-[1.3] text-gray-600">
            {service.category}
          </p>
        </div>

        {/* Warning badge */}
        {service.warningMessage && (
          <div className="ml-auto flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-pink-400 text-[20px] font-bold leading-none text-white">
            {service.warningMessage}
          </div>
        )}
      </div>
    </div>
  );
}
