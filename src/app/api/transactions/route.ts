import { NextResponse } from "next/server";

const ARTIFICIAL_DELAY_MS = 800;

export async function GET() {
  await new Promise((resolve) => setTimeout(resolve, ARTIFICIAL_DELAY_MS));

  const data = {
    transactions: [
      {
        id: "tx-1",
        type: "payment",
        amount: 225.0,
        description: "Оплата услуги 100/100 30 day",
        date: "2024-08-01T10:00:00.000Z",
        status: "success",
      },
      {
        id: "tx-2",
        type: "topUp",
        amount: 500.0,
        description: "Пополнение через терминал",
        date: "2024-07-28T14:30:00.000Z",
        status: "success",
      },
      {
        id: "tx-3",
        type: "payment",
        amount: 225.0,
        description: "Оплата услуги 100/100 30 day",
        date: "2024-07-01T10:00:00.000Z",
        status: "success",
      },
      {
        id: "tx-4",
        type: "topUp",
        amount: 1000.0,
        description: "Пополнение картой",
        date: "2024-06-15T09:00:00.000Z",
        status: "success",
      },
      {
        id: "tx-5",
        type: "refund",
        amount: 50.0,
        description: "Возврат средств",
        date: "2024-06-10T12:00:00.000Z",
        status: "success",
      },
    ],
    total: 5,
  };

  return NextResponse.json(data);
}
