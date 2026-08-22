import { NextRequest, NextResponse } from 'next/server';

const MOCK_USERS: Record<string, { password: string; pin: string; fullName: string }> = {
  '039103': { password: '123456', pin: '039103', fullName: 'Примеров-Заде П.' },
};

export async function POST(request: NextRequest) {
  await new Promise((resolve) => setTimeout(resolve, 600));

  try {
    const body = await request.json();
    const { pin, password } = body;

    if (!pin || !password) {
      return NextResponse.json({ error: 'Введите ПИН и пароль' }, { status: 400 });
    }

    const user = MOCK_USERS[pin];

    if (!user || user.password !== password) {
      return NextResponse.json({ error: 'Неверный ПИН или пароль' }, { status: 401 });
    }

    return NextResponse.json({
      success: true,
      token: `mock-jwt-${pin}-${Date.now()}`,
      user: { pin: user.pin, fullName: user.fullName },
    });
  } catch {
    return NextResponse.json({ error: 'Ошибка сервера' }, { status: 500 });
  }
}
