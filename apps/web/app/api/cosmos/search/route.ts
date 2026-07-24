import { NextRequest, NextResponse } from "next/server";
import { searchElements } from "@/lib/cosmos";
import { cacheHeaders } from "@/lib/cache";
import { ElementsResponse, ApiError } from "@/lib/types";

export async function GET(
  req: NextRequest
): Promise<NextResponse<ElementsResponse | ApiError>> {
  const q = req.nextUrl.searchParams.get("q");
  const cursor = req.nextUrl.searchParams.get("cursor");

  if (!q) {
    return NextResponse.json({ error: "Missing q" }, { status: 400 });
  }

  try {
    const result = await searchElements(q, cursor || null);
    return NextResponse.json(
      {
        elements: result.elements,
        nextCursor: result.nextCursor,
      },
      { headers: cacheHeaders() }
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return NextResponse.json({ error: message }, { status: 502 });
  }
}
