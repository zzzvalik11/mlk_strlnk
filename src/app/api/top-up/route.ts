import { NextResponse } from "next/server";

const ARTIFICIAL_DELAY_MS = 500;

export async function POST(request: Request) {
  await new Promise((resolve) => setTimeout(resolve, ARTIFICIAL_DELAY_MS));

  let amount = 0;
  try {
    const body = await request.json();
    amount = body.amount;
  } catch {
    return NextResponse.json(
      { success: false, message: "Invalid request body" },
      { status: 400 }
    );
  }

  const BASE_BALANCE = 112.5;

  const data = {
    success: true,
    newBalance: BASE_BALANCE + amount,
    currency: "RUB",
    message: `Успешно пополнено на ${amount} ₽`,
  };

  return NextResponse.json(data);
}
