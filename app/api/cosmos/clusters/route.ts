import { NextRequest, NextResponse } from "next/server";
import { fetchClusters } from "@/lib/cosmos";
import { ClustersResponse, ApiError } from "@/lib/types";

export async function GET(
  req: NextRequest
): Promise<NextResponse<ClustersResponse | ApiError>> {
  const userId = req.nextUrl.searchParams.get("userId");

  if (!userId) {
    return NextResponse.json({ error: "Missing userId" }, { status: 400 });
  }

  try {
    const clusters = await fetchClusters(userId);
    return NextResponse.json({ clusters });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return NextResponse.json({ error: message }, { status: 502 });
  }
}
