import { NextRequest, NextResponse } from "next/server";
import { fetchElements } from "@/lib/cosmos";
import { ElementsResponse, ApiError } from "@/lib/types";

export async function GET(
  req: NextRequest
): Promise<NextResponse<ElementsResponse | ApiError>> {
  const userId = req.nextUrl.searchParams.get("userId");
  const cursor = req.nextUrl.searchParams.get("cursor");

  if (!userId || !cursor) {
    return NextResponse.json(
      { error: "Missing userId or cursor" },
      { status: 400 }
    );
  }

  try {
    const result = await fetchElements(userId, cursor);
    return NextResponse.json(result);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return NextResponse.json({ error: message }, { status: 502 });
  }
}
