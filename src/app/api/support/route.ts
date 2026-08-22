import { NextResponse } from "next/server";

const ARTIFICIAL_DELAY_MS = 800;

export async function GET() {
  await new Promise((resolve) => setTimeout(resolve, ARTIFICIAL_DELAY_MS));

  const data = {
    tickets: [],
  };

  return NextResponse.json(data);
}
