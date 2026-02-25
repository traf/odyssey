import { NextRequest, NextResponse } from "next/server";
import { resolveUser } from "@/lib/cosmos";
import { ResolveResponse, ApiError } from "@/lib/types";

export async function GET(
  req: NextRequest
): Promise<NextResponse<ResolveResponse | ApiError>> {
  const username = req.nextUrl.searchParams.get("username")?.trim();

  if (!username) {
    return NextResponse.json({ error: "Missing username" }, { status: 400 });
  }

  try {
    const result = await resolveUser(username);
    return NextResponse.json(result);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    const status = message.includes("not found") ? 404 : 502;
    return NextResponse.json({ error: message }, { status });
  }
}
