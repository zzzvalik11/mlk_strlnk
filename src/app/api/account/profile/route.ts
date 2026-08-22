import { NextResponse } from "next/server";

const ARTIFICIAL_DELAY_MS = 800;

export async function GET() {
  await new Promise((resolve) => setTimeout(resolve, ARTIFICIAL_DELAY_MS));

  const profileData = {
    user: {
      pin: "039103",
      fullName: "Примеров-Заде П.",
      phone: null,
      avatarUrl: null,
    },
    balance: {
      amount: 112.5,
      currency: "RUB",
      paidUntil: "2024-08-11T00:00:00.000Z",
      isPaid: true,
      paidUntilLabel: "до 11 августа",
    },
    activeServices: [
      {
        id: "svc-1",
        name: "100/100 30 day 250 руб",
        category: "Интернет",
        cost: 225.0,
        status: "active",
        warningMessage: "!",
        billingCycle: "30 days",
      },
    ],
  };

  return NextResponse.json(profileData);
}
