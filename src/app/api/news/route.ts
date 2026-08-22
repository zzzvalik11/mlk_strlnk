import { NextResponse } from "next/server";

const ARTIFICIAL_DELAY_MS = 800;

export async function GET() {
  await new Promise((resolve) => setTimeout(resolve, ARTIFICIAL_DELAY_MS));

  const data = {
    news: [
      {
        id: "n-1",
        title: "Обновление тарифов",
        summary:
          "С 1 сентября 2024 года вступают в силу новые тарифные планы для всех абонентов.",
        imageUrl: null,
        publishedAt: "2024-08-05T08:00:00.000Z",
        readCount: 342,
      },
      {
        id: "n-2",
        title: "Технические работы",
        summary:
          "В ночь с 12 на 13 августа проводятся плановые технические работы.",
        imageUrl: null,
        publishedAt: "2024-08-03T12:00:00.000Z",
        readCount: 189,
      },
      {
        id: "n-3",
        title: "Новая услуга: IPTV",
        summary:
          "Подключите цифровое телевидение с более чем 200 каналами.",
        imageUrl: null,
        publishedAt: "2024-07-28T16:00:00.000Z",
        readCount: 567,
      },
    ],
  };

  return NextResponse.json(data);
}
